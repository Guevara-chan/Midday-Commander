import os, osproc, strutils, algorithm, sequtils, times, random, streams, sugar, strformat, encodings, tables, browsers
from unicode import Rune, runes, align, alignLeft, runeSubStr, runeLen, runeAt, capitalize, reversed, `==`, `$`
import std/with, winlean, auxiliary/colors, auxiliary/help, rayterm, raylib
{.this: self.}

#.{ [Classes]
when not defined(Meta):
    # --Constants.
    const cmd_cp = when defined(windows): "cp866"
    else: "utf-8"
    type abort_ex = ReraiseError

    # --Service procs:
    template abort(reason = "")     = raise newException(abort_ex, reason)
    template control_down(): bool   = KEY_Left_Control.IsKeyDown()  or KEY_Right_Control.IsKeyDown()
    template shift_down(): bool     = KEY_Left_Shift.IsKeyDown()    or KEY_Right_Shift.IsKeyDown()
    template alt_down(): bool       = KEY_Left_Alt.IsKeyDown()      or KEY_Right_Alt.IsKeyDown()
    template by3(num: auto): string                                = ($num).insertSep(' ', 3)
    template undot(ext: string): string                            = ext.dup(removePrefix('.'))
    template fit(txt: string, size: int, filler = ' '): string     = txt.align(size, filler.Rune).runeSubStr 0, size
    template fit_left(txt: string, size: int, filler = ' '): string= txt.alignLeft(size, filler.Rune).runeSubStr 0,size

    proc check_droplist(): seq[string] =
        if IsFileDropped():
            var idx, list_size: int32
            let listing = GetDroppedFiles(list_size.addr)
            result = collect(newSeq): (for x in 0..<list_size: $listing[x])
            ClearDroppedFiles()

    proc root_dir(path: string): string =
        var child = path
        while true: (if child.parentDir == ".": return child else: child = child.parentDir)

    proc drive_list(): seq[string] =
        when defined(windows):
            for drive in execCmdEx("wmic logicaldisk get caption,Access", {poDaemon}).output.splitLines[1..^1]
                .filterIt(it!=""):
                    if drive[0] != ' ': result.add drive.subStr(4).strip()
        else: @[]

    proc wildcard_replace(path: string, pattern = "*.*"): string =
        let
            (dir, name, ext) = path.splitFile
            mask = pattern.splitFile
        dir / (mask.name.replace("*", name).addFileExt mask.ext.replace("*", ext.undot).undot)

    proc wildcard_match(path: string, pattern = "*.*"): bool =
        proc match_part(part, pattern: string): bool =
            var idx: int
            if pattern.runeLen > part.runeLen: # Special cases.
                if part == "" and pattern == "*": return true
                return false
            for chr in pattern.runes:
                case chr:
                    of '?'.Rune: discard
                    of '*'.Rune: return part.endsWith(pattern.runeSubstr(idx+1))
                    elif chr != part.runeAt(idx): return false 
                idx.inc
            return true
        let 
            (dir, name, ext) = (if FileSystemCaseSensitive: path else: path.toLower).splitFile
            mask = (if FileSystemCaseSensitive: pattern else: pattern.toLower).splitFile
        return name.matchpart(mask.name) and ext.undot.match_part(mask.ext.undot)

    proc truePath(path: string, follow_symlink = true): string =
        when defined(windows):
            proc GetFinalPathNameByHandle(hFile:Handle, lpszFilePath:WideCStringObj, cchFilePath, dwFlags:int32):int32
                {.stdcall, dynlib: "kernel32", discardable, importc: "GetFinalPathNameByHandleW".}
            let
                handle = createFileW(newWideCString(path), 0'i32, 0'i32, nil, OPEN_EXISTING, 
                    FILE_FLAG_BACKUP_SEMANTICS or (FILE_FLAG_OPEN_REPARSE_POINT * (1-follow_symlink.int)), 0)
                length = GetFinalPathNameByHandle(handle, newWideCString(" "), 0, 0)
                buffer = newWideCString(" ".repeat(length))
            defer: discard closeHandle(handle)
            if length == 0: return path
            GetFinalPathNameByHandle(handle, buffer, len(buffer), 0)
            return ($buffer).replace(r"\\?\", "")
        else: return expandSymlink path

    iterator lazy_xtree(path: string): string =
        var 
            checklist = @[path]
            volatile: seq[string]
        while checklist.len > 0:
            for src in checklist:
                yield src
                for dir in walkDirs(src / "*"): volatile.add dir
            checklist.setLen 0
            checklist.add volatile
            volatile.setLen 0

    proc remove_dir_ex(path: string, tick: proc(now_processing: string)) =
        for (kind, path) in walkDir(path):
            tick(path); if path.fileExists: path.removeFile else: path.remove_dir_ex(tick)
        tick(path); path.removeDir

    proc transfer_dir(src, dest: string; destructive: bool, tick: proc(now_processing: string)) =
        dest.createDir
        for (kind, path) in walkDir(src):
            let dest = dest / path.extractFilename
            if path.fileExists:
                tick(path); dest.removeFile; if destructive: path.moveFile dest else: path.copyFile dest
            else: path.transfer_dir(dest, destructive, tick)
        tick(src); if destructive: src.removeDir
# -------------------- #
when not defined(DirEntry):
    type DirEntryDesc = tuple[id: string, metrics: string, time_stamp: string, coloring: Color]
    type DirEntry = object
        name:  string
        kind:  PathComponent
        size:  BiggestInt
        mtime: Time
        memo:  DirEntryDesc
        selected, hidden: bool
    const direxit = DirEntry(name: ParDir, kind: pcDir)
    const dirrepr = DirEntry(name: $CurDir, kind: pcDir)

    # --Properties:
    template executable(self: DirEntry): bool = self.name.splitFile.ext.undot in ExeExts
    template is_dir(self: DirEntry): bool     = self.kind in [pcDir, pcLinkToDir]
    template is_link(self: DirEntry): bool    = self.kind in [pcLinkToFile, pcLinkToDir]

    proc coloring(self: DirEntry): Color =
        result = case kind:
            of pcDir, pcLinkToDir: RAYWHITE
            of pcFile, pcLinkToFile:
                if self.executable: GREEN else: BEIGE
        if hidden: result = result.Fade(0.7)
    proc metrics(self: DirEntry): string =
        if self.name == ParDir:       "\xB7\x10UP--DIR\x11\xB7"
        elif self.is_dir:             "\xB7\x10SUB-DIR\x11\xB7"
        elif self.name == "":         ""
        elif self.size > 99999999999: $(self.size div 1024) & "K" # Only 11 digirs could be displayed in this col.
        else: $self.size
    proc time_stamp(self: DirEntry): string =
        if name != "": 
            mtime.format(if mtime.local.year == now().year: "dd MMM hh:mm" else: "dd MMM  yyyy")
        else: ""

    # --Methods goes here:    
    proc `$`(self: DirEntry): string = 
        result = case self.kind:
            of pcLinkToDir: "~"
            of pcLinkToFile: "@"
            of pcDir: "/"
            elif self.executable: "*"
            else: " "
        return result & name

    proc get_desc(self: DirEntry): DirEntryDesc =
        if memo.id == "": ($self, self.metrics, self.time_stamp, self.coloring) else: memo

    proc newDirEntry(src: tuple[kind: PathComponent, path: string]): DirEntry =
        DirEntry(name: src.path.extractFilename, kind: src.kind, size: src.path.getFileSize, hidden: src.path.isHidden,
            mtime: src.path.getLastModificationTime)
# -------------------- #
when not defined(DirViewer):
    type BreakDown = object
        files, dirs, bytes: BiggestInt
    type SortCriteria = enum
        default = -1, name, ext, size, mtime
    type DirViewer = ref object of Area
        host: TerminalEmu
        path: string
        list: seq[DirEntry]
        dir_stat, sel_stat: BreakDown
        dirty, active, visible, hl_changed, inverse_sort, show_repr: bool
        hline, origin, xoffset, file_count, name_col, size_col, date_col, total_width, viewer_width: int
        sorters: seq[proc(x: DirEntry, y: DirEntry): int]
        sorter:  SortCriteria
    const
        hdr_height      = 2
        foot_height     = 3
        service_height  = 2
        border_color    = GRAY
        tips_color      = GOLD
        hl_color        = SKYBLUE
        selected_color  = YELLOW

    # --Properties
    template capacity(self: DirViewer): int    = host.vlines - hdr_height - foot_height - service_height
    template hindex(self: DirViewer): int      = hline - origin
    template hentry(self: DirViewer): DirEntry = (if self.show_repr: dirrepr else: self.list[self.hline])
    template hpath(self: DirViewer): string    = self.path / self.hentry.name

    proc path_limited(self: DirViewer): string = 
        if path.runeLen > total_width-2: &"…{path.runeSubStr(-total_width+4)}"
        else: path

    proc selected_entries(self: DirViewer): seq[DirEntry] =
        result = list.filterIt it.selected
        if result.len == 0: result.add self.hentry

    proc selected_indexes(self: DirViewer): seq[int] =
        for idx, entry in list: (if entry.selected: result.add idx)

    proc selection_valid(self: DirViewer): bool = 
        let sel = self.selected_entries
        if sel.len > 1 or sel[0].name != direxit.name: return true

    iterator render_list(self: DirViewer): tuple[index: int, val: DirEntry] =
        var fragment: seq[DirEntry] = list[origin..^1]
        fragment.setLen(self.capacity)
        for idx, entry in fragment: yield (origin+idx, entry)

    # --Methods goes here:
    proc scroll_to(self: DirViewer, pos = 0): auto {.discardable.} =
        hline = max(0, min(pos, list.len - 1))
        origin = if hline >= origin + self.capacity: hline - self.capacity + 1
        else: min(origin, hline)
        hl_changed = true
        return self

    proc scroll(self: DirViewer, shift = 0) =
        scroll_to hline + shift

    proc scroll_to_name(self: DirViewer, name: string) =
        for idx, entry in list: 
            if entry.name == name: scroll_to idx; break

    proc scroll_to_prefix(self: DirViewer, prefix: string) =
        if prefix == "": return
        for idx, entry in list: 
            if prefix.len <= entry.name.len and prefix.cmpPaths(entry.name.runeSubstr(0, prefix.len)) == 0:
                scroll_to idx; break

    template sorter_base(comparator: untyped, invertor = false) =
        return if x.name == ParDir:     -1
        elif not x.is_dir and y.is_dir: 1
        elif x.is_dir and not y.is_dir: -1
        elif invertor:                  -comparator
        else:                           comparator

    proc name_sorter(x: DirEntry, y: DirEntry): int =
        sorter_base cmp(x.name, y.name)

    proc ext_sorter(x: DirEntry, y: DirEntry): int =
        sorter_base cmp(x.name.splitFile.ext, y.name.splitFile.ext)

    proc size_sorter(x: DirEntry, y: DirEntry): int =
        sorter_base cmp(x.size, y.size)

    proc mtime_sorter(x: DirEntry, y: DirEntry): int =
        sorter_base cmp(x.mtime, y.mtime)

    proc organize(self: DirViewer, criteria = SortCriteria.default): auto {.discardable.} =
        list = list.sorted sorters[(if criteria == SortCriteria.default: sorter else: criteria).int]
        return self

    proc refresh(self: DirViewer): auto {.discardable.} =
        let last_hl = hline # To return for hl position later.
        dir_stat = Breakdown(); sel_stat = BreakDown(); list.setLen(0)
        if not path.isRootDir: list.add(direxit); list[0].mtime = path.getLastModificationTime # .. entry.
        for record in walkDir(path): 
            let entry = newDirEntry record
            if not entry.is_dir: dir_stat.bytes += entry.size; dir_stat.files.inc else: dir_stat.dirs.inc
            list.add entry
        dirty = false
        return organize().scroll_to(last_hl)

    proc chdir(self: DirViewer, newdir: string): auto {.discardable.} =
        let prev_dir = path.extractFilename
        (if newdir.isAbsolute: newdir else: path / newdir).normalizePathEnd(true).truePath.setCurrentDir
        path = getCurrentDir()
        scroll_to(0).refresh()
        if newdir == ParDir: scroll_to_name(prev_dir) # Backtrace.
        return self

    proc exec(self: DirViewer, fname: string) =
        openDefaultBrowser self.hpath.quoteShell

    proc invoke(self: DirViewer, entry: DirEntry) =
        if entry.is_dir: chdir(entry.name) else: exec(entry.name)

    proc switch_selection(self: DirViewer, idx: int, state = -1) =
        var entry = list[idx]
        entry.selected = if state < 0: not entry.selected else: state.bool
        if entry.selected != list[idx].selected: # If any real changes ocurred
            let factor = if entry.selected: 1 else: -1 # Updating stat.
            if not entry.is_dir: sel_stat.bytes += entry.size * factor; sel_stat.files += factor
            else: sel_stat.dirs += factor
        list[idx] = entry

    proc select_inverted(self: DirViewer) =
        for idx, entry in list: switch_selection(idx)

    proc cache_desc(self: DirViewer, idx: int): DirEntryDesc =
        if idx < list.len:
            var entry = list[idx]
            result = entry.get_desc()
            if entry.memo.id == "":
                entry.memo = result
                list[idx] = entry

    proc adjust(self: DirViewer) =
        size_col     = "\xB7\x10UP--DIR\x11\xB7".len
        date_col     = "Modify time:".len
        name_col     = host.hlines div 2 - size_col - date_col - 4
        total_width  = name_col + size_col + date_col + 2
        viewer_width = total_width + 2

    proc switch_sorter(self: DirViewer, new_criteria = SortCriteria.default) =
        sorter = if new_criteria == SortCriteria.default: ((sorter.int+1) %% SortCriteria.high.int).SortCriteria
        else: new_criteria
        organize()

    proc pick_sorter(self: DirViewer, x = GetMouseX(), y = GetMouseY()): SortCriteria =
        if y == hdr_height - 1:
            if x in viewer_width-date_col-1..viewer_width-2: return SortCriteria.mtime
            elif x in name_col+2..viewer_width-date_col-2:   return SortCriteria.size
            elif x in 1..name_col:                           return SortCriteria.name
        return SortCriteria.default

    method update(self: DirViewer): Area {.discardable.} =
        # Init setup.
        hl_changed   = false
        # Mouse controls.
        if not active: return self
        scroll -GetMouseWheelMove()
        let
            (x, y)    = host.pick()
            pickline  = y - hdr_height
            pickindex = pickline + origin
            newsorter = pick_sorter(x, y)
        if newsorter == SortCriteria.default and (y < hdr_height or y >= host.vlines - service_height - foot_height):
            discard # Not service zone.
        elif MOUSE_Left_Button.IsMouseButtonReleased:  # Invoke item by double left click.
            if newsorter != SortCriteria.default: switch_sorter newsorter
            elif (getTime()-clicker).inMilliseconds<=300: clicker=Time(); (if pickline == self.hindex: invoke hentry())
            else: clicker = getTime()
        elif MOUSE_Right_Button.IsMouseButtonReleased: (if pickindex < list.len: switch_selection pickindex)# RB=select
        elif MOUSE_Left_Button.IsMouseButtonDown:      # HL items if left button down.
            if pickindex != self.hline and pickindex < list.len and pickindex >= 0: scroll_to pickindex
        # Kbd controls.        
        self.show_repr = KEY_Delete.IsKeyDown()
        if   KEY_Insert.IsKeyPressed and control_down(): self.hpath.SetClipboardText
        elif KEY_Up.IsKeyDown:        (if norepeat(): scroll -1)
        elif KEY_Down.IsKeyDown:      (if norepeat(): scroll 1)
        elif KEY_Page_Up.IsKeyDown:   (if norepeat(): scroll -self.capacity)
        elif KEY_Page_Down.IsKeyDown: (if norepeat(): scroll self.capacity)
        elif KEY_Left.IsKeyPressed:   scroll_to 0
        elif KEY_Right.IsKeyPressed:  scroll_to list.len
        elif KEY_Enter.IsKeyPressed:  invoke self.hentry
        elif KEY_Insert.IsKeyPressed: switch_selection(hline); scroll 1
        elif KEY_KP_Enter.IsKeyPressed: select_inverted()
        # Finalization.
        return self

    method render(self: DirViewer): Area {.discardable.} =
        # Aux template.
        template sort_mark(txt: string, crit: SortCriteria, mark = "*"): string =
            txt & (if self.sorter == crit: mark.replace "*", "\x17" else: "")
        # Init setup.
        if not visible: return self
        host.margin = xoffset
        host.loc(xoffset, 0)
        adjust()
        # Header rendering.
        with host:
            write ["╔", "═".repeat(total_width), "╗"], border_color, DARKBLUE
            loc((total_width - self.path_limited.runeLen) div 2 + xoffset, host.vpos())
            write [" ", self.path_limited, " \n"], (if active: hl_color else: direxit.coloring), DARKGRAY
            write ["║\a\x02", "Name".sort_mark(SortCriteria.ext, "/ext*").center(name_col), "\a\x01│\a\xff", 
                "Size".sort_mark(SortCriteria.size).center(size_col), "\a\x01│\a\xff",
                    "Modify time".sort_mark(SortCriteria.mtime).center(date_col), "\a\xff║\n"], border_color, DARKBLUE
        # List rendering.
        for idx, entry in self.render_list:
            let desc = cache_desc(idx)
            let text_color = if entry.selected: selected_color else: desc.coloring
            with host:
                write (if entry.selected: "╟" else : "║"), border_color, DARKBLUE
                write [desc.id.fit_left(name_col), "\a\x01", if ($entry).runeLen>name_col:"…" else:"│"], text_color,
                    if active and idx == hline and not self.show_repr: hl_color else: DARKBLUE # Highlight line.
                write [desc.metrics.fit(size_col), "\a\x01│"], text_color
                write desc.time_stamp.fit_left(date_col), text_color
                write ["\a\x01", (if entry.selected: "╢" else : "║"), "\n"], text_color, DARKBLUE
        # 1st footline rendering.
        host.write ["║", "─".repeat(name_col), "┴", "─".repeat(size_col), "┴", "─".repeat(date_col), "║\n║"], 
            border_color, DARKBLUE
        # Entry fullname row rendering.
        let target = if self.hentry.is_link: newDirEntry((kind: self.hentry.kind, path: self.hpath.truePath))
            else: self.hentry
        var 
            entry_id = $target
            ext = entry_id.splitFile.ext.undot
        if ext != "" and ext.runeLen < total_width and not target.is_dir: # Adding separate extension cell.
            entry_id = entry_id.changeFileExt ""
            let left_col = total_width - ext.runeLen - 1
            host.write [entry_id.fit_left(left_col),"\a\x01", if entry_id.runeLen>left_col: "…" else: "\u2192"],
                target.coloring
            host.write [ext, "\a\x01║\n"], target.coloring
        else: 
            host.write entry_id.fit_left(total_width), target.coloring, if self.show_repr: hl_color else: DARKBLUE
            host.write [if entry_id.runeLen>total_width:"…" else:"║","\n"], border_color, DARKBLUE
        # 2nd footline rendering.
        let (stat_feed, clr) = if sel_stat.files > 0 or sel_stat.dirs > 0: (sel_stat, '\x07') else: (dir_stat, '\x05')
        let total_size = &" \a{clr}{stat_feed.bytes.by3} bytes in {stat_feed.files} files\a\x01 "
        host.write ["╚", total_size.center(total_width+4, '-').replace("-", "═"), "╝"]
        # Finalization.
        return self

    proc newDirViewer(term: TerminalEmu): DirViewer =
        type fix = proc(x: DirEntry, y: DirEntry): int {.closure.}
        result = DirViewer(host: term, visible: true)
        result.sorters = collect(newSeq): (for sorter in @[name_sorter,ext_sorter,size_sorter,mtime_sorter]:sorter.fix)
        result.chdir(getAppFilename().root_dir)
# -------------------- #
when not defined(CommandLine):
    type CommandLine = ref object of Area
        host:   TerminalEmu
        log:    seq[string]
        shell:  Process
        origin: int
        dir_feed:   proc(): DirViewer
        prompt_cb:  proc(name: string)
        input, prompt: string
        fullscreen, through_req, input_changed: bool
    const 
        max_log = 99999
        exit_hint = " ESC to return "

    # --Properties:
    template running(self: CommandLine): bool    = not self.shell.isNil and self.shell.running
    template exclusive(self: CommandLine): bool  = self.running or self.fullscreen
    template requesting(self: CommandLine): bool = self.prompt != ""

    # --Methods goes here:
    proc scroll(self: CommandLine, shift: int) =
        origin = max(0, min(origin + shift, log.len - host.vlines))

    proc record(self: CommandLine, line: string) =
        log.add(line); scroll log.len

    proc record(self: CommandLine, lines: seq[string]) =
        for line in lines: log.add(line)
        scroll log.len

    proc shell(self: CommandLine, cmd: string = "") =
        let command = (if cmd != "": cmd else: input)
        record(&"\a\x03>>\a\x04{command}")
        shell = when defined(windows): 
              startProcess "cmd.exe",   dir_feed().path, ["/c", command], nil, {poStdErrToStdOut, poDaemon}
        else: startProcess "/bin/bash", dir_feed().path, [command, "|| exit"]
        input = ""

    proc request(self: CommandLine; hint, def_input: string; cb: proc(name: string)) =
        if not self.requesting: prompt = hint; input = def_input; prompt_cb = cb

    proc request(self: CommandLine, hint: string, cb: proc(name: string)) =
        request hint, "", cb

    proc through_request(self: CommandLine, hint: string) =
        proc void(faux: string) = discard
        request(hint, void); through_req = true

    proc end_request(self: CommandLine) =
        prompt = ""; input = ""; through_req = false

    proc paste(self: CommandLine, text: string) =
        input &= text; input_changed = true

    method update(self: CommandLine): Area {.discardable.} =
        # Init setup.
        input_changed = false
        # Service controls.
        let (x, y) = host.pick()
        if y == 0 and x >= host.hlines - exit_hint.len and MOUSE_Left_Button.IsMouseButtonReleased and fullscreen:
            fullscreen = false
        if KEY_Escape.IsKeyPressed: fullscreen = not fullscreen
        # Deferred output handling.
        defer: 
            if not shell.isNil and shell.hasData: 
                record shell.outputStream.readLine.convert(srcEncoding = cmd_cp)
                if log.len > max_log: log = log[log.len-max_log..^1]; scroll(log.len) # Memory saving.
        if self.exclusive: # Scrolling controls.
            scroll -GetMouseWheelMove()
            if KEY_PageUp.IsKeyDown:      (if norepeat(): scroll -host.vlines)
            elif KEY_PageDown.IsKeyDown:  (if norepeat(): scroll +host.vlines)
            elif KEY_Up.IsKeyDown:        (if norepeat(): scroll -1)
            elif KEY_Down.IsKeyDown:      (if norepeat(): scroll 1)
            elif KEY_Pause.IsKeyPressed:  (if self.running: shell.kill)
        else: # Input controls.
            if input != "": # Backspace only if there are text to remove.
                if KEY_Backspace.IsKeyDown: # Delete last char.
                    if norepeat(): input = input.runeSubstr(0, input.runeLen-1); input_changed = true
            if KEY_Enter.IsKeyPressed: # Input actualization.
                if not through_req:
                    if self.requesting: prompt_cb(input); end_request(); abort() elif input != "": shell(); abort()
                else: input = ""
            elif KEY_Pause.IsKeyPressed and self.requesting: end_request(); abort() # Cancel request mode.
            elif shift_down() and KEY_Insert.IsKeyPressed: paste $GetClipboardText(); abort()
            let key = GetKeyPressed()
            if key > 0: paste($(key.Rune))
        # Finalization.
        return self

    method render(self: CommandLine): Area {.discardable.} =
        # Output log.
        if self.exclusive: 
            for line in log[origin..<min(log.len, origin+host.hlines)]: host.write [line, $'\n'], GRAY
            if fullscreen: host.with loc(host.hlines - exit_hint.len, 0), write(exit_hint, BLACK, DARKGRAY)
            return
        # Commandline.
        host.margin = 0
        host.write "\n"
        if self.requesting: host.write [prompt, if through_req: "\a\x09" else: "\a\x06"], BLACK, 
            if through_req: PURPLE else: ORANGE
        else: host.write [dir_feed().path_limited, "\a\x03"], RAYWHITE, BLACK
        let prefix_len = host.hpos() + 2 # 2 - for additonal symbol and pointer.
        let full_len = prefix_len + input.runeLen
        host.write [if prompt.len > 0: "\x10" else: ">", "\a\x04", if full_len >= host.hlines: "…" else: " ",
            if full_len >= host.hlines: input.runeSubstr(-(host.hlines-prefix_len-2)) else: input, 
                (if getTime().toUnix %% 2 == 1: "_" else: ""), "\n"], Color(), BLACK
        # Finalization.
        return self

    proc newCommandLine(term: TerminalEmu, dir_feeder: proc(): DirViewer): CommandLine =
        result = CommandLine(host: term, dir_feed: dir_feeder)
# -------------------- #
when not defined(Alert):
    type Alert = ref object of Area
        host:    TerminalEmu
        message: seq[string]
        answer, msg_len: int

    # --Properties:
    template ypos(self: Alert): int = host.vlines div 2 - 3

    # --Methods goes here:
    method update(self: Alert): Area {.discardable.} =
        # Mouse controls.
        var input = if MOUSE_Left_Button.IsMouseButtonReleased:
            let h_center = host.hlines div 2
            let (x, y) = host.pick()
            if   y == self.ypos + 1 and x >= h_center - 1 and x <= h_center + 1: "n"
            elif y == self.ypos + 3 and x >= h_center - 3 and x <= h_center - 1: "y"
            elif y == self.ypos + 3 and x >= h_center + 1 and x <= h_center + 3: "n"
            else: " "
        # Keyboard controls
        elif KEY_Escape.IsKeyPressed: "n"
        elif KEY_Space.IsKeyPressed:  "y"
        else: $(GetKeyPressed().Rune)
        # Finalization.
        case input
            of "n", "N": abort()
            of "y", "Y": answer = 1; abort()
        return self

    method render(self: Alert): Area {.discardable.} =
        parent.render()
        host.margin = 0
        let delim = "█ ".repeat host.hlines div 2
        with host:
            loc(0, self.ypos)
            write [delim, "\n\a\x03", "[X]".center(host.hlines), "\n\a\x06", " ".center(host.hlines), "\n\a\xff", 
                "<Yes/No>".center(host.hlines), "\n\a\x08 ", delim], MAROON, BLACK
            loc((host.hlines - msg_len) div 2, self.ypos + 2)
            write message
        return self

    proc newAlert(term: TerminalEmu, creator: Area, msg: string): Alert =
        let msg_chunks = (&"{msg} ?").split('\n')
        result = Alert(host: term, parent: creator, msg_len: msg_chunks.join("").runeLen)
        result.message = collect(newSeq): # Decorated message chunks.
            for idx, chunk in msg_chunks: "\a" & (if idx %% 2 == 0: '\x06' else: '\x09') & chunk
        try: result.host.loop_with result except: discard
# -------------------- #
when not defined(ProgressWatch):
    type ProgressWatch = ref object of Area
        host:   TerminalEmu
        ticks: int
        start, frame_start: Time
        operation, status: string
        cancelled, frameskip: bool
    const cancel_hint = " ESC to cancel │"

    # --Properties:
    template elapsed(self: ProgressWatch): Duration = getTime() - self.start

    # --Methods goes here:
    proc cancel(self: ProgressWatch) =
        cancelled = true; abort("Task was cancelled by user.")

    proc tick(self: ProgressWatch, status: string) =
        ticks.inc
        if (getTime() - frame_start).inMilliseconds >= 50:
            self.status = status
            host.update self; frame_start = getTime()

    method update(self: ProgressWatch): Area {.discardable.} =
        let (x, y) = host.pick()
        if y == host.vlines-1 and MOUSE_Left_Button.IsMouseButtonReleased: cancel()
        if KEY_Escape.IsKeyPressed: cancel()
        if WindowShouldClose(): quit()        
        return self

    method render(self: ProgressWatch): Area {.discardable.} =
        # Init setup.
        parent.render()
        if frameskip: frameskip = false; return self
        if self.elapsed.inMilliseconds < 100: return self
        # Status render.
        if status != "": host.with:
                loc(0, 0)
                write [operation, "\a\x0D│\a\x0A", status.fit_left(host.hlines)], Orange, DarkGray
                loc(host.hlines - ticks.`$`.len - 1, 0)
                write ["│\a\x06", $ticks], Black
        # Timeline render.
        let midline = host.vlines div 2 - 1
        for y in (status!="").int..host.vlines-2:
            let 
                shift  = self.elapsed.inSeconds + 1 * (y - midline)
                time   = initDuration(seconds = 0.int64.max(shift))
                (decor, border, color) = if y == midline: ("█", "|", Lime)
                    elif y == midline-1: ("▄", "│", Lime.Fade(0.5))
                    elif y == midline+1: ("▀", "│", Lime.Fade(0.5))
                    else: ("", "│", DarkGray)
            with host:
                loc(host.hlines div 2 - 4 - decor.runeLen, y)
                write decor, color, DarkBlue
                write [border, &"{time.inHours:02}:{time.inMinutes%%60:02}:{time.inSeconds%%60:02}", border.reversed], 
                    color, Black
                write decor.reversed, color, DarkBlue
        # Finalzation.
        host.loc(-(self.elapsed.inSeconds.int %% cancel_hint.runeLen), host.vlines - 1)
        host.write cancel_hint.repeat(host.hlines div cancel_hint.runeLen + 2), BLACK, SkyBlue
        return self

    proc newProgressWatch(term: TerminalEmu, creator: Area, op = ""): ProgressWatch =
        ProgressWatch(host: term, parent: creator, operation: op,start: getTime(), frameskip: true)
# -------------------- #
when not defined(FileViewer):
    type DataLine   = tuple[origin: int, data: string]
    type ScreenLine = tuple[prefix: string, colored: string, raw: string]
    type FileViewer = ref object of Area
        host:  TerminalEmu
        feed:  Stream
        cache: seq[DataLine]
        src, lense_id: string
        walker:        iterator:BiggestInt
        fkey_feed:     proc(x, y: int): int
        fullscreen, lense_switch, hide_colors, night, line_numbers: bool
        x, y, pos, xoffset, linecount, feedsize, char_total, widest_line, hexpos_edge, ticker, f_key: int
        lenses: Table[string, proc(fv: FileViewer): iterator:ScreenLine]
    type FVControls = enum
        none, lense, minmax, lscroll, rscroll
    const
        dl_cap = ['\n']
        border_shift = 2
        cell = "FF ".len

    # --Properties:
    template feed_avail(self: FileViewer): bool  = not feed.isNil
    template data_piped(self: FileViewer): bool  = feed of StringStream
    template width(self: FileViewer): int        = self.host.hlines div (2 - self.fullscreen.int)
    template hcap(self: FileViewer): int         = self.width - border_shift * (not self.fullscreen).int
    template vcap(self: FileViewer): int         = self.host.vlines - border_shift * 2 + self.fullscreen.int
    template hexcap(self: FileViewer): int       = (self.hcap-(if line_numbers:self.hexpos_edge else:0)) div (cell+1) 
    template hexcells(self: FileViewer): int     = self.hexcap * self.vcap
    template right_edge(self: FileViewer): int   = widest_line - self.hcap
    template margin(self: FileViewer): int       = xoffset * (not self.fullscreen).int
    template caption(self: FileViewer): string   = (if fullscreen: self.src else: self.src.extractFilename)
    template active(self: FileViewer): bool      = self.fullscreen
    template bg(self: FileViewer): Color         = (if self.night: BLACK     else: DARKBLUE.Fade 0.7)
    template fg(self: FileViewer): Color         = (if self.night: LightGray else: RayWhite)
    template brd_color(self: FileViewer): Color  = (if self.night: Beige.Fade 0.7  else: GRAY)
    template ctrl_color(self: FileViewer): Color = DARKGRAY
    template fixed_view(self: FileViewer): bool  = self.data_piped or not self.feed_avail

    proc caption_limited(self: FileViewer): string =        
        if self.caption.runeLen > self.hcap-2: &"…{self.caption.runeSubStr(-self.hcap+4)}" else: self.caption

    proc hints(self: FileViewer): string =
        [" | |\x1AView\x1B", if self.fixed_view: "" elif lense_id == "ASCII": ":HEX" else: ":ASCII", 
            if self.fixed_view: "" elif self.night: "Day" else: "Night", 
                if self.fixed_view: "" elif self.line_numbers: "-LNums" else: "+LNums", " | | |Exit"].join "|"

    proc hintmask(self: FileViewer): seq[int] = 
        @[3, 10, if self.fixed_view: 0 else: 4, if self.fixed_view: 0 else: 5, if self.fixed_view: 0 else: 6]

    iterator cached_chars(self: FileViewer, start = 0): char =
        for line in cache:
            if line.origin >= start or start in line.origin..line.origin+line.data.len:
                for idx, chr in line.data: (if idx+line.origin >= start: yield chr)

    # --Methods goes here:
    proc picked_control(self: FileViewer): FVControls =
        let (x, y) = host.pick()
        if y == 0: # Headerline
            if x in self.margin+1..self.margin+2+lense_id.runeLen:
                return FVControls.lense
            if x+fullscreen.int*border_shift in self.margin+self.hcap-"╡↔╞".runeLen+1..self.margin+self.hcap:
                return FVControls.minmax
        elif y == self.vcap+border_shift:
            if x == 0:           return FVControls.lscroll
            if x == self.hcap-1: return FVControls.rscroll
        return FVControls.none

    proc vscroll(self: FileViewer, shift = 0) =
        y += shift # Check is postponed due to uncertain nature.
        pos = max(0, min(feedsize-self.hexcells, pos+self.hexcap*shift))

    proc hscroll(self: FileViewer, shift = 0) =
        x = max(0, min(self.right_edge, x + shift))

    proc dir_checkout(self: FileViewer, path: string): string =
        # Init setup.
        var 
            subdirs, files, surf_size, hidden_dirs, hidden_files: BiggestInt
            ext_table: CountTable[string]
        const block_sep = "\a\x05" & ".".repeat(22)
        # Analyzing loop.
        for record in walkDir(path.normalizePathEnd(true).truePath, checkDir = true): 
            if record.path.dirExists: # Subdir registration.
                subdirs.inc
                if record.path.isHidden: hidden_dirs.inc
            else:                     # File registration.
                files.inc; surf_size += record.path.getFileSize
                if record.path.isHidden: hidden_files.inc
                ext_table.inc(record.path.splitFile.ext)
        # Deep analyzing preparations.
        if subdirs > 0: walker = iterator: BiggestInt =
            var total_size, total_files, total_dirs: BiggestInt
            let start = getTime()
            while (getTime() - start).inMilliseconds < 500: yield 0 # Init delay.
            for dir in lazy_xtree(path.normalizePathEnd(true).truePath):
                try:
                    yield 0
                    let files = toSeq(walkFiles(dir / "*"))                    
                    for file in files: total_size += file.getFileSize; total_files.inc; yield total_size
                    total_dirs.inc
                except: discard # FS error = no count.
            if ext_table.len > 0: feed.writeLine(block_sep)
            feed.writeLine(&"Total data size: \a\x06{total_size.by3}\a\xff bytes")
            feed.writeLine(&"Total sub-directories: \a\x06{(total_dirs-1).by3}")
            feed.writeLine(&"Total files: \a\x06{total_files.by3}")
            feed.setPosition feedsize # Tracing pos back for new stuff to get readen.
            yield -1 # Signalling self-disposal.
        # Extensions breakdown.
        ext_table["\a\x05<nil>"] = ext_table[""]
        ext_table.del("")
        ext_table.sort()
        let ext_sum = collect(newSeq): 
            for key,val in ext_table.pairs: 
                (&"\a\x05{key}\a\x00: \a\x06{val}\a\x00").replace(".", ".\a\x00").align_left(22,' '.Rune) & 
                    &" (\a\x09{(val/files.int*100):.2f}%\a\x00)"               
        # Finalization.
        let
            path_hdr = &"Sum:: \a\x06{(path.normalizePathEnd(true).truePath(false)).convert(cmd_cp, \"UTF-8\")}\a\x05"
            link_hdr = &"Link\x1A \a\x09{path.normalizePathEnd(true).truePath.convert(cmd_cp, \"UTF-8\")}\a\x05"
            widest_hdr = max(path_hdr.len, link_hdr.len)
        return [join([&"{path_hdr.alignLeft(widest_hdr, ' ')}|", # Getting border to widest header.
                if path.symlinkExists: &"{link_hdr.alignLeft(widest_hdr, ' ')}|" else: ""].filterIt(it != ""), "\n"),
            "\a\x05" & "=".repeat(widest_hdr-4) & "/", "", &"Surface data size: \a\x06{surf_size.by3}\a\xff bytes", 
            &"Sub-directories: \a\x06{subdirs.by3}\a\xff (\a\x09{hidden_dirs.by3}\a\xff hidden)",
            &"Files: \a\x06{files.by3}\a\xff (\a\x09{hidden_files.by3}\a\xff hidden)", block_sep, ext_sum.join("\n")
        ].join("\n")

    proc close(self: FileViewer): FileViewer {.discardable.} =
        if self.feed_avail:
            feed.close()
            feed = nil
            walker = nil
        src = ""
        night = false
        cache.setLen 0
        ticker       = 0
        char_total   = 0
        widest_line  = 0
        line_numbers = false
        lense_switch = false
        (x, pos, y)  = (0, 0, 0)
        return self

    proc pipe(self: FileViewer, text: string, title = "") =
        close()
        src         = title
        feedsize    = text.len
        linecount   = text.count('\n')
        feed        = text.newStringStream()

    proc open(self: FileViewer, path: string, force = false) =
        if force or path != src: 
            close()
            try: 
                if path.dirExists: pipe dir_checkout(path)
                else: feed = path.truePath.newFileStream fmRead; feedsize = path.getFileSize.int; linecount = int.high
            except: discard # special case to not use handler to MultiViewer.
        src = path.absolutePath

    proc read_data_line(self: FileViewer): DataLine =
        if self.feed_avail: # If reading is possible:
            let origin = feed.getPosition
            var buffer: seq[char]
            while not feed.atEnd:
                let chr = feed.readChar
                buffer.add chr
                if chr in dl_cap: break
            return (origin, buffer.join "")    

    proc noise_lense(self: FileViewer): iterator:ScreenLine =
        return iterator:ScreenLine =        
            for y in 0..<self.vcap:
                let noise = collect(newSeq): (for x in 0..<self.hcap: "    01".sample)
                yield ("", "", noise.join "")

    proc ascii_lense(self: FileViewer): iterator:ScreenLine =
        let aligner = cache.len.`$`.len
        var fragment = cache[y..^1]
        fragment.setLen self.vcap
        self.hide_colors = true
        return iterator:ScreenLine = 
            for idx, line in fragment:
                let lnum = y + idx
                yield ((if line_numbers and lnum<=self.linecount and linecount!=0: (lnum+1).`$`.fit_left(aligner)&"|"
                else: ""), "", line.data.subStr(x).dup(removeSuffix("\c\n")))

    proc ansi_lense(self: FileViewer): iterator:ScreenLine =
        let feed = ascii_lense()
        self.hide_colors = false
        return iterator:ScreenLine = 
            for (prefix, colored, raw) in feed: yield ("", colored, raw.dup(removeSuffix('\n')))

    proc hex_lense(self: FileViewer): iterator:ScreenLine =
        var 
            accum: seq[string]
            recap: seq[char]
            lines_left = self.vcap
            fpos = pos
        self.hide_colors = true
        template row_out(sum = recap.join "") = # Aux template
            lines_left.dec 
            yield ((if line_numbers: (&"{fpos:X}|").align(self.hexpos_edge, '0') else: ""), "", accum.join("") & sum)
        return iterator:ScreenLine =
            for chr in self.cached_chars(pos): 
                accum.add &"{chr.int32:02X}" & # Smart delimiting.
                    (if accum.len == self.hexcap-1: '\xBA' elif accum.len %% 5 == 4: '\xB3' else: ' ')
                recap.add chr
                if accum.len >= self.hexcap:
                    row_out()
                    fpos += recap.len               
                    if lines_left == 0: return
                    accum.setLen 0
                    recap.setLen 0
            if accum.len > 0: row_out ' '.repeat(self.hexcap*cell-accum.len*cell-1) & "\xBA" & recap.join ""
            for exceed in 1..lines_left: yield ("", "", "")

    proc cycle_lenses(self: FileViewer): FileViewer {.discardable.}  =
        lense_switch = not lense_switch
        return self

    proc switch_fullscreen(self: FileViewer, new_state = -1): FileViewer {.discardable.} =
        fullscreen = if new_state == -1: not fullscreen else: new_state.bool
        vscroll(); hscroll(); night = false
        return self

    proc switch_lighting(self: FileViewer, new_state = -1) =
        night = not (if new_state == -1: night else: new_state.bool)

    proc post_render(self: FileViewer) =
            host.loc(0, host.vpos)
            if x>0: host.write "\x11", GOLD, DARKGRAY else: host.write "│", self.brd_color, self.bg 
            host.loc(host.hlines-1, host.vpos)
            if x<self.right_edge: host.write "\x10", GOLD, DARKGRAY: else: host.write "│", self.brd_color, self.bg 

    method update(self: FileViewer): Area {.discardable.} =
        f_key = 0 # F-key emulator.
        # Deffered data update.
        defer:
            lense_id = if self.feed_avail: # Data pumping.
                let start = getTime()
                while (cache.len < y + self.vcap or char_total < pos+self.hexcells) and not feed.atEnd:
                    let line = read_data_line()
                    cache.add line
                    char_total += line.data.len
                    widest_line = max(line.data.len, widest_line)
                    if (getTime() - start).inMilliseconds > 100 and not fullscreen: break # To not hang process.
                if cache.len > 0: # If there was any data.
                    if feed.atEnd: linecount = cache.len-1
                    hexpos_edge = (&"{feedsize:X}").len     # Should only be calculated here for performace.
                    y = max(0, min(y, linecount-self.vcap)) # Post-poned Y position update.
                    if self.data_piped: "ANSI" elif lense_switch xor '\0' in cache[0].data: "HEX" else: "ASCII"
                else: # Special handling for 0-size files.
                    (linecount, y, hexpos_edge) = (0, 0, 0)
                    if lense_switch: "HEX" else: "ASCII"
            else: "ERROR" # Noise garden.
            # Deep analyzis.
            if walker != nil:
                let start = getTime()
                ticker = (ticker + 1) %% 4
                for checkpoint in walker:
                    if checkpoint == -1: walker = nil; break
                    if (getTime() - start).inMilliseconds > 25: break
        # Mouse controls.
        let (x, y) = host.pick()
        if self.active:
            vscroll -GetMouseWheelMove()
            if MOUSE_Left_Button.IsMouseButtonDown:
                case picked_control():
                    of FVControls.lscroll: (if norepeat(): hscroll -1)
                    of FVControls.rscroll: (if norepeat(): hscroll +1)
                    else: discard
        if MOUSE_Left_Button.IsMouseButtonReleased:
            case picked_control():
                of FVControls.lense:    cycle_lenses()      # Switch view mode on inspector tag click.
                of FVControls.minmax:   switch_fullscreen() # Switch between preview & full modes.
                elif self.active: f_key = fkey_feed(x, y)   # Command buttons picking.
        # Keyboard controls.
        if self.active:
            if   KEY_PageUp.IsKeyDown:    (if norepeat(): vscroll -self.vcap)
            elif KEY_PageDown.IsKeyDown:  (if norepeat(): vscroll +self.vcap)
            elif KEY_Up.IsKeyDown:        (if norepeat(): vscroll -1)
            elif KEY_Down.IsKeyDown:      (if norepeat(): vscroll 1)
            elif KEY_Left.IsKeyDown:      (if norepeat(): hscroll -1)
            elif KEY_Right.IsKeyDown:     (if norepeat(): hscroll 1)
            elif KEY_F3.IsKeyPressed and not shift_down() or f_key == 3: switch_fullscreen 0
            elif KEY_F4.IsKeyPressed  or f_key == 4:                     cycle_lenses()
            elif KEY_F5.IsKeyPressed  or f_key == 5:                     (if not self.fixed_view(): switch_lighting())
            elif KEY_F6.IsKeyPressed  or f_key == 6:                     line_numbers = not line_numbers
            elif KEY_F10.IsKeyPressed or f_key == 10 or KEY_Escape.IsKeyPressed: return nil
        return self

    method render(self: FileViewer): Area {.discardable.} =
        # Init setup.        
        host.margin = self.margin
        let peller = if walker.isNil: " " else: $("\\|/-"[ticker])
        proc write_centered(text: string, color: Color) =
            host.loc (self.hcap - text.runeLen) div 2 + self.margin, host.vpos()
            host.write @[" ", text, " "], color, self.ctrl_color
        # Header render.
        with host:
            loc(self.margin, 0)
            write if fullscreen: "╘" else: "╒", self.brd_color, self.bg
            write [" ", lense_id, "\a\x09", peller], if self.feed_avail: SKYBLUE else: RED, self.ctrl_color
            write "═".repeat(self.hcap-lense_id.runeLen-5-fullscreen.int*border_shift), self.brd_color, self.bg
            write (if fullscreen: "\x10│\x11" else: "╡↔╞"), GOLD, self.ctrl_color
            write [if fullscreen: "╛" else: "╕", ""], self.brd_color, self.bg
        if self.feed_avail and (y>0 or x>0 or fullscreen): # Locations hint.
            write_centered [if linecount-self.vcap>0: $y else: "*", ":", if self.right_edge > self.hcap: $x else: "*", 
                if self.data_piped or feedsize-self.hexcells<=0: "" else: &"/off={pos:X}"].join(""), PURPLE
        host.write "\n", self.brd_color, self.bg
        # Rendering loop.
        let 
            lborder = if xoffset > 0: "┤" else: "│"
            rborder = (if xoffset < host.hlines - self.width: "├" else: "│") & "\n"
            render_list = lenses[lense_id](self)
        for prefix, colored, line in render_list(): 
            let len_shift = (if self.hide_colors: 0 else: line.subStr(0, min(self.hcap, line.len)).count('\a') * 2) -
                prefix.len
            with host:
                write if fullscreen: "" else: lborder
                write prefix, Purple # Line numbers, etc.
                write line.convert(srcEncoding=cmd_cp).fit_left(self.hcap+len_shift), self.fg, raw=self.hide_colors
                write if fullscreen: "\n" else: rborder, self.brd_color
        # Footing render.
        with(host):
            write if fullscreen: "╒" else: "╘"
            write "═".repeat(self.hcap - fullscreen.int * 2), self.brd_color, self.bg
            write if fullscreen: "╕" else: "╛"
        write_centered self.caption_limited, (if self.feed_avail: Orange else: Maroon)
        if self.fullscreen: host.write "\n"
        # Finalization.
        return self

    proc newFileViewer(term: TerminalEmu, xoffset: int, fkey_feeder: proc(x, y: int): int, src = ""): FileViewer =
        result = FileViewer(host: term, xoffset: xoffset, fkey_feed: fkey_feeder).close()
        type fix = proc (fv: FileViewer): iterator:ScreenLine {.closure.}{.closure.} # Some compiler glitches.
        result.lenses = 
            {"ASCII": ascii_lense.fix, "ANSI": ansi_lense.fix, "HEX": hex_lense.fix, "ERROR": noise_lense.fix}.toTable
        if src != "": result.open src

    proc destroy(self: FileViewer): FileViewer {.discardable.} =
        close()
        return nil
# -------------------- #
when not defined(MultiViewer):
    type ErrRecord   = tuple[msg: string, time: Time]
    type MultiViewer = ref object of Area
        host:      TerminalEmu
        viewers:   seq[DirViewer]
        cmdline:   CommandLine
        error:     ErrRecord
        errorlog:  seq[ErrRecord]
        inspector: FileViewer
        watcher:   ProgressWatch
        current, f_key: int
        dirty, quick_search: bool
    const hint_width  = 6

    # --Properties:
    template active(self: MultiViewer): DirViewer      = self.viewers[self.current]
    template next_index(self: MultiViewer): int        = (self.current+1) %% self.viewers.len
    template next_viewer(self: MultiViewer): DirViewer = self.viewers[self.next_index]
    template next_path(self: MultiViewer): string      = self.next_viewer.path
    template inspecting(self: MultiViewer): bool       = not inspector.isNil
    template inspected_path(self: MultiViewer): string = (if self.inspecting: self.inspector.src else: "")
    template previewing(self: MultiViewer): bool       = self.inspecting and not self.inspector.fullscreen
    template fullview(self: MultiViewer): bool         = self.inspecting and self.inspector.fullscreen
    template hint_prefix(self: MultiViewer): string    = " ".repeat(host.hlines div 11 - hint_width - 1) & "F"
    template hint_cellwidth(self: MultiViewer): int    = hint_width + self.hint_prefix.runeLen + 1
    template hint_margin(self: MultiViewer): int       = (host.hlines - (self.hint_cellwidth.float * 10.5).int) div 2

    # --Methods goes here:
    proc select(self: MultiViewer, idx: int = 0) =
        for view in viewers: view.active = false
        viewers[idx].active = true
        current = idx

    proc sync(self: MultiViewer, feed: DirViewer) =
        for view in viewers:
            if view != feed and view.path == feed.path: 
                let prev_hl = view.hline
                view.refresh().scroll_to prev_hl

    proc pick_fkey(self: MultiViewer; x, y: int): int =
        if y == host.vlines-1:
            let index = (x-(self.hint_prefix.runeLen + self.hint_margin - 1)) / self.hint_cellwidth + 1
            if index-index.int.float < (1.1-0.1*(self.hint_prefix.runeLen).float): return index.int

    proc register_err(self: MultiViewer, err: ref Exception) =
        error = (msg: err.msg, time: getTime())
        if not (err of ReraiseError): errorlog.add(error)

    proc reset_watcher(self: MultiViewer, op = "") =
        watcher = newProgressWatch(host, self, op)

    proc warn(self: MultiViewer, message: string): int =
        if not watcher.isNil: watcher.frameskip = true
        return newAlert(host, self, message).answer

    proc navigate(self: MultiViewer, path: string) =
        discard self.active.chdir path

    proc transfer(self: MultiViewer; src, dest: string; file_proc: proc(src, dest: string), destructive=false): bool =
        proc tick(now_processing: string) = watcher.tick now_processing # aux binding.        
        if not (dest.fileExists or dest.dirExists) or # Checking if dest already exists.
            warn(&"Are you sure want to overwrite \n{dest.extractFilename}\n") > 0:
                let start = getTime()
                if src.dirExists: src.transfer_dir(dest, destructive, tick)
                else: tick(src); dest.removeFile; src.file_proc(dest)
                return true

    template sel_transfer(self: MultiViewer, file_proc: untyped, destructive = false, ren_pattern = "") =
        # Init setup.
        var 
            last_transferred: string
            sel_indexes = self.active.selected_indexes # For selection removal.
        reset_watcher(if destructive: "Move" else: "Copy")
        uninspect()
        # Deffered finalization.
        defer:
            if self.next_viewer.dirty: # Only if any changes happened.
                self.next_viewer.refresh().scroll_to_name(last_transferred)
                select self.next_index
        # Transfer loop.
        for entry in self.active.selected_entries:
            if entry.name != direxit.name: # No transfer for ..
                let src = self.active.path / entry.name
                let dest = self.next_path / src.extractFilename.wildcard_replace(
                    if ren_pattern != "": ren_pattern else: "*.*")
                if (not self.next_path.startsWith src) and transfer(src, dest, file_proc, destructive):
                    self.next_viewer.dirty = true # Setting 'dirty' flags.
                    if destructive: self.active.dirty = true
                    last_transferred = dest.extractFilename
            if sel_indexes.len > 0 and (entry.name == direxit.name or not destructive): # Selection removal.
                self.active.switch_selection sel_indexes[0], 0
                sel_indexes.delete 0

    proc uninspect(self: MultiViewer) =
        if self.inspecting: inspector = inspector.destroy()

    proc inspect(self: MultiViewer): FileViewer {.discardable.} =
        let 
            target = self.active.hentry
            path = self.active.path / self.active.hentry.name
        if self.inspecting: inspector.open path # <-Reusing existing fileviewer/opening new V
        else: inspector = newFileViewer(host, self.next_viewer.xoffset, ((x, y: int) => self.pick_fkey(x, y)), path)
        return inspector

    proc inspect(self: MultiViewer, text: string, title: string): FileViewer {.discardable.} =
        if not self.inspecting: 
            inspector = newFileViewer(host, self.next_viewer.xoffset, ((x, y: int) => self.pick_fkey(x, y)))
        inspector.pipe(text, title)
        return inspector
       
    proc copy(self: MultiViewer) =
        if self.active.path != self.next_path: sel_transfer(self, copyFile)

    proc move(self: MultiViewer, ren_pattern = "") =
        let src_viewer = self.active
        sel_transfer(self, moveFile, true, ren_pattern)
        src_viewer.refresh()

    proc new_dir(self: MultiViewer, name: string) =
        self.active.path.joinPath(name).createDir
        self.active.refresh.scroll_to_name name
        sync self.active

    proc new_link(self: MultiViewer, name: string) =
        if self.active.hentry.name != direxit.name:
            self.active.path.joinPath(self.active.hentry.name).createSymlink self.active.path / name
            self.active.refresh.scroll_to_name name
            sync self.active

    proc delete(self: MultiViewer) =
        # Init setup.
        proc tick(now_processing: string) = watcher.tick now_processing # aux binding
        reset_watcher("Delete")
        # Deffered finalization.
        defer:
            if self.active.dirty:
                self.active.refresh()
                sync(self.active)
        # Actual deletion.
        for idx, entry in self.active.selected_entries:
            if entry.name != direxit.name: # No deletion for ..
                let victim = self.active.path / entry.name
                if self.inspected_path == victim: inspector.close()
                if victim == self.active.path: self.active.chdir direxit.name
                if entry.is_dir: victim.remove_dir_ex(tick) else: tick(victim); victim.removeFile()
            else: self.active.switch_selection(idx, 0)
            self.active.dirty = true

    proc receive(self: MultiViewer, list: seq[string]) =
        # Init setup.
        var last_transferred: string
        reset_watcher()
        # Deffered finalization.
        defer:
            if self.active.dirty:
                self.active.refresh().scroll_to_name(last_transferred)
                sync self.active
        # Receiver loop.
        for src in list:
            if transfer(src, self.active.path / src.extractFilename, copyFile):
                last_transferred = src.extractFilename
                self.active.dirty = true

    proc show_help(self: MultiViewer) =
        inspect(help.core_help.join("\n"), "@HELP").switch_fullscreen(1).switch_lighting(0)

    proc show_errorlog(self: MultiViewer) =
        inspect(&"\a\x06{errorlog.len.by3}\a\xff erorrs occured since startup (\a\x02ESC\a\xff to return).\n\n" &
            errorlog.mapIt("\a\x09[" & it.time.local.format("HH:mm:ss") & 
                &"] \a\x08{it.msg.convert(cmd_cp, \"UTF-8\")}").join("\n"), "@ERRORS")
        .switch_fullscreen(1).switch_lighting(0)

    proc switch_inspector(self: MultiViewer) =
        if self.inspecting: uninspect() else: inspect()

    proc switch_inspector_fs(self: MultiViewer) =
        if not self.inspecting: inspect()
        inspector.switch_fullscreen 1

    proc switch_sorter(self: MultiViewer, criteria = SortCriteria.default) =
        self.active.switch_sorter criteria

    proc manage_selection(self: MultiViewer, pattern = "", new_state = true) =
        let mask = if pattern != "": pattern else: "*.*"
        for idx, entry in self.active.list:
            if entry.name.wildcard_match(mask): self.active.switch_selection(idx, new_state.int)

    proc request_navigation(self: MultiViewer) =
        cmdline.request &"Input path to browse \a\x03<{drive_list().join(\"|\")}>", (path:string) =>
            self.navigate path.strip(false, true)

    proc request_moving(self: MultiViewer) =
        if self.active.selection_valid:
            cmdline.request "Input renaming pattern \a\x03<*.*>", (pattern: string) =>
                self.move pattern.strip.strip(false, true)

    proc request_new_dir(self: MultiViewer) =
        cmdline.request "Input name for new directory", (name: string) => self.new_dir name

    proc request_new_link(self: MultiViewer) =
        if self.active.selection_valid:
            cmdline.request "Input name for new link", (name: string) => self.new_link name

    proc request_deletion(self: MultiViewer) =
        let target = if self.active.selected_entries.len > 1: &"\n{self.active.selected_entries.len}\n entris"
            elif self.active.hentry.name == dirrepr.name: "\nthis\n dir"
            else: &"\n{self.active.hentry.name}\n"
        if self.active.selection_valid and warn(&"Are you sure want to delete {target}") >= 1: delete()

    proc request_sel_management(self: MultiViewer, new_state = true) =
        cmdline.request "Input " & (if new_state: "" else: "un") & "selection pattern \a\x03<*.*>", (pattern:string) =>
            self.manage_selection(pattern.strip(false, true), new_state)

    proc pick_viewer(self: MultiViewer, x = GetMouseX(), y = GetMouseY()): int =
        if y < host.vlines - service_height:
            for idx, view in viewers: 
                if x in view.xoffset..view.xoffset+view.viewer_width: return idx
        return -1

    proc switch_quick_search(self: MultiViewer, new_state = -1) =
        let end_state = if new_state == -1: not quick_search else: new_state.bool
        quick_search = if end_state and not cmdline.requesting: cmdline.through_request("\x13Search"); true
            elif not end_state: cmdline.end_request();                                                 false
            else: quick_search # No changes.

    method update(self: MultiViewer): Area {.discardable.} =
        f_key = 0 # F-key emulator.
        try:
            if not self.fullview: cmdline.update()
            if self.fullview: (if inspector.update().isNil: uninspect())
            elif not cmdline.exclusive:
                # Mouse controls.
                let
                    (x, y) = host.pick()
                    picked_view_idx = pick_viewer(x, y)
                    fv_pick = if inspector.isNil: FVControls.none else: inspector.picked_control
                if MOUSE_Left_Button.IsMouseButtonDown or MOUSE_Right_Button.IsMouseButtonDown: # DirViewers picking.
                    if fv_pick == FVControls.none and picked_view_idx >= 0: select picked_view_idx
                elif MOUSE_Left_Button.IsMouseButtonReleased: f_key = pick_fkey(x, y) # Command buttons picking.
                # Drag/drop handling.
                let droplist = check_droplist()                
                if droplist.len > 0:
                    if picked_view_idx >= 0:
                        select picked_view_idx
                        receive droplist
                    elif y == host.vlines - service_height: cmdline.paste(droplist[0])
                # Hint controls (ctrl+).
                if control_down():
                    if   f_key==3 or KEY_F3.IsKeyPressed: switch_sorter SortCriteria.name
                    elif f_key==4 or KEY_F4.IsKeyPressed: switch_sorter SortCriteria.ext
                    elif f_key==5 or KEY_F5.IsKeyPressed: switch_sorter SortCriteria.size
                    elif f_key==6 or KEY_F6.IsKeyPressed: switch_sorter SortCriteria.mtime
                # Hint controls (shift+).
                elif shift_down():
                    if   f_key==2 or KEY_F2.IsKeyPressed: show_errorlog()
                    if   f_key==3 or KEY_F3.IsKeyPressed: switch_inspector_fs()
                    elif f_key==7 or KEY_F7.IsKeyPressed: request_new_link()
                # Hint controls (vanilla).
                else:
                    if   f_key==1 or KEY_F1.IsKeyPressed:   show_help()
                    elif f_key==3 or KEY_F3.IsKeyPressed:   switch_inspector()
                    elif f_key==5 or KEY_F5.IsKeyPressed:   copy()
                    elif f_key==6 or KEY_F6.IsKeyPressed:   request_moving()
                    elif f_key==7 or KEY_F7.IsKeyPressed:   request_new_dir()
                    elif f_key==8 or KEY_F8.IsKeyPressed:   request_deletion()
                    elif f_key==10 or KEY_F10.IsKeyPressed: quit()
                # Extra controls.
                if KEY_Home.IsKeyPressed:               request_navigation()
                elif KEY_Tab.IsKeyPressed:              select(self.next_index)
                elif KEY_End.IsKeyPressed:              cmdline.paste(self.active.hpath)
                elif KEY_KP_Add.IsKeyPressed:           request_sel_management()
                elif KEY_KP_Subtract.IsKeyPressed:      request_sel_management(false)
                elif KEY_Left_Alt.IsKeyPressed or KEY_Right_Alt.IsKeyPressed: switch_quick_search()
                # Quick search update.
                if quick_search and cmdline.input_changed: self.active.scroll_to_prefix cmdline.input
                # File viewer update.
                let start = getTime()
                if self.inspecting:
                    if self.previewing:
                        inspector.xoffset = self.next_viewer.xoffset
                        if self.active.hl_changed: inspect()
                    inspector.update()                    
                self.active.lapse = (getTime() - start).inMilliseconds
                # Viewer update.
                self.active.update()
                if dirty:
                    dirty = false
                    for viewer in viewers: viewer.refresh()
            elif cmdline.running: dirty = true # To update viewers later after cmd execution.
            # Finalization.
            if (getTime() - error.time).inSeconds > 2: error.msg = ""
        except: # Error message
            register_err(getCurrentException())        
            #error = (msg: getCurrentExceptionMsg().splitLines[0], time: getTime())
            for viewer in viewers: (if viewer.dirty: viewer.refresh().scroll_to(viewer.hline))        
        host.limit_fps(if host.focused: 60 else: 5)
        return self

    method render(self: MultiViewer): Area {.discardable.} =
        # Commandline/viewers render.
        if not self.fullview:
            if not cmdline.exclusive:
                let displaced = if self.previewing: self.next_viewer() else: nil
                var offset = 0
                for view in viewers: 
                    view.xoffset = offset # Offset lineup.
                    (if view == displaced: (view.adjust(); inspector) else: view).render() # Adjusting if no render.
                    offset += view.viewer_width # Caluclating next post after adjustment.
            cmdline.render()
        else: inspector.render()            
        if cmdline.exclusive: return
        # Hints.
        if error.msg != "": # Error message.
            host.write error.msg.splitLines[0].fit(host.hlines+1), BLACK, MAROON
        else: # Hot keys.
            var idx: int
            if self.fullview: f_key = inspector.f_key
            host.loc(self.hint_margin, host.vpos)
            let (hint_line, enabled) = if self.fullview:  (inspector.hints, inspector.hintmask)
                elif control_down():                      (" | |byName|byExt|bySize|byModi| | | | ",
                                                          @[3, 4, 5, 6])
                elif shift_down():                        (" |ErrLog|\x11View\x10| | | |MkLink| | | ",
                                                          @[2, 3, 7])
                else:                                     ("Help|Menu|View|Edit|Copy|RenMov|MkDir|Delete|PullDn|Quit",
                                                          @[1, 3, 5, 6, 7, 8, 10])
            for hint in hint_line.split("|"):
                idx.inc()
                host.write [self.hint_prefix, $idx], 
                    if f_key == idx or (KEY_F1+idx-1).KeyboardKey.IsKeyDown: Maroon else: hl_color, BLACK
                host.write hint.center(hint_width), BLACK, 
                    if control_down() and idx-3 == self.active.sorter.int: GOLD
                        elif idx==3 and self.previewing and not control_down(): Orange 
                            elif idx in enabled: SKYBLUE else: GRAY
            if self.fullview: inspector.post_render() # Drawing additional stuff for full-screen.
        # Finalization.
        return self

    proc newMultiViewer(term: TerminalEmu, viewers: varargs[DirViewer]): MultiViewer =
        result = MultiViewer(host: term, viewers: viewers.toSeq)
        let base = result
        result.cmdline = newCommandLine(term, () => base.active)
        result.select()
#.}

# ==Main code==
when isMainModule:    
    let 
        win = newTerminalEmu("Midday Commander", "res/midday.png", 110, 33, colors.default_palette)
        supervisor = newMultiViewer(win, newDirViewer(win), newDirViewer(win))
    win.loop_with supervisor