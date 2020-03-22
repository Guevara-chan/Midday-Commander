import os, osproc, strutils, algorithm, sequtils, times, streams, sugar, strformat, threadpool, raylib
from unicode import Rune, runes, align, alignLeft, runeSubStr, `==`, `$`, runeLen
{.this: self.}

#.{ [Classes]
when not defined(Meta):
    # --Service classes:
    type Area {.inheritable.} = ref object
        repeater, clicker: Time
    method update(self: Area): Area {.discardable base.} = discard
    method render(self: Area): Area {.discardable base.} = discard
    proc norepeat(self: Area): bool =
        if (getTime() - repeater).inMilliseconds > 110: repeater = getTime(); return true

    # --Service procs:
    proc fit(txt: string, size: int, filler = ' '): string = txt.align(size, filler.Rune).runeSubStr 0, size
    proc fit_left(txt: string, size: int, filler = ' '): string = txt.alignLeft(size, filler.Rune).runeSubStr 0, size
    proc root_dir(path: string): string =
        var child = path
        while true: (if child.parentDir == "": return child else: child = child.parentDir)

    # --Data
    const help = @["\a\x03>\a\x01.",
    "\a\x03>\a\x06Midday Commander\a\x05 retrofuturistic file manager v0.01",
    "\a\x03>\a\x05Developed in 2*20 by \a\x04Victoria A. Guevara",
    "===================================================================",
    "\a\x02ESC:\a\x01    switch between dir view & console view",
    "\a\x02F1:\a\x01     display this cheatsheet (\a\x02ESC\a\x01 to return)",
    "\a\x02F5:\a\x01     copy selected entri(s)",
    "\a\x02F6:\a\x01     move selected entri(s)",
    "\a\x02F7:\a\x01     request directory creation",
    "\a\x02F8:\a\x01     delete selected entri(s)",
    "\a\x02Insert:\a\x01 (un)select hilited entry",
    "\a\x02Home:\a\x01   request new path to browse",
    "\a\x02Left:\a\x01   move to begin of listing",
    "\a\x02Right:\a\x01  move to end of listing",
    "\a\x02Up:\a\x01     move selection/view 1 line up",
    "\a\x02Down:\a\x01   move selection/view 1 line down ",
    "\a\x02PgUp:\a\x01   move selection/view 1 page up",
    "\a\x02PgDown:\a\x01 move selection/view 1 page down",
    "\a\x02Pause:\a\x01  cancel query OR cancel command execution",
    "\a\x02Enter:\a\x01  inspect hilited dir OR run hilited file OR execute command ",
    "==================================================================="]
