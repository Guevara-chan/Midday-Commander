import os, osproc, strutils, algorithm, sequtils, times, random, streams, sugar, strformat, encodings, tables, std/with
from unicode import Rune, runes, align, alignLeft, runeSubStr, runeLen, runeAt, capitalize, reversed, `==`, `$`
import browsers, threadpool, raylib
{.this: self.}

#.{ [Classes]
when not defined(Meta):
    # --Constants.
    const cmd_cp = when defined(windows): "cp866"
    else: "utf-8"
    type abort_ex = ReraiseError

    # --Service classes:
    type Area {.inheritable.} = ref object
        repeater, clicker: Time
        parent: Area
    method update(self: Area): Area {.discardable base.} = discard
    method render(self: Area): Area {.discardable base.} = discard
    proc norepeat(self: Area): bool = 
        if (getTime() - repeater).inMilliseconds > 110: repeater = getTime(); return true

    # --Service procs:
    template abort(reason = "")     = raise newException(abort_ex, reason)
    template control_down(): bool   = KEY_Left_Control.IsKeyDown()  or KEY_Right_Control.IsKeyDown()
    template shift_down(): bool     = KEY_Left_Shift.IsKeyDown()    or KEY_Right_Shift.IsKeyDown()
    template undot(ext: string): string                            = ext.runeSubstr((" " & ext).searchExtPos)
    template fit(txt: string, size: int, filler = ' '): string     = txt.align(size, filler.Rune).runeSubStr 0, size
    template fit_left(txt: string, size: int, filler = ' '): string= txt.alignLeft(size, filler.Rune).runeSubStr 0,size

    proc root_dir(path: string): string =
        var child = path
        while true: (if child.parentDir == ".": return child else: child = child.parentDir)

    proc drive_list(): seq[string] =
        when defined(windows):
            for drive in execCmdEx("wmic logicaldisk get caption,Access", {poDaemon}).output.splitLines[1..^1]
                .filterIt(it!=""):
                    if drive[0] != ' ': result.add drive.subStr(4).strip()
        else: @[]

    proc check_droplist(): seq[string] =
        if IsFileDropped():
            var idx, list_size: int32
            let listing = GetDroppedFiles(list_size.addr)
            result = collect(newSeq): (for x in 0..<list_size: $listing[x])
            ClearDroppedFiles()

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
            (dir, name, ext) = path.splitFile
            mask = pattern.splitFile
        return name.match_part(mask.name) and ext.undot.match_part(mask.ext.undot)

    # --Data:
    const help = @["\a\x03>\a\x01.",
        "\a\x03>\a\x06Midday Commander\a\x05 retrofuturistic file manager v0.06",
        "\a\x03>\a\x05Developed in 2*20 by \a\x04Victoria A. Guevara",
        "===================================================================================",
        "\a\x02ESC:\a\x01    switch between dir & console views OR deny alert choice OR cancel tracking",
        "\a\x02F1:\a\x01     display this cheatsheet (\a\x02ESC\a\x01 to return)",
        "\a\x02F3:\a\x01     switch preview mode on/off",
        "\a\x02F5:\a\x01     copy selected entri(s)",
        "\a\x02F6:\a\x01     request moving selected entri(s) with optional renaming",
        "\a\x02F7:\a\x01     request directory creation",
        "\a\x02F8:\a\x01     delete selected entri(s)",
        "\a\x02F10:\a\x01    quit program",
        "\a\x02F11:\a\x01    switch debug info on/off",
        "\a\x02Space:\a\x01  confirm alert choice",
        "\a\x02Insert:\a\x01 (un)select hilited entry",
        "\a\x02Home:\a\x01   request new path to browse",
        "\a\x02Left:\a\x01   move to begin of listing",
        "\a\x02Right:\a\x01  move to end of listing",
        "\a\x02Up:\a\x01     move selection/view 1 line up",
        "\a\x02Down:\a\x01   move selection/view 1 line down ",
        "\a\x02PgUp:\a\x01   move selection/view 1 page up",
        "\a\x02PgDown:\a\x01 move selection/view 1 page down",
        "\a\x02Pause:\a\x01  cancel query OR cancel command execution",
        "\a\x02End:\a\x01    paste fullpath to hilited entry into commandline",
        "\a\x02Enter:\a\x01  inspect hilited dir OR run hilited file OR execute command ",
        "\a\x07Shift+\a\x02Insert:\a\x01 paste clipboard to commandline",
        "\a\x07Numpad|\a\x02Enter:\a\x01 invert all selections in current dir",
        "\a\x07Numpad|\a\x02+:\a\x01     reqest pattern for mass selection in current dir",
        "\a\x07Numpad|\a\x02-:\a\x01     reqest pattern for mass deselection in current dir",
        "==================================================================================="]
