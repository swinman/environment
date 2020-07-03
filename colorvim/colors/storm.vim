" Vim color file: ------------------------------------
"                --------- s t o r m . v i m ----------
"                 ------------------------------------
" i. SETUP                                                              {{{1
"                                                                       {{{2

if version > 580
    " no guarantees below v 5.8, but this makes it stop complaining
    hi clear
    if exists("syntax_on")
        syntax reset
    endif
endif
set background=dark
let g:colors_name="storm"
"                                                                       2}}}
"                                                                       1}}}
" 1. NORMAL                                                             {{{1
hi Normal           gui=NONE            cterm=NONE          term=NONE
hi Normal           guibg=Grey19        ctermbg=236
hi Normal           guifg=White         ctermfg=15
"                                                                       1}}}
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
hi Title            gui=BOLD            cterm=BOLD
hi Title            guifg=IndianRed     ctermfg=167

hi StatusLine       gui=BOLD            cterm=BOLD
hi StatusLine       guifg=Grey80        ctermfg=252
hi StatusLine       guibg=Grey15        ctermbg=235

hi StatusLineNC     gui=NONE            cterm=NONE
hi StatusLineNC     guibg=Grey10        ctermbg=234
hi StatusLineNC     guifg=Grey50        ctermfg=244

hi Cursor           guifg=LightSlateGrey     ctermfg=103
hi Cursor           guibg=Khaki1        ctermbg=228

hi lCursor          gui=REVERSE         cterm=REVERSE
hi lCursor          guibg=NONE          ctermbg=NONE
hi lCursor          guifg=NONE          ctermfg=NONE

hi CursorLine       gui=None            cterm=None
hi CursorLine       guibg=Grey39        ctermbg=241

hi CursorLineNr     gui=BOLD            cterm=BOLD
hi CursorLineNr     guifg=Yellow        ctermfg=11
"hi CursorIM
"hi CursorColumn
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
hi Pmenu            gui=BOLD            cterm=BOLD
hi Pmenu            guifg=SkyBlue1      ctermfg=117
hi Pmenu            guibg=Grey39        ctermbg=241

hi PmenuSel         guibg=Grey30        ctermbg=239
hi PmenuSel         guifg=LightCoral    ctermfg=210

hi PmenuThumb       guibg=Grey82        ctermbg=252
hi PmenuThumb       guifg=Grey46        ctermfg=243

hi WildMenu         guifg=Black         ctermfg=0
hi WildMenu         guibg=Yellow        ctermbg=11

hi Directory        gui=BOLD            cterm=BOLD
hi Directory        guifg=SkyBlue1      ctermfg=117

hi link ErrorMsg    Error

"hi ModeMsg                              cterm=BOLD
hi ModeMsg          guifg=LightGoldenRod2    ctermfg=222

hi MoreMsg          gui=BOLD            cterm=BOLD
hi MoreMsg          guifg=SeaGreen1     ctermfg=85

hi Question         gui=BOLD            cterm=BOLD
hi Question         guifg=SpringGreen1  ctermfg=48

hi WarningMsg       guifg=Salmon1       ctermfg=209
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
hi VertSplit        gui=NONE            cterm=NONE
hi VertSplit        guibg=Grey15        ctermbg=235
hi VertSplit        guifg=Grey30        ctermfg=239

hi Folded           guibg=Grey30        ctermbg=239
hi Folded           guifg=Grey78        ctermfg=251

hi FoldColumn       guibg=Grey30        ctermbg=239
hi FoldColumn       guifg=Tan           ctermfg=180

hi LineNr           guifg=Grey74        ctermfg=250

hi OverLength       guibg=DeepPink4     ctermbg=53

hi SignColumn       guibg=Grey42        ctermbg=242
hi SignColumn       guifg=Aqua          ctermfg=14

hi ColorColumn      guibg=Grey15        ctermbg=235
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
hi IncSearch        gui=NONE            cterm=NONE
hi IncSearch        guifg=PaleTurquoise4 ctermfg=66
hi IncSearch        guibg=Khaki1        ctermbg=228

hi Search           gui=NONE            cterm=NONE
hi Search           guifg=NavajoWhite1  ctermfg=223
hi Search           guibg=Orange3       ctermbg=172

hi Visual           gui=NONE            cterm=NONE
"hi Visual           guibg=DarkGoldenrod ctermbg=136
hi Visual           guibg=Orange4       ctermbg=94
"hi Visual           guifg=Khaki1        ctermfg=228
hi Visual           guifg=Orange1       ctermfg=214

hi VisualNOS        gui=BOLD,UNDERLINE  cterm=BOLD,UNDERLINE

"hi MatchParen
hi Braces           guifg=Grey70        ctermfg=249