# -------------------- #
when not defined(TerminalEmu):
    type TerminalEmu = ref object
        font:       Font
        cur, cell:  Vector2
        fg, bg:     Color
        palette:    seq[Color]
        margin:     int

    # --Properties.
    proc hlines(self: TerminalEmu): int = GetScreenWidth() div cell.x.int
    proc vlines(self: TerminalEmu): int = GetScreenHeight() div cell.y.int
    proc hpos(self: TerminalEmu): int = (self.cur.x / self.cell.x).int
    proc vpos(self: TerminalEmu): int = (self.cur.y / self.cell.y).int

    # --Methods goes here:
    proc loc_precise(self: TerminalEmu, x = 0, y = 0) =
        cur.x = x.float; cur.y = y.float

    proc loc(self: TerminalEmu, x = 0, y = 0) =
        loc_precise((x.float * cell.x).int, (y.float * cell.y).int)

    proc write(self: TerminalEmu, txt: string; fg_init = Color(), bg_init = Color()) =
        # Init setup.
        var ctrl: bool
        if fg_init.a > 0.uint8: fg = fg_init
        if bg_init.a > 0.uint8: bg = bg_init
        # Buffering.
        var chunks: seq[string]
        var buffer: string
        for chr in txt.runes:
            if chr.int > 31: buffer &= $chr
            else: 
                if buffer != "": chunks.add buffer
                buffer = ""
                chunks.add $chr
        if buffer != "": chunks.add buffer
        # Char render loop.
        for chunk in chunks:
            if ctrl:                          # Control arg.
                fg = palette[chunk[0].int]
                ctrl = false
            elif chunk[0] == '\a': ctrl = true   # Control character.
            elif chunk[0] != '\n':
                let width = cell.x * chunk.runeLen.float
                cur.DrawRectangleV(Vector2(x: width, y: cell.y), bg)
                if chunk != " ": font.DrawTextEx(chunk, cur, font.baseSize.float32, 0, fg)
                cur.x += width
            else: loc_precise(margin * cell.x.int, (cur.y + cell.y).int) # new line.

    proc write(self: TerminalEmu, chunks: open_array[string], fg_init = Color(), bg_init = Color()) =
        write "", fg_init, bg_init
        for chunk in chunks: write chunk

    proc pick(self: TerminalEmu; x, y: int): auto =
        (x div cell.x.int, y div cell.y.int)

    proc adjust(self: TerminalEmu) =
        SetWindowSize self.hlines * cell.x.int, self.vlines * cell.y.int

    proc update(self: TerminalEmu, areas: varargs[Area]) =
        if IsWindowResized(): self.adjust()
        loc_precise(); (fg, bg) = (WHITE, BLACK); margin = 0
        BeginDrawing()
        ClearBackground BLACK
        for area in areas: area.update().render()
        #DrawFPS(0,0)
        EndDrawing()

    proc newTerminalEmu(colors: varargs[Color]): TerminalEmu =
        # Init setup.
        InitWindow(880, 400, "Midday Commander")
        60.SetTargetFPS
        0.SetExitKey
        getAppDir().setCurrentDir
        # Splash screen.
        BeginDrawing()
        ClearBackground DARKBLUE
        let 
            text = "...LOADING..."
            sizing = MeasureTextEx(GetFontDefault(), text, 25, 0)
        DrawText(text, (GetScreenWidth() - sizing.x.int) div 2, (GetScreenHeight() - sizing.y.int) div 2, 25, RAYWHITE)
        EndDrawing()
        SetWindowIcon(LoadImage("res/midday.png"))
        # Font setup.
        var glyphs: array[486, int]
        for i in 0..glyphs.high: glyphs[i] = i
        let extra_chars = 
            @[0x2534,0x2551,0x2502,0x255F,0x2500,0x2562,0x2550,0x255A,0x255D,0x2554,0x2557,0x2026,0xB7,0xB0,0xA0] &
                lc[x | (x <- 0x410..0x451), int]
        glyphs[0x80..0x80+extra_chars.len-1] = extra_chars
        # Terminal object.
        result = TerminalEmu(font:"res/TerminalVector.ttf".LoadFontEx(12,glyphs.addr,glyphs.len), palette:colors.toSeq)
        result.cell = result.font.MeasureTextEx("0", result.font.baseSize.float32, 0)
        # Finalization.
        result.adjust()
# -------------------- #
when not defined(DirEntry):
    type DirEntry = object
        name: string
        kind: PathComponent
        size: BiggestInt
        mtime: Time
        selected: bool
    const direxit = DirEntry(name: "..", kind: pcDir)

    # --Properties:
    proc executable(self: DirEntry): bool =
        let ext = name.splitFile.ext
        if ext != "" and ext.runeSubstr(1) in ExeExts: return true
    proc coloring(self: DirEntry): Color =
        case kind:
            of pcDir, pcLinkToDir: WHITE
            of pcFile, pcLinkToFile:
                if self.executable: GREEN else: BEIGE
    proc time_stamp(self: DirEntry): string =
        if name != "": 
            mtime.format(if mtime.local.year == now().year: "dd MMM hh:mm" else: "dd MMM  yyyy")
        else: ""

    # --Methods goes here:
    template is_dir(self: DirEntry): bool = self.kind in [pcDir, pcLinkToDir]
    proc `$`(self: DirEntry): string = (if self.is_dir: "/" elif self.executable: "*" else: " ") & name
    template get_size(self: DirEntry): string =
        if self.name == direxit.name: "\xB7\x10UP--DIR\x11\xB7"
        elif self.is_dir:             "\xB7\x10SUB-DIR\x11\xB7"
        elif self.name == "":         ""
        elif self.size > 99999999999: $(self.size div 1024) & "K"
        else: $self.size
    template newDirEntry(src: tuple[kind: PathComponent, path: string]): DirEntry =
        DirEntry(name: src.path.extractFilename, kind: src.kind, size: src.path.getFileSize, 
            mtime: src.path.getLastModificationTime)