# -------------------- #
when not defined(TerminalEmu):
    type TerminalEmu = ref object
        font:       Font
        cur, cell:  Vector2
        fg, bg:     Color
        palette:    seq[Color]
        dbginfo:    bool
        title:      string
        fps_table:  seq[int]
        margin, min_width, min_height: int

    # --Properties.
    template hlines(self: TerminalEmu): int = GetScreenWidth() div self.cell.x.int
    template vlines(self: TerminalEmu): int = GetScreenHeight() div self.cell.y.int
    template hpos(self: TerminalEmu): int = (self.cur.x / self.cell.x).int
    template vpos(self: TerminalEmu): int = (self.cur.y / self.cell.y).int

    # --Methods goes here:
    proc loc_precise(self: TerminalEmu, x = 0, y = 0) =
        cur.x = x.float; cur.y = y.float

    proc loc(self: TerminalEmu, x = 0, y = 0) =
        loc_precise((x.float * cell.x).int, (y.float * cell.y).int)

    proc write(self: TerminalEmu, txt: string, fg_init = Color(), bg_init = Color(); raw = false) =
        # Init setup.
        var ctrl: bool
        if fg_init.a > 0.uint8: fg = fg_init
        if bg_init.a > 0.uint8: bg = bg_init
        # Buffering.
        var chunks: seq[string]
        if not raw: # Buffering with control characters.            
            var buffer: string
            for chr in txt.runes:
                if chr.int > 31: buffer &= $chr
                else: 
                    if buffer != "": chunks.add buffer
                    buffer = ""
                    chunks.add $chr
            if buffer != "": chunks.add buffer
        else: chunks = @[txt]
        # Char render loop.
        for chunk in chunks:
            if ctrl:                                         # Control arg.
                fg = palette[chunk[0].int]
                ctrl = false
            elif chunk[0] == '\a' and not raw: ctrl = true   # Control character.
            elif raw or chunk[0] != '\n':
                let width = cell.x * chunk.runeLen.float
                cur.DrawRectangleV(Vector2(x: width, y: cell.y), bg)
                if chunk != " ": font.DrawTextEx(chunk, cur, font.baseSize.float32, 0, fg)
                cur.x += width
            else: loc_precise(margin * cell.x.int, (cur.y + cell.y).int) # new line.

    proc write(self: TerminalEmu, chunks: open_array[string], fg_init = Color(), bg_init = Color(), raw = false) =
        write "", fg_init, bg_init
        for chunk in chunks: write chunk, raw=raw

    proc pick(self: TerminalEmu, x = GetMouseX(), y = GetMouseY()): auto =
        (x div cell.x.int, y div cell.y.int)

    proc resize(self: TerminalEmu, hlines, vlines: int) =
        SetWindowSize hlines * cell.x.int, vlines * cell.y.int

    proc adjust(self: TerminalEmu) =
        resize max(self.hlines - self.hlines %% 2, min_width), max(self.vlines, min_height)

    proc update(self: TerminalEmu, areas: varargs[Area]) =
        # Common controls.
        if IsWindowResized(): self.adjust()
        if KEY_F11.IsKeyPressed: dbginfo = not dbginfo
        # Render cycle.
        loc_precise(); (fg, bg) = (WHITE, BLACK); margin = 0
        BeginDrawing()
        ClearBackground BLACK
        for area in areas: area.update().render()
        EndDrawing()
        # Finalization.
        fps_table.add GetFPS()
        while fps_table.len > 60: fps_table.delete 0
        SetWindowTitle(if dbginfo: &"{self.title} [fps: {min(fps_table)}~{max(fps_table)}]" else: title)

    proc loop_with(self: TerminalEmu, areas: varargs[Area]) = 
        while not WindowShouldClose(): update areas

    proc newTerminalEmu(title, icon: string; min_width, min_height: int; colors: varargs[Color]): TerminalEmu =
        # Init setup.
        FLAG_WINDOW_RESIZABLE.uint32.SetConfigFlags
        InitWindow(880, 400, title)
        60.SetTargetFPS
        0.SetExitKey
        getAppDir().setCurrentDir
        # Splash screen.
        let 
            text = "...LOADING..."
            sizing = MeasureTextEx(GetFontDefault(), text, 25, 0)
        for y in 0..1: # Temporary fix for raylib 3.0
            BeginDrawing()
            ClearBackground DARKBLUE
            DrawText(text, (GetScreenWidth()-sizing.x.int) div 2, (GetScreenHeight()-sizing.y.int) div 2, 25, RAYWHITE)
            EndDrawing()
        SetWindowIcon(LoadImage(icon))
        # Font setup.
        var glyphs: array[486, int]
        for i in 0..glyphs.high: glyphs[i] = i
        let rus_chars = collect(newSeq): (for x in 0x410..0x451: x)
        let extra_chars = @[
            0x2534,0x2551,0x2502,0x255F,0x2500,0x2562,0x2550,0x255A,0x255D,0x2554,0x2557,0x2026,0x2588,0x2192,0x2584,
                0x2580,0x2524,0x2552,0x2558,0x2555,0x255B,0x251C,0xB7,0xB0,0xA0
            ] & rus_chars
        glyphs[0x80..0x80+extra_chars.len-1] = extra_chars
        # Terminal object.
        result = TerminalEmu(font:"res/TerminalVector.ttf".LoadFontEx(12,glyphs.addr,glyphs.len), palette:colors.toSeq)
        result.cell  = result.font.MeasureTextEx("0", result.font.baseSize.float32, 0)
        (result.title, result.min_width, result.min_height) = (title, min_width, min_height)
        # Finalization.
        result.resize(110, 33) # Most tested size.
