" Vim color file: ------------------------------------
"                ------- n u v o l a 2 . v i m --------
"                 ------------------------------------
" i. SETUP                                                              {{{1
"                                                                       {{{2
set background=light
if version > 580
    " no guarantees below v 5.8, but this makes it stop complaining
    hi clear
    if exists("syntax_on")
    syntax reset
    endif
endif
let g:colors_name = "summer"
"                                                                       2}}}

" 1. NORMAL                                                             {{{1
hi Normal           gui=NONE            cterm=NONE          term=NONE
hi Normal           guibg=Grey89        ctermbg=254
hi Normal           guifg=Grey19        ctermfg=236

" 2. GROUPS                                                             {{{1
"   a. Title, Tabs, Status, Cursor                                      {{{2
"       NOTES                                                           {{{3
"Title		titles for output from ":set all", ":autocmd" etc.
"TabLine		tab pages line, not active tab page label
"TabLineFill	tab pages line, where there are no labels
"TabLineSel	tab pages line, active tab page label
"StatusLine	status line of current window
"StatusLineNC	status lines of not-current windows
"		Note: if this is equal to "StatusLine" Vim will use "^^^" in
"		the status line of the current window.
"The 'statusline' syntax allows the use of 9 different highlights in the
"statusline and ruler (via 'rulerformat').  The names are User1 to User9.
"Cursor		the character under the cursor
"CursorIM	like Cursor, but used when in IME mode |CursorIM|
"CursorLine	the screen line that the cursor is in when 'cursorline' is set
"CursorColumn	screen col that the cursor is in when 'cursorcolumn' is set
"                                                                       3}}}
hi Title            gui=BOLD
hi Title            guibg=NONE
hi Title            guifg=#1014AD

hi StatusLine       gui=BOLD            cterm=NONE          term=BOLD,REVERSE
hi StatusLine       guibg=Grey40        ctermbg=DarkGray
hi StatusLine       guifg=Grey90        ctermfg=Yellow

hi StatusLineNC     gui=NONE
hi StatusLineNC     guibg=Grey40
hi StatusLineNC     guifg=Grey70

hi Cursor           gui=NONE
hi Cursor           guibg=#1071CE
hi Cursor           guifg=#F8F8F8
"hi Cursor          guifg=#F8F8F8       guibg=#8000FF

hi CursorIM         gui=NONE
hi CursorIM         guibg=#8000FF
hi CursorIM         guifg=#F8F8F8

hi CursorLine       guibg=Grey95
"                                                                       2}}}
"   b. Menus, Pop-ups, Directory, Messages                              {{{2
"       NOTES                                                           {{{3
"Pmenu		Popup menu: normal item.
"PmenuSel	Popup menu: selected item.
"PmenuSbar	Popup menu: scrollbar.
"PmenuThumb	Popup menu: Thumb of the scrollbar.
"WildMenu	current match in 'wildmenu' completion
"Directory	directory names (and other special names in listings)
"ErrorMsg	error messages on the command line
"ModeMsg		'showmode' message (e.g., "-- INSERT --")
"MoreMsg		|more-prompt|
"Question	|hit-enter| prompt and yes/no questions
"WarningMsg	warning messages
"
"GUI Only (not Win32): font, guifg & guibg are the only 3 that work
"Menu		Current font, background and foreground colors of the menus.
"		Also used for the toolbar.
"		Applicable highlight arguments: font, guibg, guifg.
"
"		NOTE: For Motif and Athena the font argument actually
"		specifies a fontset at all times, no matter if 'guifontset' is
"		empty, and as such it is tied to the current |:language| when
"		set.
"
"Tooltip		Current font, background and foreground of the tooltips.
"		Applicable highlight arguments: font, guibg, guifg.
"
"		NOTE: For Motif and Athena the font argument actually
"		specifies a fontset at all times, no matter if 'guifontset' is
"		empty, and as such it is tied to the current |:language| when
"		set.
"                                                                       3}}}
hi Pmenu            guibg=Orange
hi Pmenu            guifg=Red

hi PmenuSel         guibg=Green
hi PmenuSel         guifg=Blue

"hi PmenuSbar
"hi PmenuThumb

hi WildMenu         gui=UNDERLINE
hi WildMenu         guibg=#E9E9F4
hi WildMenu         guifg=#56A0EE