# -------------------- #
when not defined(DirViewer):
    type DirViewer = ref object of Area
        host: TerminalEmu
        path: string
        list: seq[DirEntry]
        dir_size: BiggestInt
        dirty, active, visible: bool
        hline, origin, xoffset, file_count: int
    const
        hdr_height      = 2
        foot_height     = 3
        service_height  = 2
        border_color    = GRAY
        tips_color      = GOLD
        hl_color        = SKYBLUE
        selected_color  = YELLOW
        name_col        = 28
        size_col        = "\xB7\x10UP--DIR\x11\xB7".len
        date_col        = "Modify time:".len
        total_width     = name_col + size_col + date_col + 2
        viewer_width    = total_width + 2

    # --Properties
    proc capacity(self: DirViewer): int = host.vlines - hdr_height - foot_height - service_height
    proc hindex(self: DirViewer): int   = hline - origin
    proc hentry(self: DirViewer): DirEntry = list[hline]
    proc selected_entries(self: DirViewer): seq[DirEntry] =
        for idx, entry in list: (if entry.selected: result.add entry)
        if result.len == 0: result.add self.hentry
    proc selected_indexes(self: DirViewer): seq[int] =
        for idx, entry in list: (if entry.selected: result.add idx)
    proc path_limited(self: DirViewer): string = 
        if path.runeLen > total_width-2: &"…{path.runeSubStr(-total_width+4)}"
        else: path

    # --Methods goes here:
    proc scroll_to(self: DirViewer, pos = 0): auto {.discardable.} =
        hline = max(0, min(pos, list.len - 1))
        origin = if hline >= origin + self.capacity: hline - self.capacity + 1
        else: min(origin, hline)
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
        dir_size = 0; file_count = 0; list.setLen(0)
        for record in walkDir(path): 
            let entry = newDirEntry record
            if not entry.is_dir: dir_size += entry.size; file_count.inc
            list.add entry
        if not path.isRootDir: list.insert(direxit, 0) # .. entry.
        dirty = false
        return organize().scroll_to(last_hl)

    proc chdir(self: DirViewer, newdir: string): auto {.discardable.} =
        let prev_dir = path.extractFilename
        ((if path.isAbsolute: newdir else: path.joinPath newdir).normalizedPath & "\\").setCurrentDir
        path = getCurrentDir().normalizedPath
        scroll_to(0).refresh()
        if newdir == direxit.name: scroll_to_name(prev_dir) # Backtrace.
        return self

    proc exec(self: DirViewer, fname: string) =
        discard execShellCmd path.joinPath(self.hentry.name).quoteShell

    proc invoke(self: DirViewer, entry: DirEntry) =
        if entry.is_dir: chdir(entry.name) else: spawn exec(entry.name)

    proc switch_selection(self: DirViewer, idx: int) =
        var copy = list[idx]
        copy.selected = not copy.selected
        list[idx] = copy

    method update(self: DirViewer): Area {.discardable.} =
        # Mouse controls.
        if not active: return self
        scroll -GetMouseWheelMove()
        let
            (x, y) = host.pick(GetMouseX(), GetMouseY())
            pickline = y - hdr_height
        if y < hdr_height or y >= host.vlines - service_height - foot_height: discard # Not service zone.
        elif MOUSE_Left_Button.IsMouseButtonReleased:
            if (getTime()-clicker).inMilliseconds<=300: clicker = Time(); (if pickline == self.hindex: invoke hentry())
            else: clicker = getTime()
        elif MOUSE_Right_Button.IsMouseButtonReleased: switch_selection pickline
        elif MOUSE_Left_Button.IsMouseButtonDown: (if pickline != self.hindex: scroll_to pickline + origin)
        # Kbd controls.
        if KEY_UP.IsKeyDown:         (if norepeat(): scroll -1)
        elif KEY_Down.IsKeyDown:     (if norepeat(): scroll 1)
        elif KEY_Page_Up.IsKeyDown:  (if norepeat(): scroll -self.capacity)
        elif KEY_Page_Down.IsKeyDown:(if norepeat(): scroll self.capacity)
        elif KEY_Left.IsKeyPressed:  scroll_to 0
        elif KEY_Right.IsKeyPressed: scroll_to list.len
        elif KEY_Enter.IsKeyPressed: invoke self.hentry
        elif KEY_Insert.IsKeyPressed: switch_selection(hline); scroll 1
        # Finalization.
        return self

    method render(self: DirViewer): Area {.discardable.} =
        # Init setup.
        if not visible: return self
        var render_list: seq[DirEntry] = list[origin..^1]
        render_list.setLen(self.capacity)
        host.margin = xoffset
        host.loc(xoffset, 0)
        # Header rendering.
        host.write @["╔", "═".repeat(total_width), "╗"], border_color, DARKBLUE
        host.loc((total_width - self.path_limited.runeLen) div 2 + xoffset, host.vpos())
        host.write @[" ", self.path_limited, " \n"], (if active: hl_color else: direxit.coloring), DARKGRAY
        host.write @["║\a\x02", "Name".center(name_col), "\a\x01│\a\x02", "Size".center(size_col), "\a\x01│\a\x02",
            "Modify time".center(date_col), "\a\x01║\n"], border_color, DARKBLUE
        # List rendering.
        for idx, entry in render_list:
            let text_color = if entry.selected: selected_color else: entry.coloring
            host.write (if entry.selected: "╟" else : "║"), border_color, DARKBLUE
            host.write @[($entry).fit_left(name_col), "\a\x01│"], text_color,
                if active and idx == self.hindex: hl_color else: DARKBLUE # Highlight line.
            host.write @[entry.get_size.fit(size_col), "\a\x01│"], text_color
            host.write entry.time_stamp.fit_left(date_col), text_color
            host.write @["\a\x01", (if entry.selected: "╢" else : "║"), "\n"], text_color, DARKBLUE
        # Footing rendering.
        host.write @["║", "─".repeat(name_col), "┴", "─".repeat(size_col), "┴", "─".repeat(date_col), "║\n║"], 
            border_color, DARKBLUE
        host.write @[($hentry()).fit_left(total_width), "\a\x01║\n"], hentry().coloring
        let total_size = &" \a\x05{($dir_size).insertSep(' ', 3)} bytes in {file_count} files\a\x01 "
        host.write ["╚", total_size.center(total_width+4, '-').replace("-", "═"), "╝"]
        # Finalization.
        return self

    proc newDirViewer(term: TerminalEmu, xoffset = 0): DirViewer =
        DirViewer(host: term, xoffset: xoffset, visible: true).chdir(getAppFilename().root_dir)