# -------------------- #
when not defined(DirEntry):
    type DirEntryDesc = tuple[id: string, metrics: string, time_stamp: string, coloring: Color]
    type DirEntry = object
        name: string
        kind: PathComponent
        size: BiggestInt
        mtime: Time
        memo: DirEntryDesc
        selected, hidden: bool
    const direxit = DirEntry(name: ParDir, kind: pcDir)

    # --Properties:
    template executable(self: DirEntry): bool   = self.name.splitFile.ext.undot in ExeExts
    template is_dir(self: DirEntry): bool       = self.kind in [pcDir, pcLinkToDir]

    proc coloring(self: DirEntry): Color =
        result = case kind:
            of pcDir, pcLinkToDir: WHITE
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
    proc `$`(self: DirEntry): string = (if self.is_dir: "/" elif self.executable: "*" else: " ") & name

    proc get_desc(self: DirEntry): DirEntryDesc =
        if memo.id == "": ($self, self.metrics, self.time_stamp, self.coloring) else: memo

    proc newDirEntry(src: tuple[kind: PathComponent, path: string]): DirEntry =
        DirEntry(name: src.path.extractFilename, kind: src.kind, size: src.path.getFileSize, hidden: src.path.isHidden,
            mtime: src.path.getLastModificationTime)