hi Directory        guibg=NONE
hi Directory        guifg=#0000FF

hi ErrorMsg         gui=BOLD
hi ErrorMsg         guibg=NONE
hi ErrorMsg         guifg=#EB1513

hi ModeMsg          gui=BOLD
hi ModeMsg          guibg=NONE
hi ModeMsg          guifg=#0070FF

hi MoreMsg          guibg=NONE
hi MoreMsg          guifg=seagreen

hi link Question            MoreMsg
hi link WarningMsg          ErrorMsg
"                                                                       2}}}
"   c. Splits, Folds, LineNo, Scroll, Signs, ColorColumn                {{{2
"       NOTES                                                           {{{3
"VertSplit	the column separating vertically split windows
"Folded		line used for closed folds
"FoldColumn	'foldcolumn'
"LineNr		Line number for ":number" and ":#" commands, and when 'number'
"		or 'relativenumber' option is set.
"CursorLineNr	Like LineNr when 'cursorline' is set for the cursor line.
"SignColumn	column where |signs| are displayed
"ColorColumn	used for the columns set with 'colorcolumn'
"OverLength  (CUSTOM) to slightly highlight lines that go over length
"
"GUI Only (not Win32): font, guifg & guibg are the only 3 that work
"Scrollbar	Current background and foreground of the main window's
"		scrollbars.
"		Applicable highlight arguments: guibg, guifg.
"                                                                       3}}}
hi VertSplit        gui=NONE
hi VertSplit        guibg=Grey40
hi VertSplit        guifg=Grey70

hi Folded           guibg=Grey80
hi Folded           guifg=Grey30
hi link FoldColumn          Folded

hi LineNr           gui=NONE
hi LineNr           guibg=Grey80
hi LineNr           guifg=Grey30

hi CursorLineNr	    guibg=Grey80
hi CursorLineNr	    guifg=Black

hi OverLength       guibg=#FF8888       ctermbg=Red
hi OverLength       ctermfg=White
match OverLength /\%81v\+/
"                                                                       2}}}
"   d. Search, Visual, MatchParen                                       {{{2
"       NOTES                                                           {{{3
"IncSearch	'incsearch' highlighting; also used for the text replaced with
"		":s///c"
"Search		Last search pattern highlighting (see 'hlsearch').
"		Also used for highlighting the current line in the quickfix
"		window and similar items that need to stand out.
"Visual		Visual mode selection
"VisualNOS	Visual mode selection when vim is "Not Owning the Selection".
"		Only X11 Gui's |gui-x11| and |xterm-clipboard| supports this.
"MatchParen	The character under the cursor or just before it, if it
"		is a paiRed bracket, and its match. |pi_paren.txt|
"                                                                       3}}}
hi IncSearch        gui=UNDERLINE       cterm=UNDERLINE
hi IncSearch        guibg=#FFE568       ctermbg=brown
hi IncSearch        guifg=Black         ctermfg=Black

hi Search           gui=NONE            cterm=UNDERLINE     term=reverse
hi Search           guibg=#FFE568       ctermbg=brown
hi Search           guifg=Black         ctermfg=Black

hi Visual           gui=NONE                                term=reverse
hi Visual           guibg=#BDDFFF       ctermbg=black
hi Visual           guifg=Black         ctermfg=yellow

hi VisualNOS        gui=UNDERLINE                           term=reverse
hi VisualNOS        guibg=#BDDFFF       ctermbg=Black
hi VisualNOS        guifg=Black         ctermfg=Yellow

hi Braces           guifg=Grey50        ctermfg=Yellow
match Braces /[(){}\[\]]/
"                                                                       2}}}
"   e. Diff, Spelling, Special Text                                     {{{2
"       NOTES                                                           {{{3
"DiffAdd		diff mode: Added line |diff.txt|
"DiffChange	diff mode: Changed line |diff.txt|
"DiffDelete	diff mode: Deleted line |diff.txt|
"DiffText	diff mode: Changed text within a changed line |diff.txt|
"SpellBad	Word that is not recognized by the spellchecker. |spell|
"		This will be combined with the highlighting used otherwise.
"SpellCap	Word that should start with a capital. |spell|
"		This will be combined with the highlighting used otherwise.
"SpellLocal	Word that is recognized by the spellchecker as one that is
"		used in another region. |spell|
"		This will be combined with the highlighting used otherwise.
"SpellRare	Word that is recognized by the spellchecker as one that is
"		hardly ever used. |spell|
"		This will be combined with the highlighting used otherwise.
"Conceal		placeholder characters substituted for concealed
"		text (see 'conceallevel')
"NonText		'~' and '@' at the end of the window, characters from
"		'showbreak' and other characters that do not really exist in
"		the text (e.g., ">" displayed when a double-wide character
"		doesn't fit at the end of the line).
"SpecialKey	Meta and special keys listed with ":map", also for text used
"		to show unprintable characters in the text, 'listchars'.
"		Generally: text that is displayed differently from what it
"		really is.
"                                                                       3}}}
hi DiffAdd          gui=NONE
hi DiffAdd          guibg=#C8F2EA
hi DiffAdd          guifg=#2020FF