hi MatchParen       guibg=DarkCyan      ctermbg=36

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
hi DiffAdd          guibg=DarkBlue      ctermbg=18
hi DiffChange       guibg=DarkMagenta   ctermbg=90

hi DiffDelete       gui=NONE            cterm=NONE
hi DiffDelete       guibg=DarkCyan      ctermbg=36
hi DiffDelete       guifg=Red3          ctermfg=124

hi DiffText         gui=BOLD            cterm=BOLD
hi DiffText         guibg=Red           ctermbg=9

hi NonText          gui=BOLD            cterm=BOLD
hi NonText          guibg=Grey30        ctermbg=239
hi NonText          guifg=LightSkyBlue1 ctermfg=153

hi SpecialKey       guifg=DarkOliveGreen3 ctermfg=149

hi Conceal          guibg=Grey66        ctermbg=248
hi Conceal          guifg=Grey82        ctermfg=252

"                                                                       2}}}
"                                                                       1}}}
" 3. SYNTAX                                                             {{{1
"   a. Comment                                                          {{{2
"       NOTES                                                           {{{3
"	*Comment	any comment
"                                                                       3}}}
hi Comment          guifg=SkyBlue1      ctermfg=117
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
hi Constant         guifg=LightCoral       ctermfg=210
"                                                                       2}}}
"   c. Identifier                                                       {{{2
"       NOTES                                                           {{{3
"	*Identifier	any variable name
"	 Function	function name (also: methods for classes)
"                                                                       3}}}
hi Identifier       gui=NONE            cterm=NONE
hi Identifier       guifg=PaleGreen     ctermfg=156
hi link Function                Identifier
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
hi Statement        gui=Bold            cterm=BOLD
hi Statement        guifg=Khaki3        ctermfg=185

hi link Conditional         Statement
hi link Repeat              Statement
hi link Label               Statement
hi link Operator            Statement
hi Operator         gui=NONE
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
hi PreProc          guifg=IndianRed1    ctermfg=203
"                                                                       2}}}
"   f. Type                                                             {{{2
"       NOTES                                                           {{{3
"	*Type		int, long, char, etc.
"	 StorageClass	static, register, volatile, etc.
"	 Structure	struct, union, enum, etc.
"	 Typedef	A typedef
"                                                                       3}}}
hi Type             gui=NONE
hi Type             guifg=DarkKhaki     ctermfg=143

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
hi Special          guifg=NavajoWhite1  ctermfg=223
"                                                                       2}}}
"   h. Other                                                            {{{2
"       NOTES                                                           {{{3
"	*Underlined	text that stands out, HTML links
"	*Ignore		left blank, hidden  |hl-Ignore|
"	*Error		any erroneous construct
"	*Todo		anything that needs extra attention; mostly the
"			keywords TODO FIXME and XXX
"                                                                       3}}}
hi Underlined                           cterm=UNDERLINE
hi Underlined       guifg=CornFlowerBlue ctermfg=69

hi Ignore                               cterm=BOLD
hi Ignore           guifg=Grey39        ctermfg=241

hi Error            gui=BOLD            cterm=BOLD
hi Error            guibg=Red           ctermbg=9
hi Error            guifg=White         ctermfg=15

hi Todo             gui=BOLD            cterm=BOLD
hi Todo             guibg=Yellow        ctermbg=11
hi Todo             guifg=Red1          ctermfg=196
"                                                                       2}}}
"   i. HTML                                                             {{{2
hi htmlLink         gui=UNDERLINE       cterm=UNDERLINE
"hi htmlLink         guibg=NONE          ctermbg=NONE
hi htmlLink         guifg=Magenta       ctermfg=201