# -------------------- #
when not defined(CommandLine):
    type CommandLine = ref object of Area
        host:   TerminalEmu
        log:    seq[string]
        shell:  Process
        origin: int
        dir_feed:   proc(): DirViewer
        prompt_cb:  proc(name: string)
        fullscreen: bool
        input, prompt: string
    const max_log = 99999
    const exit_hint = " ESC to return "

    # --Properties:
    proc running(self: CommandLine): bool = (if not shell.isNil and shell.running: return true)
    proc exclusive(self: CommandLine): bool = self.running or fullscreen

    # --Methods goes here:
    proc scroll(self: CommandLine, shift: int) =
        origin = max(0, min(origin + shift, log.len - host.vlines))

    proc record(self: CommandLine, line: string) =
        log.add(line); scroll log.len

    proc shell(self: CommandLine, cmd: string = "") =
        let command = (if cmd != "": cmd else: input)
        record(&"\a\x03>>\a\x04{command}")
        shell = startProcess("cmd.exe", dir_feed().path, @["/c", command])
        input = ""

    proc request(self: CommandLine, hint: string, cb: proc(name: string)) =
        if prompt == "": prompt = hint; input = ""; prompt_cb = cb

    proc end_request(self: CommandLine) =
        prompt = ""; input = ""

    method update(self: CommandLine): Area {.discardable.} =
        # Service controls.
        let (x, y) = host.pick(GetMouseX(), GetMouseY())
        if y == 0 and x >= host.hlines() - exit_hint.len and MOUSE_Left_Button.IsMouseButtonReleased and fullscreen:
            fullscreen = false
        if KEY_Escape.IsKeyPressed: fullscreen = not fullscreen
        if self.exclusive: # Scrolling controls.
            if KEY_PageUp.IsKeyDown:      (if norepeat(): scroll -host.vlines)
            elif KEY_PageDown.IsKeyDown:  (if norepeat(): scroll +host.vlines)
            elif KEY_Up.IsKeyDown:        (if norepeat(): scroll -1)
            elif KEY_Down.IsKeyDown:      (if norepeat(): scroll 1)
            elif KEY_Pause.IsKeyPressed:  (if self.running: shell.kill)
        else: # Input controls.
            if input != "":
                if KEY_Backspace.IsKeyDown: (if norepeat(): input = input.runeSubstr(0, input.len-1))
                elif KEY_Enter.IsKeyPressed: # Input actualization.
                    if prompt != "": prompt_cb(input); end_request(); raise newException(OSError, "") # Async query.
                    else: shell()
            if KEY_Pause.IsKeyPressed and prompt != "": end_request() # Cancel request mode.
            let key = GetKeyPressed()
            if key > 0: input &= $(key.Rune)
        # Output parsing.
        if not shell.isNil and shell.hasData: 
            record(shell.outputStream.readLine())
            if log.len > max_log: log = log[log.len-max_log..^1]; scroll(log.len) # Memory saving.
        return self

    method render(self: CommandLine): Area {.discardable.} =
        # Output log.
        if self.exclusive: 
            for line in log[origin..<min(log.len, origin+host.hlines)]: host.write @[line, $'\n'], GRAY
            if fullscreen:
                host.loc(host.hlines - exit_hint.len, 0)
                host.write exit_hint, BLACK, DARKGRAY
            return
        # Commandline.
        host.margin = 0
        host.write "\n"
        host.margin = -2
        if prompt != "": host.write @[prompt, "\a\x06"], BLACK, ORANGE
        else: host.write @[dir_feed().path_limited, "\a\x03"], RAYWHITE, BLACK
        host.write @[if prompt.len > 0: "\x10" else: ">", "\a\x04 ", input, 
            (if getTime().toUnix %% 2 == 1: "_" else: ""), "\n"], Color(), BLACK
        # Finalization.
        return self

    proc newCommandLine(term: TerminalEmu, dir_feeder: proc(): DirViewer): CommandLine =
        result = CommandLine(host: term, dir_feed: dir_feeder)