hi DiffChange       gui=NONE
hi DiffChange       guibg=#D0FFD0
hi DiffChange       guifg=#006800

hi link DiffDelete          DiffAdd

hi DiffText         gui=NONE
hi DiffText         guibg=#FFEAE0
hi DiffText         guifg=#F83010

"hi SpellRare
hi NonText          gui=BOLD
hi NonText          guibg=Grey70
hi NonText          guifg=Grey10

"hi SpecialKey       gui=NONE
"hi SpecialKey       guibg=NONE
"hi SpecialKey       guifg=#A35B00
"                                                                       2}}}

" 3. SYNTAX                                                             {{{1
"   a. Comment                                                          {{{2
"       NOTES                                                           {{{3
"	*Comment	any comment
"                                                                       3}}}
hi Comment                                                  term=BOLD
"hi Comment          guifg=#3F6B5B       ctermfg=DarkGray
hi Comment          guifg=#209090       ctermfg=DarkGray
"                                                                       2}}}
"   b. Constant                                                         {{{2
"       NOTES                                                           {{{3
"	*Constant	any constant
"	 String		a string constant: "this is a string"
"	 Character	a character constant: 'c', '\n'
"	 Number		a number constant: 234, 0xff
"	 Boolean	a boolean constant: TRUE, false
"	 Float		a floating point constant: 2.3e10
"                                                                       3}}}
hi Constant                                                 term=UNDERLINE
hi Constant         guifg=#B91F49       ctermfg=Red

hi String           guifg=#EE7070
hi link Character  Constant

hi Number           gui=NONE                                term=UNDERLINE
hi Number           guifg=#50b050       ctermfg=Red

hi Boolean          guifg=#459045
hi link Float      Number
"                                                                       2}}}
"   c. Identifier                                                       {{{2
"       NOTES                                                           {{{3
"	*Identifier	any variable name
"	 Function	function name (also: methods for classes)
"                                                                       3}}}
hi Identifier                                               term=UNDERLINE
hi Identifier       guifg=Blue          ctermfg=Blue

hi Function         gui=BOLD
hi Function         guifg=#408040
"                                                                       2}}}
"   d. Statement                                                        {{{2
"       NOTES                                                           {{{3
"	*Statement	any statement
"	 Conditional	if, then, else, endif, switch, etc.
"	 Repeat		for, do, while, etc.
"	 Label		case, default, etc.
"	 Operator	"sizeof", "+", "*", etc.
"	 Keyword	any other keyword
"	 Exception	try, catch, throw
"                                                                       3}}}
hi Statement        gui=BOLD                                term=BOLD
hi Statement        guifg=#1071CE       ctermfg=DarkRed

hi link Conditional         Statement
hi link Repeat              Statement
hi link Label               Statement
hi link Operator            Statement
hi link Keyword             Statement
hi link Exception           Statement
"                                                                       2}}}
"   e. Preprocessor                                                     {{{2
"       NOTES                                                           {{{3
"	*PreProc	generic Preprocessor
"	 Include	preprocessor #include
"	 Define		preprocessor #define
"	 Macro		same as Define
"	 PreCondit	preprocessor #if, #else, #endif, etc.
"                                                                       3}}}
hi PreProc                                                  term=UNDERLINE
hi PreProc          guifg=#FF6060       ctermfg=DarkBlue
"hi PreProc          guifg=#1071CE       ctermfg=darkblue