# -------------------- #
when not defined(DirViewer):
    type BreakDown = object
        files, dirs, bytes: BiggestInt
    type DirViewer = ref object of Area
        host: TerminalEmu
        path: string
        list: seq[DirEntry]
        dir_stat, sel_stat: BreakDown
        dirty, active, visible, hl_changed: bool
        hline, origin, xoffset, file_count, name_col, size_col, date_col, total_width, viewer_width: int
    const
        hdr_height      = 2
        foot_height     = 3
        service_height  = 2
        border_color    = GRAY
        tips_color      = GOLD
        hl_color        = SKYBLUE
        selected_color  = YELLOW

    # --Properties
    template capacity(self: DirViewer): int     = host.vlines - hdr_height - foot_height - service_height
    template hindex(self: DirViewer): int       = hline - origin
    template hentry(self: DirViewer): DirEntry  = self.list[self.hline]
    template hpath(self: DirViewer): string     = self.path / self.hentry.name

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
            for idx, entry in fragment: yield (origin + idx, entry)

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
        for idx, entry in list: (if entry.name == name: scroll_to idx)

    proc organize(self: DirViewer): auto {.discardable.} =
        list = list.sorted proc (x: DirEntry, y: DirEntry): int =
            if not x.is_dir and y.is_dir: return 1
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
        # Init setup.
        let prev_dir = path.extractFilename
        ((if newdir.isAbsolute: newdir else: path / newdir).normalizedPath & DirSep).setCurrentDir
        # Case correction.
        var corrector: string = getCurrentDir().root_dir.capitalize
        for parent in toSeq(getCurrentDir().parentDirs).reversed: # Case correction.
            for real_name in walkPattern(parent/../parent.extractFilename): 
                corrector = corrector / (real_name.extractFilename)
        path = corrector
        # Finalization.
        scroll_to(0).refresh()
        if newdir == ParDir: scroll_to_name(prev_dir) # Backtrace.
        return self

    proc exec(self: DirViewer, fname: string) =
        openDefaultBrowser (path / self.hentry.name).quoteShell

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

    method update(self: DirViewer): Area {.discardable.} =
        # Init setup.
        hl_changed   = false
        # Mouse controls.
        if not active: return self
        scroll -GetMouseWheelMove()
        let
            (x, y) = host.pick()
            pickline = y - hdr_height
            pickindex = pickline + origin
        if y < hdr_height or y >= host.vlines - service_height - foot_height: discard # Not service zone.
        elif MOUSE_Left_Button.IsMouseButtonReleased:  # Invoke item by double left click.
            if (getTime()-clicker).inMilliseconds<=300: clicker = Time(); (if pickline == self.hindex: invoke hentry())
            else: clicker = getTime()
        elif MOUSE_Right_Button.IsMouseButtonReleased: (if pickindex < list.len: switch_selection pickindex)# RB=select
        elif MOUSE_Left_Button.IsMouseButtonDown:      # HL items if left button down.
            if pickindex != self.hline and pickindex < list.len: scroll_to pickindex
        # Kbd controls.
        if KEY_UP.IsKeyDown:         (if norepeat(): scroll -1)
        elif KEY_Down.IsKeyDown:     (if norepeat(): scroll 1)
        elif KEY_Page_Up.IsKeyDown:  (if norepeat(): scroll -self.capacity)
        elif KEY_Page_Down.IsKeyDown:(if norepeat(): scroll self.capacity)
        elif KEY_Left.IsKeyPressed:   scroll_to 0
        elif KEY_Right.IsKeyPressed:  scroll_to list.len
        elif KEY_Enter.IsKeyPressed:  invoke self.hentry
        elif KEY_Insert.IsKeyPressed: switch_selection(hline); scroll 1
        elif KEY_KP_Enter.IsKeyPressed: select_inverted()
        # Finalization.
        return self

    method render(self: DirViewer): Area {.discardable.} =
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
            write ["║\a\x02", "Name".center(name_col), "\a\x01│\a\x02", "Size".center(size_col), "\a\x01│\a\x02",
                "Modify time".center(date_col), "\a\x01║\n"], border_color, DARKBLUE
        # List rendering.
        for idx, entry in self.render_list:
            let desc = cache_desc(idx)
            let text_color = if entry.selected: selected_color else: desc.coloring
            with host:
                write (if entry.selected: "╟" else : "║"), border_color, DARKBLUE
                write [desc.id.fit_left(name_col), "\a\x01", if ($entry).runeLen>name_col:"…" else:"│"], text_color,
                    if active and idx == hline: hl_color else: DARKBLUE # Highlight line.
                write [desc.metrics.fit(size_col), "\a\x01│"], text_color
                write desc.time_stamp.fit_left(date_col), text_color
                write ["\a\x01", (if entry.selected: "╢" else : "║"), "\n"], text_color, DARKBLUE
        # 1st footline rendering.
        host.write ["║", "─".repeat(name_col), "┴", "─".repeat(size_col), "┴", "─".repeat(date_col), "║\n║"], 
            border_color, DARKBLUE
        # Entry fullname row rendering.
        var 
            entry_id = $hentry()
            ext = entry_id.splitFile.ext.undot
        if ext != "" and ext.runeLen < total_width and not hentry().is_dir: # Adding separate extension cell.
            entry_id = entry_id.changeFileExt ""
            let left_col = total_width - ext.runeLen - 1
            host.write [entry_id.fit_left(left_col),"\a\x01", if entry_id.runeLen>left_col: "…" else: "\u2192"],
                hentry().coloring
            host.write [ext, "\a\x01║\n"], hentry().coloring
        else: host.write [entry_id.fit_left(total_width), "\a\x01", if entry_id.runeLen>total_width:"…" else:"║","\n"],
            hentry().coloring
        # 2nd footline rendering.
        let (stat_feed, clr) = if sel_stat.files > 0 or sel_stat.dirs > 0: (sel_stat, '\x07') else: (dir_stat, '\x05')
        let total_size = &" \a{clr}{($stat_feed.bytes).insertSep(' ', 3)} bytes in {stat_feed.files} files\a\x01 "
        host.write ["╚", total_size.center(total_width+4, '-').replace("-", "═"), "╝"]
        # Finalization.
        return self

    proc newDirViewer(term: TerminalEmu): DirViewer =
        DirViewer(host: term, visible: true).chdir(getAppFilename().root_dir)
# -------------------- #
when not defined(CommandLine):
    type CommandLine = ref object of Area
        host:   TerminalEmu
        log:    seq[string]
        shell:  Process
        origin: int
        fullscreen: bool
        dir_feed:   proc(): DirViewer
        prompt_cb:  proc(name: string)
        input, prompt: string
    const 
        max_log = 99999
        exit_hint = " ESC to return "

    # --Properties:
    template running(self: CommandLine): bool   = not self.shell.isNil and self.shell.running
    template exclusive(self: CommandLine): bool = self.running or self.fullscreen

    # --Methods goes here:
    proc scroll(self: CommandLine, shift: int) =
        origin = max(0, min(origin + shift, log.len - host.vlines))

    proc record(self: CommandLine, line: string) =
        log.add(line); scroll log.len

    proc shell(self: CommandLine, cmd: string = "") =
        let command = (if cmd != "": cmd else: input)
        record(&"\a\x03>>\a\x04{command}")
        shell = when defined(windows): 
              startProcess "cmd.exe",   dir_feed().path, ["/c", command], nil, {poStdErrToStdOut, poDaemon}
        else: startProcess "/bin/bash", dir_feed().path, [command, "|| exit"]
        input = ""

    proc request(self: CommandLine; hint, def_input: string; cb: proc(name: string)) =
        if prompt == "": prompt = hint; input = def_input; prompt_cb = cb

    proc request(self: CommandLine, hint: string, cb: proc(name: string)) =
        request hint, "", cb

    proc end_request(self: CommandLine) =
        prompt = ""; input = "";

    proc paste(self: CommandLine, text: string) =
        input &= text

    method update(self: CommandLine): Area {.discardable.} =
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
                if KEY_Backspace.IsKeyDown: (if norepeat(): input = input.runeSubstr(0, input.runeLen-1))
            if KEY_Enter.IsKeyPressed: # Input actualization.
                if prompt != "": prompt_cb(input); end_request(); abort() elif input != "": shell(); abort()
            elif KEY_Pause.IsKeyPressed and prompt != "": end_request(); abort() # Cancel request mode.
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
        if prompt != "": host.write [prompt, "\a\x06"], BLACK, ORANGE
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
        message: string
        answer:  int

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
        host.loc(0, self.ypos)        
        host.write [delim, "\n\a\x03", "[X]".center(host.hlines), "\n\a\x06", message.center(host.hlines), "\n\a\x03", 
            "<Yes/No>".center(host.hlines), "\n\a\x08 ", delim], MAROON, BLACK
        return self

    proc newAlert(term: TerminalEmu, creator: Area, msg: string): Alert =
        result = Alert(host: term, parent: creator, message: &"{msg} ?")
        try: result.host.loop_with result except: discard