# -------------------- #
when not defined(FileViewer):
    discard "TODO: file viewer"
    discard "Probably can be extended to editor later"
# -------------------- #
when not defined(MultiViewer):
    type MultiViewer = ref object of Area
        host:    TerminalEmu
        viewers: seq[DirViewer]
        cmdline: CommandLine
        error:   tuple[msg: string, time: Time]
        dirty:   bool
        current, f_key: int

    # --Properties:
    proc active(self: MultiViewer): DirViewer = viewers[current]
    proc next_index(self: MultiViewer): int = (current+1) %% viewers.len
    proc next_viewer(self: MultiViewer): DirViewer = viewers[self.next_index]
    proc next_path(self: MultiViewer): string = self.next_viewer.path

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

    template transfer(self: MultiViewer, dir_proc: untyped, file_proc: untyped) =
        var 
            last_transferred: string
            sel_indexes = self.active.selected_indexes # For selection removal.
        for entry in self.active.selected_entries:
            let src = self.active.path.joinPath entry.name
            let dest = self.next_path.joinPath entry.name
            if entry.is_dir: src.dir_proc(dest) else: src.file_proc(dest)
            self.next_viewer.dirty = true
            last_transferred = entry.name
            if sel_indexes.len > 0: # Selection removal.
                self.active.switch_selection sel_indexes[0]
                sel_indexes.delete 0
        self.next_viewer.refresh().scroll_to_name(last_transferred)
        select self.next_index

    proc copy(self: MultiViewer) =
        transfer(self, copyDir, copyFile)

    proc move(self: MultiViewer) =
        let src_viewer = self.active
        transfer(self, moveDir, moveFile)
        src_viewer.refresh()

    proc request_new_dir(self: MultiViewer) =
        cmdline.request "Input name for new directory", (name: string) => 
            (self.active.path.joinPath(name).createDir; self.active.refresh.scroll_to_name name; self.sync self.active)

    proc request_disk(self: MultiViewer) =
        cmdline.request "Input path to browse", (path: string) => (discard self.active.chdir path)

    proc delete(self: MultiViewer) =
        for idx, entry in self.active.selected_entries:
            let victim = self.active.path.joinPath entry.name
            if entry.is_dir: victim.removeDir() else: victim.removeFile()
            self.active.dirty = true
        self.active.refresh()
        sync(self.active)

    method update(self: MultiViewer): Area {.discardable.} =
        f_key = 0 # F-key emulator.
        try:
            cmdline.update()
            if not cmdline.exclusive:
                # Mouse controls.
                let (x, y) = host.pick(GetMouseX(), GetMouseY())
                if y < host.vlines - service_height: # DirViewers picking.
                    if MOUSE_Left_Button.IsMouseButtonDown or MOUSE_Right_Button.IsMouseButtonDown:
                        for idx, view in viewers: (if x >= view.xoffset and x <= view.xoffset+viewer_width: select idx)
                elif y == host.vlines-1 and MOUSE_Left_Button.IsMouseButtonReleased: # Command buttons picking.
                    let index = (x-1) / 11 + 1
                    if index-index.int.float < 0.7: f_key = index.int # If click in button bounds - activating.
                # Keyboard controls.
                if f_key==1 or KEY_F1.IsKeyPressed:  (cmdline.fullscreen = true; for hint in help: cmdline.record(hint))
                elif f_key==5 or KEY_F5.IsKeyPressed: copy()
                elif f_key==6 or KEY_F6.IsKeyPressed: move()
                elif f_key==7 or KEY_F7.IsKeyPressed: request_new_dir()
                elif f_key==8 or KEY_F8.IsKeyPressed: delete()
                elif f_key==10 or KEY_F10.IsKeyPressed:quit()
                elif KEY_Home.IsKeyPressed: request_disk()
                elif KEY_Tab.IsKeyPressed:  select(self.next_index)
                # Viewer update.
                self.active.update()
                if dirty:
                    dirty = false
                    for viewer in viewers: viewer.refresh()
            elif cmdline.running: dirty = true # To update viewers later after cmd execution.
            # Finalization.
            if (getTime() - error.time).inSeconds > 2: error.msg = ""
        except: # Error message
            error = (msg: getCurrentExceptionMsg().split('\n')[0], time: getTime())
            for viewer in viewers: (if viewer.dirty: viewer.refresh().scroll_to(viewer.hline))
        return self

    method render(self: MultiViewer): Area {.discardable.} =
        # Commandlione/viewers render.
        if not cmdline.exclusive: (for view in viewers: view.render())
        cmdline.render()
        if cmdline.exclusive: return
        # Hints.
        if error.msg != "": # Error message.
            host.write &">>{error.msg.fit(host.hlines+1)}", BLACK, MAROON
        else: # Hot keys.
            var idx: int
            for hint in "Help|Menu|View|Edit|Copy|RenMov|MkDir|Delete|PullDn|Quit".split("|"):
                idx.inc()
                host.write @["   F", $idx], 
                    if f_key == idx or (KEY_F1+idx-1).KeyboardKey.IsKeyDown: Maroon else: hl_color, BLACK
                host.write hint.center(6), BLACK, if idx in [1, 5, 6, 7, 8, 10]: SKYBLUE else: GRAY
        # Finalization.
        return self

    proc newMultiViewer(term: TerminalEmu, viewers: varargs[DirViewer]): MultiViewer =
        result = MultiViewer(host: term, viewers: viewers.toSeq)
        let base = result
        result.cmdline = newCommandLine(term, () => base.active)
        result.select()
#.}

# ==Main code==
let 
    win = newTerminalEmu(BLACK, border_color, tips_color, DARKGRAY, LIME, LIGHTGRAY, ORANGE)
    supervisor = newMultiViewer(win, newDirViewer(win), newDirViewer(win, viewer_width))
while not WindowShouldClose(): win.update supervisor