hi link Include        PreProc
hi link Define         PreProc
hi link Macro          PreProc
hi link PreCondit      PreProc
"                                                                       2}}}
"   f. Type                                                             {{{2
"       NOTES                                                           {{{3
"	*Type		int, long, char, etc.
"	 StorageClass	static, register, volatile, etc.
"	 Structure	struct, union, enum, etc.
"	 Typedef	A typedef
"                                                                       3}}}
hi Type             gui=NONE                                term=UNDERLINE
hi Type             guifg=Blue          ctermfg=Blue

hi link StorageClass       Type
hi link Structure          Type
hi link Typedef            Type
"                                                                       2}}}
"   g. Special                                                          {{{2
"       NOTES                                                           {{{3
"	*Special	any special symbol
"	 SpecialChar	special character in a constant
"	 Tag		you can use CTRL-] on this
"	 Delimiter	character that needs attention
"	 SpecialComment	special things inside a comment
"	 Debug		debugging statements
"                                                                       3}}}
hi Special                                                  term=BOLD
hi Special          guifg=Red2          ctermfg=DarkMagenta

hi link SpecialChar        Special

hi Tag                                                      term=BOLD
hi Tag              guifg=DarkGreen     ctermfg=DarkGreen

hi link Delimiter          Special
hi link SpecialComment     Special
hi link Debug              Special

"                                                                       2}}}
"   h. Other                                                            {{{2
"       NOTES                                                           {{{3
"	*Underlined	text that stands out, HTML links
"	*Ignore		left blank, hidden  |hl-Ignore|
"	*Error		any erroneous construct
"	*Todo		anything that needs extra attention; mostly the
"			keywords TODO FIXME and XXX
"                                                                       3}}}
"hi Underlined
"hi Ignore
hi Error                                                    term=REVERSE
hi Error            guibg=Red           ctermbg=9
hi Error            guifg=White         ctermfg=15

hi Todo                                                     term=STANDOUT
hi Todo             guibg=Yellow        ctermbg=Yellow
hi Todo             guifg=Blue          ctermfg=Blue
"                                                                       2}}}
"   i. HTML                                                             {{{2
hi htmlLink         gui=UNDERLINE
hi htmlLink         guibg=NONE
hi htmlLink         guifg=#0000FF

hi htmlBold                             gui=BOLD
hi htmlBoldItalic                       gui=BOLD,ITALIC
hi htmlBoldUnderline                    gui=BOLD,UNDERLINE
hi htmlBoldUnderlineItalic              gui=BOLD,UNDERLINE,ITALIC
hi htmlItalic                           gui=ITALIC
hi htmlUnderline                        gui=UNDERLINE
hi htmlUnderlineItalic                  gui=UNDERLINE,ITALIC
"                                                                       2}}}

" 4. CTAGS ADD-ON (TagHL)                                               {{{1
"   a. python, vim, sh, c, make                                         {{{2
"       NOTES                                                           {{{3
" AutoCommand
" Class
" Command
" Constant
" DefinedName
" EnumerationValue
" EnumeratorName
" Extern
" File
" Function
" GlobalVariable
" Import
" LocalVariable
" Map
" Member                - python method
" Namespace
" Structure
" Type
" Union
" Also recommended are Enumerator and GlobalConstant
" more from plugin/TagHighlight/data/kinds.txt
"                                                                       3}}}
hi link AutoCommand         Keyword
hi Class            guifg=#886688
hi link Command             Keyword
hi DefinedName      guifg=#666666
hi EnumerationValue guifg=#448844
hi link EnumeratorName      Keyword
hi link Extern              Keyword
hi link File                Keyword
hi link GlobalConstant      Constant
hi GlobalVariable   guifg=#A06000
hi link Import              Keyword
hi link LocalVariable       GlobalVariable
hi link Map                 Keyword
hi link Member              Function
hi link Namespace           Keyword
hi link Union               Keyword
hi link pythonOperator      Operator
hi link pythonFunction      Function
hi link pythonBuiltin       Statement
"                                                                       2}}}
"   b. Additional tags                                                  {{{2
"hi link Anchor                  Keyword
"hi link BlockData               Keyword
"hi link CommonBlocks            Keyword
"hi link Component               Keyword
"hi link Data                    Keyword
"hi link Domain                  Keyword
"hi link Entity                  Keyword
"hi link EntryPoint              Keyword
"hi link Enumeration             Keyword
"hi link EnumerationName         Keyword
"hi link Event                   Keyword
"hi link Exception               Keyword
"hi link Feature                 Keyword
"hi link Field                   Keyword
"hi link FileDescription         Keyword
"hi link Format                  Keyword
"hi link Fragment                Keyword
hi link FunctionObject      Function
"hi link GroupItem               Keyword
"hi link Index                   Keyword
"hi link Interface               Keyword
"hi link InterfaceComponent      Keyword
"hi link Label                   Keyword
"hi link Macro                   Keyword
"hi link Method                  Keyword
"hi link Module                  Keyword
"hi link Namelist                Keyword
"hi link NetType                 Keyword
"hi link Package                 Keyword
"hi link Paragraph               Keyword
"hi link Pattern                 Keyword
"hi link Port                    Keyword
"hi link Program                 Keyword
"hi link Property                Keyword
"hi link Prototype               Keyword
"hi link Publication             Keyword
"hi link Record                  Keyword
"hi link RegisterType            Keyword
"hi link Section                 Keyword
"hi link Service                 Keyword
"hi link Set                     Keyword
"hi link Signature               Keyword
"hi link Singleton               Keyword
"hi link Slot                    Keyword
"hi link SqlCursor               Keyword
"hi link Subroutine              Keyword
"hi link Synonym                 Keyword
"hi link Table                   Keyword
"hi link Task                    Keyword
"hi link Trigger                 Keyword
"hi link TypeComponent           Keyword
"hi link Variable                GlobalVariable
"hi link View                    Keyword
"hi link VirtualPattern          Keyword
"                                                                       2}}}