# -------------------- #
when not defined(ProgressWatch):
    type ProgressWatch = ref object of Area
        host:  TerminalEmu
        start: Time
        cancelled, frameskip: bool
    const cancel_hint = " ESC to cancel │"

    # --Properties:
    template elapsed(self: ProgressWatch): Duration = getTime() - self.start

    # --Methods goes here:
    proc cancel(self: ProgressWatch) =
        cancelled = true; abort("Progress tracking was cancelled by user.")

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
        # Timeline render.
        let midline = host.vlines div 2 - 1
        for y in 0..host.vlines-2: 
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
                write [border, &"{time.inHours:02}:{time.inMinutes:02}:{time.inSeconds:02}", border.reversed], 
                    color, Black
                write decor.reversed, color, DarkBlue
        # Finalzation.
        host.loc(-(self.elapsed.inSeconds.int %% cancel_hint.runeLen), host.vlines - 1)
        host.write cancel_hint.repeat(host.hlines div cancel_hint.runeLen + 2), BLACK, SkyBlue
        return self

    proc newProgressWatch(term: TerminalEmu, creator: Area): ProgressWatch =
        ProgressWatch(host: term, parent: creator, start: getTime())
# -------------------- #
when not defined(FileViewer):
    type
        DataLine = tuple[origin: int, chars: seq[char]]
    type FileViewer = ref object of Area
        host: TerminalEmu
        src:  string
        feed: Stream
        cache: seq[DataLine]
        fullscreen: bool
        x, y, xoffset: int
        lense_id: string
        #lenses: Table[string, proc(fv: FileViewer): iterator:string]
    const 
        dl_cap = ['\n']
        border_shift = 2

    # --Properties:
    template width(self: FileViewer): int       = self.host.hlines div (2 - self.fullscreen.int)
    template hcap(self: FileViewer): int        = self.width - border_shift
    template vcap(self: FileViewer): int        = self.host.vlines - border_shift * (2 - self.fullscreen.int)
    template screencap(self: FileViewer): int   = self.hcap * self.vcap
    template feed_avail(self: FileViewer): bool = not feed.isNil
    template name(self: FileViewer): string     = self.src.extractFilename

    proc name_limited(self: FileViewer): string =
        if self.name.runeLen > self.hcap-2: &"…{self.name.runeSubStr(-self.hcap+4)}" else: self.name

    iterator cached_chars(self: FileViewer, start = 0): char =
        for line in cache:
            for chr in line.chars: yield chr

    # --Methods goes here:
    proc dir_checkout(self: FileViewer, path: string): string =
        # Init setup.
        var 
            subdirs, files, surf_size, hidden_dirs, hidden_files: BiggestInt
            ext_table: CountTable[string]
        # Analyzing loop.
        for record in walkDir(path): 
            if record.path.dirExists: # Subdir registration.
                subdirs.inc
                if record.path.isHidden: hidden_dirs.inc
            else:                     # File registration.
                files.inc; surf_size += record.path.getFileSize
                if record.path.isHidden: hidden_files.inc
                ext_table.inc(record.path.splitFile.ext)
        # Extensions breakdown.
        ext_table["<nil>"] = ext_table[""]
        ext_table.del("")
        ext_table.sort()
        let ext_sum = collect(newSeq): 
            for key,val in ext_table.pairs: (&"{key}: {val}").align_left(13,' '.Rune) & &"({(val/files.int*100):.2f}%)"
        # Finalization.
        result = [&"Sum:: {path}|", "=".repeat(path.runeLen + 6) & "/", "", 
            &"Surface data size: {($surf_size).insertSep(' ', 3)} bytes", 
            &"Sub-directories: {($subdirs).insertSep(' ', 3)} ({($hidden_dirs).insertSep(' ', 3)} hidden)",
            &"Files: {($files).insertSep(' ', 3)} ({($hidden_files).insertSep(' ', 3)} hidden)", ".".repeat(22),
            ext_sum.join("\n")
        ].join("\n")

    proc close(self: FileViewer) =
        if self.feed_avail:
            feed.close()
            feed = nil
        src = ""
        cache.setLen 0
        (x, y) = (0, 0)

    proc open(self: FileViewer, path: string, force = false) =
        if force or path != src: 
            close()
            feed = if path.dirExists: dir_checkout(path).newStringStream() else: path.newFileStream fmRead
        src = path.absolutePath

    proc read_data_line(self: FileViewer): DataLine =
        if self.feed_avail: # If reading is possible:
            let origin = feed.getPosition
            var buffer: seq[char]
            while not feed.atEnd:
                let chr = feed.readChar
                buffer.add chr
                if chr in dl_cap: break
            return (origin, buffer)      

    proc noise_lense(self: FileViewer): iterator:string =
        return iterator:string =        
            for y in 0..<self.vcap:
                let noise = collect(newSeq): (for x in 0..<self.hcap: "    01".sample)
                yield noise.join ""

    proc ascii_lense(self: FileViewer): iterator:string =
        var fragment = cache[y..^1]
        fragment.setLen self.vcap
        return iterator:string =
            for data in fragment: yield data.chars[0..<min(self.hcap, data.chars.len)].join ""

    proc hex_lense(self: FileViewer): iterator:string =
        let per_line = self.hcap div 3 - (self.hcap div 9)
        var 
            accum: seq[string]
            recap: seq[char]
            lines_left = self.vcap
        return iterator:string =
            for chr in self.cached_chars: 
                accum.add &"{chr.int32:02X}" & (if accum.len %% 5 == 4: "\xB3" else: " ")
                recap.add chr
                if accum.len >= per_line:
                    yield accum.join("") & recap.join ""
                    lines_left.dec
                    if lines_left == 0: return
                    accum.setLen 0
                    recap.setLen 0
            for exceed in 1..lines_left: yield ""

    const lenses = {"ASCII": ascii_lense, "HEX": hex_lense, "ERROR": noise_lense}.toTable
    method update(self: FileViewer): Area {.discardable.} =
        lense_id = if self.feed_avail: # Data pumping.
            while cache.len < y + self.vcap:
               cache.add read_data_line()
            if '\0' in cache[0].chars: "HEX" else: "ASCII"
        else: "ERROR" # Noise garden
        return self

    method render(self: FileViewer): Area {.discardable.} =
        # Init setup.        
        host.margin = xoffset
        # Header render.
        with host:
            loc(xoffset, 0)
            write "╒", border_color, DARKBLUE.Fade 0.7
            write @[" ", lense_id, " "], if self.feed_avail: SKYBLUE else: RED, DARKGRAY
            write @["═".repeat(self.hcap-lense_id.runeLen-2), "╕\n"], border_color, DARKBLUE.Fade 0.7
        let 
            lborder = if xoffset > 0: "┤" else: "│"
            rborder = (if xoffset < host.hlines - self.width: "├" else: "│") & "\n"
        # Rendering loop.
        let render_list = lenses[lense_id](self)
        for line in render_list(): with host:
            write lborder
            write line.convert(srcEncoding = cmd_cp).fit_left(self.hcap), RayWhite, raw=true
            write rborder, border_color
        # Footing render.
        host.write ["╘", "═".repeat(self.hcap), "╛"]
        host.loc((self.hcap - self.name_limited.runeLen) div 2 + xoffset, host.vpos())
        host.write [" ", self.name_limited, " "], (if self.feed_avail: Orange else: Maroon), DARKGRAY
        # Finalization.
        return self

    proc newFileViewer(term: TerminalEmu, xoffset: int, src = ""): FileViewer =
        result = FileViewer(host: term, xoffset: xoffset)
        #result.lenses = {"ASCII": ascii_lense, "HEX": hex_lense, "ERROR": noise_lense}.toTable
        if src != "": result.open src

    proc destroy(self: FileViewer): FileViewer {.discardable.} =
        close()
        return nil
