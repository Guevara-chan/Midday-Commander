import os, strutils, times, sequtils, strformat, sugar, raylib
from unicode import Rune, runes, runeLen, `==`, `$`
{.this: self.}
{.experimental.}

#.{ [Classes]
when not defined(Area):
    type Area* {.inheritable.} = ref object
        parent*: Area
        lapse*:  int64
        repeater, clicker*: Time

    # --Methods goes here:
    method update*(self: Area): Area {.discardable base.} = discard
    method render*(self: Area): Area {.discardable base.} = discard
    proc norepeat*(self: Area): bool = 
        if (getTime() - repeater).inMilliseconds - lapse > 110: repeater = getTime(); result = true
        lapse = 0
# -------------------- #
when not defined(TerminalEmu):
    type TerminalEmu* = ref object
        font:       Font
        cur, cell:  Vector2
        fg, bg:     Color
        palette:    seq[Color]
        title:      string
        fps_table:  seq[int]
        dbginfo:    bool
        margin*, max_fps*, min_width, min_height: int

    # --Properties.
    template hlines*(self: TerminalEmu): int = GetScreenWidth() div self.cell.x.int
    template vlines*(self: TerminalEmu): int = GetScreenHeight() div self.cell.y.int
    template hpos*(self: TerminalEmu): int = (self.cur.x / self.cell.x).int
    template vpos*(self: TerminalEmu): int = (self.cur.y / self.cell.y).int

    proc focused*(self: TerminalEmu): bool =
        when defined(windows):
            proc GetFocus(): pointer {.stdcall, dynlib: "user32", discardable, importc: "GetFocus".}
            return GetFocus() == GetWindowHandle()
        else: return true

    # --Methods goes here:
    proc loc_precise(self: TerminalEmu, x = 0, y = 0) =
        cur.x = x.float; cur.y = y.float

    proc loc*(self: TerminalEmu, x = 0, y = 0) =
        loc_precise((x.float * cell.x).int, (y.float * cell.y).int)

    proc write*(self: TerminalEmu, txt: string, fg_init = Color(), bg_init = Color(); raw = false) =
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
        else: chunks = @[txt.replace('\n', ' ').replace('\0', ' ')]
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

    proc write*(self: TerminalEmu, chunks: open_array[string], fg_init = Color(), bg_init = Color(), raw = false) =
        write "", fg_init, bg_init
        for chunk in chunks: write chunk, raw=raw

    proc pick*(self: TerminalEmu, x = GetMouseX(), y = GetMouseY()): auto =
        (x div cell.x.int, y div cell.y.int)

    proc resize*(self: TerminalEmu, hlines, vlines: int) =
        SetWindowSize hlines * cell.x.int, vlines * cell.y.int

    proc adjust*(self: TerminalEmu) =
        resize self.hlines - self.hlines %% 2, self.vlines

    proc limit_fps*(self: TerminalEmu, limit: int) =
        if max_fps != limit: limit.SetTargetFPS
        max_fps = limit

    proc update*(self: TerminalEmu, areas: varargs[Area]) =
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

    proc loop_with*(self: TerminalEmu, areas: varargs[Area]) = 
        while not WindowShouldClose(): update areas

    proc newTerminalEmu*(title, icon: string; min_width, min_height: int; colors: varargs[Color]): TerminalEmu =
        # Init setup.
        FLAG_WINDOW_RESIZABLE.uint32.SetConfigFlags
        InitWindow(880, 400, title)
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
                0x2580,0x2524,0x2552,0x2558,0x2555,0x255B,0x251C,0x2194,0x2561,0x255E,0xB7,0xB0,0xA0
            ] & rus_chars
        glyphs[0x80..0x80+extra_chars.len-1] = extra_chars
        # Terminal object.
        result = TerminalEmu(font:"res/TerminalVector.ttf".LoadFontEx(12,glyphs.addr,glyphs.len), palette:colors.toSeq)
        result.cell  = result.font.MeasureTextEx("0", result.font.baseSize.float32, 0)
        (result.title, result.min_width, result.min_height) = (title, min_width, min_height)
        # Finalization.
        result.resize(min_width, min_height)
        SetWindowMinSize(GetScreenWidth(), GetScreenHeight())
#.}