" A. NOTES                                                              {{{1
"   a. General                                                          {{{2
" use :highlight to see current settings and current tags
" use hi \TAB\TAB for list of possible tags
"
" see highlight-groups: ColorColumn, Conceal, CursorIM, CursorColumn, CursorLine
"
" for an easy color picker use http://www.colorpicker.com  'gb will open url'
" this is based off desert.vim
"
" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors
"                                                                       2}}}
"   b. Color Terminal Options                                           {{{2
"color terminal colors
"	    NR-16   NR-8    COLOR NAME ~
"	    0	    0	    Black
"	    1	    4	    DarkBlue
"	    2	    2	    DarkGreen
"	    3	    6	    DarkCyan
"	    4	    1	    DarkRed
"	    5	    5	    DarkMagenta
"	    6	    3	    Brown, DarkYellow
"	    7	    7	    LightGray, LightGrey, Gray, Grey
"	    8	    0*	    DarkGray, DarkGrey
"	    9	    4*	    Blue, LightBlue
"	    10	    2*	    Green, LightGreen
"	    11	    6*	    Cyan, LightCyan
"	    12	    1*	    Red, LightRed
"	    13	    5*	    Magenta, LightMagenta
"	    14	    3*	    Yellow, LightYellow
"	    15	    7*	    White
"
"	The number under "NR-16" is used for 16-color terminals ('t_Co'

"	8-color terminals ('t_Co' less than 16).  The '*' indicates that the
"	bold attribute is set for ctermfg.  In many 8-color terminals (e.g.,
"	"linux"), this causes the bright colors to appear.  This doesn't work
"	for background colors!	Without the '*' the bold attribute is removed.
"	If you want to set the bold attribute in a different way, put a
"	"cterm=" argument AFTER the "ctermfg=" or "ctermbg=" argument.	Or use
"	a number instead of a color name.
"	                                                                    2}}}
"   c. GUI Options                                                      {{{2
" all settings: [term, cterm, gui], [ctermfg, ctermbg, guifg, guibg],
" [font, guisp] guisp is special, like undercurl
"    Red		LightRed	    DarkRed
"    Green	    LightGreen	    DarkGreen	SeaGreen
"    Blue	    LightBlue	    DarkBlue	SlateBlue
"    Cyan	    LightCyan	    DarkCyan
"    Magenta	LightMagenta	DarkMagenta
"    Yellow	    LightYellow	    Brown		DarkYellow
"    Gray	    LightGray	    DarkGray
"    Black	    White
"    Orange	    Purple		    Violet
"                                                                       2}}}

" X. VIMCONFIG                                                          {{{1
"                                                                       {{{2
" vim: tw=0 ts=4 sw=4
" vim600:foldmethod=marker
"                                                                       2}}}
