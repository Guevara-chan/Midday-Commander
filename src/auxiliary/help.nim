const core_help* = [
    "\a\x03>\a\x06Midday Commander\a\x05 retrofuturistic file manager v0.08",
    "\a\x03>\a\x05Developed in 2*20 by \a\x04Victoria A. Guevara",
    "\a\x01===================================================================================",
    "\a\x02ESC:\a\x01    switch between dir & console views OR deny alert choice OR cancel task",
    "\a\x02F1:\a\x01     display this cheatsheet (\a\x02ESC\a\xff to return)",
    "\a\x02F3:\a\x01     switch preview mode on/off",
    "\a\x02F5:\a\x01     copy selected entri(s)",
    "\a\x02F6:\a\x01     request moving selected entri(s) with optional renaming",
    "\a\x02F7:\a\x01     request directory creation",
    "\a\x02F8:\a\x01     delete selected entri(s)",
    "\a\x02F10:\a\x01    quit program",
    "\a\x02F11:\a\x01    switch debug info on/off",
    "\a\x02Tab:\a\x01    select next directory viewer",
    "\a\x02RAlt:\a\x01   switch quicksearch mode on/off",
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
    "\a\x02Delete:\a\x01 hilight currently viewed dir (while pressed)",
    "\a\x02End:\a\x01    paste fullpath to hilited entry into commandline",
    "\a\x02Enter:\a\x01  browse hilited dir OR run hilited file OR execute command",
    "\a\x07Ctrl+\a\x02F4-F7:\a\x01     sort entry list by name/extension/size/modification time ",
    "\a\x07Ctrl+\a\x02Insert:\a\x01    store path to hilited entry into clipboard",
    "\a\x07Ctrl+\a\x02Backspace:\a\x01 erase commandline",
    "\a\x07Shift+\a\x02F2:\a\x01       display detailed error history",
    "\a\x07Shift+\a\x02F3:\a\x01       view hilited entry in full",
    "\a\x07Shift+\a\x02F7:\a\x01       request symlink creation for hilited entry",
    "\a\x07Shift+\a\x02Insert:\a\x01   paste clipboard to commandline",
    "\a\x07Numpad|\a\x02Up:\a\x01      move 1 entry back in commandline history",
    "\a\x07Numpad|\a\x02Down:\a\x01    move 1 entry forward in commandline history",
    "\a\x07Numpad|\a\x02Del:\a\x01     browse parent dir",
    "\a\x07Numpad|\a\x02Enter:\a\x01   invert all selections in current dir",
    "\a\x07Numpad|\a\x02+:\a\x01       request pattern for mass selection in current dir",
    "\a\x07Numpad|\a\x02-:\a\x01       request pattern for mass deselection in current dir",
    "\a\x01===================================================================================",
    "                                \a\x03.[\a\xffGamepad controls\a\x03].",
    "\a\x01===================================================================================",
    "\a\x07DPad|\a\x02Up:\a\x01      move selection/view 1 line up",
    "\a\x07DPad|\a\x02Down:\a\x01    move selection/view 1 line down ",
    "\a\x07DPad|\a\x02Left:\a\x01    move to begin of listing",
    "\a\x07DPad|\a\x02Right:\a\x01   move to end of listing",
    "\a\x02A\a\x07\x1D\a\xffCross:\a\x01      browse hilited dir OR run hilited file OR confirm alert choice",
    "\a\x02B\a\x07\x1D\a\xffCircle:\a\x01     deny alert choice",
    "\a\x02Y\a\x07\x1D\a\xffTriangle:\a\x01   delete selected entri(s)",
    "\a\x02RB\a\x07\x1D\a\xffR1:\a\x01        select next directory viewer",
    "\a\x02Back\a\x07\x1D\a\xffSelect:\a\x01  cancel task",
    ]