# -------------------- #
when not defined(MultiViewer):
    type MultiViewer = ref object of Area
        host:    TerminalEmu
        viewers: seq[DirViewer]
        cmdline: CommandLine
        error:   tuple[msg: string, time: Time]
        dirty:   bool
        inspector: FileViewer
        watcher: ProgressWatch
        current, f_key: int
    const hint_width  = 6

    # --Properties:
    template active(self: MultiViewer): DirViewer       = self.viewers[self.current]
    template next_index(self: MultiViewer): int         = (self.current+1) %% self.viewers.len
    template next_viewer(self: MultiViewer): DirViewer  = self.viewers[self.next_index]
    template next_path(self: MultiViewer): string       = self.next_viewer.path
    template inspecting(self: MultiViewer): bool        = not inspector.isNil
    template previewing(self: MultiViewer): bool        = self.inspecting and not self.inspector.fullscreen
    template hint_prefix(self: MultiViewer): string     = " ".repeat(host.hlines div 11 - hint_width - 1) & "F"
    template hint_cellwidth(self: MultiViewer): int     = hint_width + self.hint_prefix.runeLen + 1
    template hint_margin(self: MultiViewer): int        = (host.hlines - (self.hint_cellwidth.float * 10.5).int) div 2

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

    proc reset_watcher(self: MultiViewer) =
        watcher = newProgressWatch(host, self)

    proc wait_task(self: MultiViewer, task: FlowVar[ref Exception]) =
        while not task.isReady: host.update watcher
        let error = ^task
        if not error.isNil: raise error

    proc warn(self: MultiViewer, message: string): int =
        if not watcher.isNil: watcher.frameskip = true
        return newAlert(host, self, message).answer

    proc navigate(self: MultiViewer, path: string) =
        discard self.active.chdir path

    proc transfer(self: MultiViewer; src, dest: string; dir_proc, file_proc: proc(src, dest: string)): bool =
        # Service proc.
        proc transferrer(src, dest: string, dir_proc, file_proc: proc(src, dest: string)): ref Exception =
            try: 
                if src.dirExists: src.dir_proc(dest) else: src.file_proc(dest)
            except: return getCurrentException()
        # Actual transfer.
        if not (dest.fileExists or dest.dirExists) or # Checking if dest already exists.
            warn("Are you sure want to overwrite " & dest.extractFilename.quoteShell) > 0:
                let is_dir = src.dirExists
                wait_task spawn src.transferrer(dest, dir_proc, file_proc)
                return true

    template sel_transfer(self: MultiViewer; dir_proc, file_proc: untyped; destructive = false; ren_pattern = "") =
        # Init setup.
        var 
            last_transferred: string
            sel_indexes = self.active.selected_indexes # For selection removal.
        reset_watcher()
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
                let dest = self.next_path / entry.name.wildcard_replace(if ren_pattern != "": ren_pattern else: "*.*")
                if src != self.next_path and transfer(src, dest, dir_proc, file_proc): # Setting 'dirty' flags.
                    self.next_viewer.dirty = true
                    if destructive: self.active.dirty = true
                    last_transferred = dest.extractFilename
            if sel_indexes.len > 0 and (entry.name == direxit.name or not destructive): # Selection removal.
                self.active.switch_selection sel_indexes[0], 0
                sel_indexes.delete 0

    proc uninspect(self: MultiViewer) =
        if self.inspecting: inspector = inspector.destroy()

    proc inspect(self: MultiViewer) =
        let 
            target = self.active.hentry
            path = self.active.path / self.active.hentry.name
        if self.inspecting: inspector.open path                               # Reusing existing fileviewer
        else: inspector = newFileViewer(host, self.next_viewer.xoffset, path) # Opening new fileviewer

    proc copy(self: MultiViewer) =
        sel_transfer(self, copyDir, copyFile)

    proc move(self: MultiViewer, ren_pattern = "") =
        let src_viewer = self.active
        sel_transfer(self, moveDir, moveFile, true, ren_pattern)
        src_viewer.refresh()

    proc new_dir(self: MultiViewer, name: string) =
        self.active.path.joinPath(name).createDir
        self.active.refresh.scroll_to_name name
        sync self.active

    proc delete(self: MultiViewer) =
        # Service proc.
        proc deleter(victim: string, is_dir: bool): ref Exception =
            try: 
                if is_dir: victim.removeDir() else: victim.removeFile()
            except: return getCurrentException()
        reset_watcher()
        # Deffered finalization.
        defer:
            if self.active.dirty:
                self.active.refresh()
                sync(self.active)
        # Actual deletion.
        for idx, entry in self.active.selected_entries:
            if entry.name != direxit.name: # No deletion for ..
                let victim = self.active.path / entry.name
                wait_task spawn victim.deleter(entry.is_dir)
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
            if transfer(src, self.active.path / src.extractFilename, copyDir, copyFile): 
                last_transferred = src.extractFilename
                self.active.dirty = true

    proc switch_inspector(self: MultiViewer) =
        if self.inspecting: uninspect() else: inspect()

    proc manage_selection(self: MultiViewer, pattern = "", new_state = true) =
        let mask = if pattern != "": pattern else: "*.*"
        for idx, entry in self.active.list:
            if entry.name.wildcard_match(mask): self.active.switch_selection(idx, new_state.int)

    proc request_navigation(self: MultiViewer) =
        cmdline.request &"Input path to browse \a\x03<{drive_list().join(\"|\")}>", (path:string) => self.navigate path

    proc request_moving(self: MultiViewer) =
        if self.active.selection_valid:
            cmdline.request "Input renaming pattern \a\x03<*.*>", (pattern: string) => self.move pattern

    proc request_new_dir(self: MultiViewer) =
        cmdline.request "Input name for new directory", (name: string) => self.new_dir (name)

    proc request_deletion(self: MultiViewer) =
        if self.active.selection_valid and 
            warn(&"Are you sure want to delete {self.active.selected_entries.len} entris") >= 1: delete()

    proc request_sel_management(self: MultiViewer, new_state = true) =
        cmdline.request "Input " & (if new_state: "" else: "un") & "selection pattern \a\x03<*.*>", (pattern:string) =>
            self.manage_selection(pattern, new_state)

    proc pick_viewer(self: MultiViewer, x = GetMouseX(), y = GetMouseY()): int =
        if y < host.vlines - service_height:
            for idx, view in viewers: 
                if x >= view.xoffset and x <= view.xoffset+self.active.viewer_width: return idx
        return -1

    method update(self: MultiViewer): Area {.discardable.} =
        f_key = 0 # F-key emulator.
        try:
            cmdline.update()
            if not cmdline.exclusive:
                # Mouse controls.
                let
                    (x, y) = host.pick()
                    picked_view_idx = pick_viewer(x, y)
                if MOUSE_Left_Button.IsMouseButtonDown or MOUSE_Right_Button.IsMouseButtonDown: # DirViewers picking.
                    if picked_view_idx >= 0: select picked_view_idx
                elif y == host.vlines-1 and MOUSE_Left_Button.IsMouseButtonReleased: # Command buttons picking.
                    let index = (x-(self.hint_prefix.runeLen + self.hint_margin - 1)) / self.hint_cellwidth + 1
                    if index-index.int.float < (1.1-0.1*(self.hint_prefix.runeLen).float): 
                        f_key = index.int # If click in button bounds - activating.
                # Drag/drop handling.
                let droplist = check_droplist()                
                if droplist.len > 0:
                    if picked_view_idx >= 0:
                        select picked_view_idx
                        receive droplist
                    elif y == host.vlines - service_height: cmdline.paste(droplist[0])
                # Keyboard controls.
                if f_key==1 or KEY_F1.IsKeyPressed:  (cmdline.fullscreen = true; for hint in help:cmdline.record(hint))
                elif f_key==3 or KEY_F3.IsKeyPressed:   switch_inspector()
                elif f_key==5 or KEY_F5.IsKeyPressed:   copy()
                elif f_key==6 or KEY_F6.IsKeyPressed:   request_moving()
                elif f_key==7 or KEY_F7.IsKeyPressed:   request_new_dir()
                elif f_key==8 or KEY_F8.IsKeyPressed:   request_deletion()
                elif f_key==10 or KEY_F10.IsKeyPressed: quit()
                elif KEY_Home.IsKeyPressed:             request_navigation()
                elif KEY_Tab.IsKeyPressed:              select(self.next_index)
                elif KEY_End.IsKeyPressed:              cmdline.paste(self.active.hpath)
                elif KEY_KP_Add.IsKeyPressed:           request_sel_management()
                elif KEY_KP_Subtract.IsKeyPressed:      request_sel_management(false)
                # File viewer update.
                if self.previewing:
                    inspector.xoffset = self.next_viewer.xoffset
                    if self.active.hl_changed: inspect()
                if self.inspecting: inspector.update()
                # Viewer update.
                self.active.update()
                if dirty:
                    dirty = false
                    for viewer in viewers: viewer.refresh()
            elif cmdline.running: dirty = true # To update viewers later after cmd execution.
            # Finalization.
            if (getTime() - error.time).inSeconds > 2: error.msg = ""
        except: # Error message
            error = (msg: getCurrentExceptionMsg().splitLines[0], time: getTime())
            for viewer in viewers: (if viewer.dirty: viewer.refresh().scroll_to(viewer.hline))
        return self

    method render(self: MultiViewer): Area {.discardable.} =
        # Commandline/viewers render.
        if not cmdline.exclusive:
            let displaced = if self.previewing: self.next_viewer() else: nil
            var offset = 0
            for view in viewers: 
                view.xoffset = offset # Offset lineup.
                (if view == displaced: inspector else: view).render()
                offset += view.viewer_width # Caluclating next post after adjustment.
        cmdline.render()
        if cmdline.exclusive: return
        # Hints.
        if error.msg != "": # Error message.
            host.write &">>{error.msg.fit(host.hlines+1)}", BLACK, MAROON
        else: # Hot keys.
            var idx: int
            host.loc(self.hint_margin, host.vpos)
            for hint in "Help|Menu|View|Edit|Copy|RenMov|MkDir|Delete|PullDn|Quit".split("|"):
                idx.inc()
                host.write [self.hint_prefix, $idx], 
                    if f_key == idx or (KEY_F1+idx-1).KeyboardKey.IsKeyDown: Maroon else: hl_color, BLACK
                host.write hint.center(hint_width), BLACK, 
                    if idx==3 and self.previewing: Orange elif idx in [1, 3, 5, 6, 7, 8, 10]: SKYBLUE else: GRAY
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
        win = newTerminalEmu("Midday Commander", "res/midday.png", 110, 33,
            BLACK, border_color, tips_color, DARKGRAY, LIME, LIGHTGRAY, ORANGE, selected_color, MAROON)
        supervisor = newMultiViewer(win, newDirViewer(win), newDirViewer(win))
    win.loop_with supervisor