hi htmlBold                 gui=BOLD                    cterm=BOLD
hi htmlBoldItalic           gui=BOLD,ITALIC             cterm=BOLD,ITALIC
hi htmlBoldUnderline        gui=BOLD,UNDERLINE          cterm=BOLD,UNDERLINE
hi htmlBoldUnderlineItalic  gui=BOLD,UNDERLINE,ITALIC   cterm=BOLD,UNDERLINE,ITALIC
hi htmlItalic               gui=ITALIC                  cterm=ITALIC
hi htmlUnderline            gui=UNDERLINE               cterm=UNDERLINE
hi htmlUnderlineItalic      gui=UNDERLINE,ITALIC        cterm=UNDERLINE,ITALIC
"                                                                       2}}}
"                                                                       1}}}
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
" Member
" Namespace
" Structure
" Type
" Union
" Also recommended are Enumerator and GlobalConstant
" more from plugin/TagHighlight/data/kinds.txt
"                                                                       3}}}
hi link AutoCommand         Keyword
hi Class            guifg=Thistle1      ctermfg=225
hi link Command             Keyword
hi DefinedName      guifg=MistyRose3    ctermfg=181
hi EnumerationValue guifg=Plum1         ctermfg=219
hi EnumeratorName   guifg=MediumPurple2 ctermfg=135
hi link Extern              Keyword
hi link File                Keyword
hi link GlobalConstant      Keyword
hi GlobalVariable   guifg=NavajoWhite1  ctermfg=223
hi Import           guifg=Yellow2       ctermfg=190
hi link LocalVariable       Keyword
hi Map              guifg=Gold1         ctermfg=220
hi Member           guifg=DarkSeaGreen2 ctermfg=157
hi link Namespace           Keyword
hi Union            guifg=DarkKhaki     ctermfg=143
hi link pythonOperator      Operator
hi link pythonFunction      Function
"hi link pythonBuiltin       Operator
"hi pythonBuiltin    guifg=NONE
"                                                                       2}}}
"   b. vhdl                                                               {{{2

hi link vhdlStatement   Statement
    " vhdlStatement     LIBRARY USE CASE IF
hi vhdlNone         guibg=Orange        ctermbg=214
    " vhdlNone ?
hi link vhdlType        Type
    " vhdlType      INTEGER STD_LOGIC etc
hi link vhdlAttribute   Member
    " vhdlAttribtue is      x'Event
hi link vhdlBoolean     Constant
    " vhdlBoolean   true, TRUE, false
hi link vhdlVector      String
    " vhdlVector        X"01001010001001001"
hi link vhdlCharacter   GlobalVariable
    " vhdlCharacter     '1'
hi link vhdlString      String
    " vhdlString        \"something like this"
hi link vhdlNumber      Constant
    " vhdlNumber is     123      but not 12_000
hi link vhdlOperator    Special
    " vhdlOperator is   AND = := / <= => +
hi link vhdlSpecial     vhdlOperator
    " vhdlSpecial is      ;.()
hi link vhdlTime        GlobalVariable
    " vhdlTime          15 ns
hi link vhdlComment     Comment
hi link vhdlGlobal      GlobalVariable
    " vhdlGlobal ?

hi link CTagsPackage        Member
    " stopsen_pkg low_logic_pkg
hi link CTagsGlobalConstant vhdlGlobal
    " SIG_LEN seed3_stdl F_SYS_kHZ F_SAMPLE_kHZ ROM_BLOCK_SIZE ADC_LEAD_0s ADC_CPOL ROM_ADDR_BITS F_IN_kHZ LOG2N ROM_BLOCKS ADC_MAX T_sample_low T_half seed2_stdl ROM_ADDR_WIDTH T_half_ps LOG2_ROM_BLOCK_SIZE LOG2NxADC ADC_RES count_to LOG2NxADCxx2 ROM_DATA_WIDTH ADC_CPHA LOG2_ROM_DATA_WIDTH cycles_per_sample CORR_nA CORR_nB
hi link CTagsEntity         Member
    " sample_clk_gen ram shift_reg_tb pseudorandom stopsen_tb stopsen_calc led_pattern_tb adc_itf mux shift_register mux2 adc_itf_tb top_level_altera correlate_sum pll_altera_12x48 rom_generic sample_clk_tb pll_12x48 flipflop led_rom top_level correlations_tb rom_1x_altera led_pattern
hi link CTagsEnumerationValue EnumerationValue
    " state values
hi link CTagsType           vhdlType
    " STD_LOGIC_ARRAY led_from_rom_array mem_type Ruu_array u_array Ryu_array y_array Ryy_array


"                                                                         2}}}
"   c. Additional tags                                                    {{{2
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
"hi link FunctionObject          Keyword
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
"hi link Variable                Keyword
"hi link View                    Keyword
"hi link VirtualPattern          Keyword
"                                                                       2}}}
"                                                                       1}}}
" A. NOTES                                                              {{{1
"   a. General                                                          {{{2
" use :highlight to see current settings and current tags
" use hi \TAB\TAB for list of possible tags
"
" use :redir @* | highlight | redir END     to load highlight out into register
" then: @*p to paste from register into buffer
"
" see highlight-groups: ColorColumn, Conceal, CursorIM, CursorColumn, CursorLine
"
" for an easy color picker use http://www.colorpicker.com  'gb will open url'
" this is based off desert.vim
"
" https://jonasjacek.github.io/colors/
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
"                                                                       1}}}
" X. VIMCONFIG                                                          {{{1
"                                                                       {{{2
" vim: tw=0 ts=4 sw=4
" vim600:foldmethod=marker
"                                                                       2}}}
"                                                                       1}}}
