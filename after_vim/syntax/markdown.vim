" Fixes layered on top of $VIMRUNTIME/syntax/markdown.vim.
"
" The stock runtime file has four annoyances for technical prose:
"   1. markdownCode is never linked to a highlight group, so inline `code`
"      and fenced blocks render as plain body text
"   2. an underscore between two word characters (SDRV_NVIC_PAR) is matched
"      as markdownError and shows up in the error colour
"   3. _foo_ / __foo__ open italic and bold regions, so ordinary snake_case
"      prose turns into runaway emphasis
"   4. emphasis regions are not line bounded, so one unpaired asterisk in
"      running text (HAS_*, *.c, arm-none-eabi*) italicises everything after
"      it until the next asterisk, however many paragraphs away that is
" It also does "runtime! syntax/html.vim", which turns <ifc> style
" placeholders into HTML tags.

" 1) give inline code, indented blocks and fenced blocks a visible colour
hi def link markdownCode      String
hi def link markdownCodeBlock String

" 2) an underscore inside a word is not an error
syn clear markdownError

" 3) drop the underscore forms of emphasis, and 4) bound the asterisk forms
"    to a single line.  The patterns are the runtime file's, plus oneline;
"    they must be re-declared in this order so *** still wins over ** and *.
"    oneline means an unpaired asterisk highlights nothing at all, rather
"    than opening a region that runs to the next asterisk in the file.  The
"    cost is that emphasis can no longer span a wrapped line.
syn clear markdownItalic markdownBold markdownBoldItalic
syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=\*\|\*\S\@=" end="\S\@<=\*\|\*\S\@=" skip="\\\*" oneline contains=markdownLineStart,@Spell
syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=\*\*\|\*\*\S\@=" end="\S\@<=\*\*\|\*\*\S\@=" skip="\\\*" oneline contains=markdownLineStart,markdownItalic,@Spell
syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=\*\*\*\|\*\*\*\S\@=" end="\S\@<=\*\*\*\|\*\*\*\S\@=" skip="\\\*" oneline contains=markdownLineStart,@Spell

" 5) <placeholder> is literal text, not an HTML tag.  Declared after the html
"    syntax so it wins the tie.  Spaces are allowed inside so that
"    <path to application binary> is one placeholder instead of a tag named
"    "path" with three attributes.  A letter or underscore must follow the
"    "<" directly, which keeps "a < b" from matching, and neither ":" nor
"    "@" is allowed, so <http://host> and <user@host> still auto link.  It
"    is transparent so it takes the colour of whatever encloses it
"    (headings, link text) instead of forcing Normal.
syn match markdownPlaceholder "<[A-Za-z_][A-Za-z0-9_./ -]*>" transparent contains=NONE
syn cluster markdownInline add=markdownPlaceholder
