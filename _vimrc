" ======================== SETUP ================================         {{{1
" -------------------- INSTRUCTIONS -----------------------------         {{{2
" run the ./config_vim.sh script in bash or..
" 1) INSTALL pathogen:
" mkdir ~/.vim/autoload ~/.vim/bundle
" curl -Sso ~/.vim/autoload/pathogen.vim \
"   https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

" 2) DOWNLOAD the following plugins:
" clone below into bundle subdirectory of ~/.vim or ~/vimfiles
" git clone git://github.com/jiangmiao/auto-pairs.git
" git clone git://github.com/scrooloose/nerdtree.git
" git clone git://github.com/scrooloose/syntastic.git
" git clone git://github.com/klen/rope-vim.git
" git clone git://github.com/tpope/vim-fugitive.git
" git clone git://github.com/tpope/vim-sensible.git
" git clone git://github.com/SirVer/ultisnips.git
" git clone git://github.com/swinman/colorvim.git
" git clone git://github.com/swinman/taghighlight.git
"
" 3) INSERT lines into the user .vimrc / _vimrc file to source this file
"if has("win32")
"    source ~\Documents\software\environment\_vimrc
"else
"    source ~/software/environment/_vimrc
"endif
" END: --------------- INSTRUCTIONS -----------------------------         2}}}

" ------------------------ TODO ---------------------------------         {{{2
"TODO : use autocmd to automatically show lines that extend beyond screen
"in command line (without disrupting movement).. see messages, try adding also
"only showing the line if timeout for 500 ms. (time enough to read line)

"TODO : add remap of surround with (,{,[,<,",' in viusal mode
"vnoremap <C-(>

"TODO : add control to adding paren, quote etc to omit adding pair
" ("'{}'").. actually control doesn't work with [,] because GOTO cmd
" this is one of the most annoying things with pairs .. maybe change behavior
" such that only insert pairs if not immediately following change to insert
" mode.. in other words only after typing at least one other character

"TODO : change wraptext settings on git commit filetype to wrap at 70 chr?

"TODO : make a shortcut for :r!locate somefile <CR>0i:e <ESC>"edd@e
" see http://stackoverflow.com/questions/1218390/what-is-your-most-productive-shortcut-with-vim
" END: ------------------- TODO ---------------------------------         2}}}

" ------------------ PATHOGEN SETTINGS --------------------------         {{{2
filetype off
" style recommended by python-mode
call pathogen#infect()
call pathogen#helptags()
syntax enable
filetype on
filetype plugin indent on
" END: ------------- PATHOGEN SETTINGS --------------------------         2}}}

" NOTE: to output python command to the buffer use
" :.!py -c "import uuid; print uuid.uuid1()"

" END: =================== SETUP ================================         1}}}

" ====================== FUNCTIONS ==============================         {{{1
" -------------------- win32 MyDiff -----------------------------         {{{2
if has("win32")
    function! MyDiff()
        let opt = '-a --binary '
        if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
        if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
        let arg1 = v:fname_in
        if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
        let arg2 = v:fname_new
        if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
        let arg3 = v:fname_out
        if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
        let eq = ''
        if $VIMRUNTIME =~ ' '
            if &sh =~ '\<cmd'
                let cmd = '""' . $VIMRUNTIME . '\diff"'
                let eq = '"'
            else
                let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
            endif
        else
            let cmd = $VIMRUNTIME . '\diff'
        endif
        silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
    endfunction
endif
" END: --------------- win32 MyDiff -----------------------------         2}}}

" -------------------- DelWhiteSpace ----------------------------         {{{2
function! DelWhiteSpace()
    let Lineno = line('.')
    let Colno = col('.')
    silent! exec '%s/\s\+$//g'
    silent! exec '%s/\_s\+\%$//'
    exe '/\%$'
    if Lineno < line('.')
        exe Lineno
        exe "normal " . Colno . "|"
    endif
endfunction
" END: --------------- DelWhiteSpace ----------------------------         2}}}

" ---------------------- SetFFUnix ------------------------------         {{{2
function! SetFFUnix()
    update
    e ++ff=dos
    setlocal ff=unix
endfunction
" END: ----------------- SetFFUnix ------------------------------         2}}}

" ------------------ ChangeColorScheme --------------------------         {{{2
function! LightColorscheme()
    if has("gui")
        try
            colorscheme nuvola2
            set colorcolumn=
        catch /^Vim\%((\a\+)\)\=:E185/
            colorscheme default
            set colorcolumn=80
        endtry
    endif
endfunction

function! DarkColorscheme()
    if has("gui")
        try
            set colorcolumn=
            colorscheme desert2
        catch /^Vim\%((\a\+)\)\=:E185/
            colorscheme darkblue
            set colorcolumn=80
        endtry
    endif
endfunction

function! ChangeColorScheme()
    if exists("g:colors_name") && (g:colors_name=='desert2'
                \|| g:colors_name=='desert' || g:colors_name=='darkblue')
        call LightColorscheme()
    else
        call DarkColorscheme()
    endif
endfunction
" END: ------------- ChangeColorScheme --------------------------         2}}}

" ------------------- ToggleSpelling ----------------------------         {{{2
function! ToggleSpelling()
    if &spell=='nospell'
        set spell
    else
        set nospell
    endif
endfunction
" END: -------------- ToggleSpelling ----------------------------         2}}}

" -------------------- TryGoToDefine ----------------------------         {{{2
function! TryGoToDefine()
    if &ft == 'python'
        :call RopeGotoDefinition()
    elseif &ft == 'c' || &ft == 'cpp'
	:exe("cs find g " . expand("<cword>"))
"        cs find g <C-R>=expand("<cword>")<CR><CR>
    else
        return "<C-]>"
    endif
endfunction
" END: --------------- TryGoToDefine ----------------------------         2}}}

" ---------------------- GetCChar -------------------------------         {{{2
function! GetCChar()
    if &ft == 'python'
        let CChar = "#"
    elseif &ft == 'conf' || &ft == 'cfg' || &ft == 'make' || &ft == 'sh'
        let CChar = "#"
    elseif &ft == 'gitcommit' || &ft == 'gitignore' || &ft == 'gitrebase'
        let CChar = "#"
    elseif &ft == 'snippets'
        let CChar = "#"
    elseif &ft == 'udevrules'
        let CChar = '#'
    elseif &ft == 'tcl'
        let CChar = '#'
    elseif &ft == 'c' || &ft == 'cpp'
        let CChar = "//"
    elseif &ft == 'vim'
        let CChar = '"'
    elseif &ft == 'iss'
        let CChar = ';'
    elseif &ft == 'dosbatch'
        let CChar = ':'
    elseif &ft == 'tex' || &ft == 'bib'
        let CChar = '%'
    elseif &ft == 'inform'
        let CChar = ';'
    elseif &ft == 'vhdl'
        let CChar = '--'
    else
        let CChar = '"'
    endif
    return CChar
endfunction
" END: ----------------- GetCChar -------------------------------         2}}}

" ----------------------- Comment -------------------------------         {{{2
function! Comment()
    let CChar = GetCChar()
    let Line = getline('.')
    let Newline = CChar . Line
    call setline('.', Newline)
    let Lineno = line('.') + 1
    exe Lineno
endfunction
" another way to do this...
"autocmd FileType javascript nnoremap <buffer> <localleader>c 0i//<esc>j
"autocmd FileType python     nnoremap <buffer> <localleader>c 0i#<esc>jj
" END: ------------------ Comment -------------------------------         2}}}

" ------------------- ShowLineExtents ---------------------------         {{{2
function! ShowLineExtents()
    if mode() == 'n'
        let Line = getline('.')
        let Linelen = strdisplaywidth(Line)
        let Screenwidth = winwidth(0)
"        if Linelen <= Screenwidth - 3
"            return
"        endif
        "let Newline = strpart(Line, Screenwidth)
        echo Line
    endif
    return
endfunction
" END: -------------- ShowLineExtents ---------------------------         2}}}

" -------------------- ToggleLineNo -----------------------------         {{{2
function! ToggleLineNo()
    if &relativenumber
        set number
    elseif &number
        set nonumber
    else
        set relativenumber
    endif
endfunction
" END: --------------- ToggleLineNo -----------------------------         2}}}

" --------------------- CleanupCode -----------------------------         {{{2
function! CleanupCode()
    silent! exec '%s/ *\([;,]\)/\1/g'
    silent! exec '%s/\([;,]\)\(\S\)/\1 \2/g'
    silent! exec '%s/^\/\*\*\_.  \* @}\_.  \*\/\_.//g'
    silent! exec '%s/^  \* @{\_.//g'
    silent! exec '%s/^\/\*\* @defgroup \(.*\)\_.  \*\//\/\* \1 \*\//g'
    silent! exec '%s/^\/\*\* *\_.  \?\*/\/\*\*/g'
    silent! exec '%s/^\(.*end\)\@!if\([^{]*\)\_.\s*{$/\1if\2 {/g'
    silent! exec '%s/}\s*\n\s*else\n\s*{$/} else {/g'
    silent! exec '%s/\s*\n{$/ {/g'
    silent! exec '%s/<h2><center>&copy;/                 /g'
    silent! exec '%s/<\/center><\/h2>//g'
    silent! exec '%s/do\_.\s*{$/do {/g'
    silent! exec '%s/^  \* @attention\_.  \*\_.//g'
    silent! exec '%s/\*\/\_.$/\*\//gc'
    silent! exec '%s/^ *\  */'
    silent! exec '%s/\t\  /'
endfunction
" END: ---------------- CleanupCode -----------------------------         2}}}

" --------------------- ToggleWidth -----------------------------         {{{2
function! ToggleWidth()
    if &columns < 120
        set columns=165
        if winwidth(winnr()) == &columns
            exec 'vs'
        endif
    else
        exec "only"
        set columns=85
    endif
endfunction
" END: ---------------- ToggleWidth -----------------------------         2}}}

" -------------------- GetScreenSize ----------------------------         {{{2
function! GetScreenSize()
    !xrandr | grep "*" | sed "s/\s*\([^x]*\)x\(\S*\).*/\1x\2/"
endfunction
" END: --------------- GetScreenSize ----------------------------         2}}}

" -------------------- iHexChecksum -----------------------------         {{{2
function IHexChecksum()
  let l:data = getline(".")
  let l:dlen = strlen(data)

  if (empty(matchstr(l:data, "^:\\(\\x\\x\\)\\{5,}$")))
    echoerr("Input is not a valid Intel HEX line!")
    return
  endif

  let l:byte = 0
  for l:bytepos in range(1, l:dlen-4, 2)
    let l:byte += str2nr(strpart(l:data, l:bytepos, 2), 16)
  endfor

  let l:byte = (256-(l:byte%256))%256
  call setline(".", strpart(l:data, 0, l:dlen-2).printf("%02x", l:byte))
endfunction
" END: --------------- iHexChecksum -----------------------------         2}}}

if has("eval")
" ---------------- GitKeepAbove / Below -------------------------         {{{2
function! GitKeepAbove()
    " keep the top change set
    exe line('.') - 1
    :.,/^<<<<<<< /s/^<<<<<<< .*\_.//
    exe line('.') - 1
    :.,/^=======/s/^=======\_.\{-}>>>>>>> .*\_.//
endfunction

function! GitKeepBelow()
    " keep the bottom change set
    exe line('.') - 1
    .,/^<<<<<<< /s/^<<<<<<< \_.\{-}=======\_.//
    exe line('.') - 1
    .,/^>>>>>>> /s/^>>>>>>>.*\_.//
endfunction
" END: ----------- GitKeepAbove / Below -------------------------         2}}}

" ----------------------- OpenURL -------------------------------         {{{2
function! OpenURL(url)
    if has("win32")
        exe "!start cmd /cstart /b ".a:url.""
    elseif $DISPLAY !~ '^\w'
        exe "silent !sensible-browser \"".a:url."\" &"
    else
        exe "silent !sensible-browser -T \"".a:url."\" &"
    endif
    redraw!
endfunction
command! -nargs=1 OpenURL :call OpenURL(<q-args>)
" END: ------------------ OpenURL -------------------------------         2}}}

" ------------------------- Run ---------------------------------         {{{2
" ......................... Run .................................         {{{3
function! Run()
    let old_makeprg = &makeprg
    let old_errorformat = &errorformat
    try
        let cmd = matchstr(getline(1),'^#!\zs[^ ]*')
        if exists('b:run_command')
            exe b:run_command
        elseif cmd != '' && executable(cmd)
            wa
            let &makeprg = matchstr(getline(1),'^#!\zs.*').' %'
            make
        elseif &ft == 'mail' || &ft == 'text' || &ft == 'help' ||
                    \&ft == 'gitcommit'
            setlocal spell!
        elseif &ft == 'html' || &ft == 'xhtml' || &ft == 'php' ||
                    \&ft == 'aspvbs' || &ft == 'aspperl'
            wa
            if !exists('b:url')
                 call OpenURL(expand('%:p'))
            else
                 call OpenURL(b:url)
            endif
        elseif &ft == 'vim'
            w
            if exists(':Runtime')
                 return 'Runtime %'
            else
                 unlet! g:loaded_{expand('%:t:r')}
                 return 'source %'
            endif
        elseif &ft == 'sql'
            1,$DBExecRangeSQL
        elseif expand('%:e') == 'tex'
            wa
            exe "normal :!rubber -f -d --inplace %:r\<CR>"
            exe "silent :!evince %:r".".pdf"." >/dev/null 2>/dev/null &"
        elseif &ft == 'dot'
            let &makeprg = 'dotty'
            make %
        elseif &ft == 'python'
            wa
            call RunPython(expand('%:p'))
        else
            wa
            if &makeprg =~ '%'
                 make
            else
                 make %
            endif
        endif
        return ''
    finally
        let &makeprg = old_makeprg
        let &errorformat = old_errorformat
    endtry
endfunction
command! -bar Run :execute Run()
" END: .................... Run .................................         3}}}

" ...................... RunPython ..............................         {{{3
function! RunPython(fname)
    if has("win32")
        let scmd = ":!start ipython -i --no-banner " . a:fname
        exec scmd
    else
        let scmd = ":!python -i " . a:fname
        exec scmd
    endif
endfunction
" END: ................. RunPython ..............................         3}}}
" END: -------------------- Run ---------------------------------         2}}}
endif
" END: ================= FUNCTIONS ==============================         1}}}

" ==================== VIM SETTINGS =============================         {{{1
" ---------------------- Operation ------------------------------         {{{2
set nocompatible  " not compatible with vi "
set mouse=a       " enable mouse "g
set printoptions+=paper:letter
set printfont=:h9 " sets the font to 9 pts
set confirm       " turns on visual confirm instead of command failed "g
set backup        " turns on backup (saves prev. file as fn.ext~)
"set backupdir=~\vimfiles\backups

"if exists("+spelllang")
"    set spelllang=en_us
"endif
"set spellfile=~/.vim/spell/en.utf-8.add

"Settings for Searching and Moving
" set ignorecase
" set smartcase
" set gdefault
" set incsearch
" set showmatch
" set hlsearch

" More Common Settings.
"set encoding=utf-8
"set backspace=indent,eol,start
"set laststatus=2
"set undofile
"set shell=/bin/bash

" Make pasting done without any indentation break."
"set pastetoggle=<F3>

if has("win32")
    set diffexpr=MyDiff()
    let g:softwaredir="~\\Documents\\software"
    if has("gui_running")
        exe('cd ' . g:softwaredir)
    endif
else
    " Dictionary path, from which the words are being looked up.
    set dictionary=/usr/share/dict/words
    let g:softwaredir="~/software"
endif
" END: ----------------- Operation ------------------------------         2}}}

" ----------------------- Display -------------------------------         {{{2
set softtabstop=4 " tab spacing option "
set shiftwidth=4  " tab spacing option "
set expandtab     " expands tabs to multiple spaces "
set scrolloff=3   " when changing positions at least n lines visable"
set ruler         " display cursor position at bottom "
set cursorline    " highlight cursor line "
set showmode      " shows -- INSERT -- in cmd line when in insert mode "
set showcmd       " shows cmd chars you have typed on rt side at bottom "
set hidden        " allows buffers that are hidden and have unsaved changes "
set smartindent   " similar to autoindent but adds tabs in some situations "
set lazyredraw    " don't redraw in macros "
set ttyfast       " improves redrawing "
set nowrap        " vim handles long lines by letting them off the screen "
set textwidth=79  " wrap text at 80 char
set columns=85
set lines=50
set foldmethod=indent
set foldlevel=1
set formatoptions-=t        " DONT auto-wrap lines
set title         " set window title
set visualbell    " turns off bell, turns on flash
" END: ------------------ Display -------------------------------         2}}}

" --------------------- Status Line -----------------------------         {{{2
"set stl=%<%f\ %{fugitive#statusline()}%h%m%r%=%-14.(%l,%c%V%)\ %P
"set stl=[%n]\ %<%.99f\ %h%w%m%r%y%=%-16(\ %l,%c-%v\ %)%P
set statusline=[%n]\ %<%.20f
    " buffer number, file name
set statusline+=\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]
    " file encoding, file format
set statusline+=%h%m%r%y
    " help, modified, readonly, filetype flags
set statusline+=%{fugitive#statusline()}
    " git branchg
set statusline+=%=
    " left / right col seperator
set statusline+=%c,%l/%L\ %P
    " col, line, total lines  percent
" END: ---------------- Status Line -----------------------------         2}}}

" --------------------- GUI Options -----------------------------         {{{2
" Removing scrollbars
if has("gui_running")
    set guioptions-=m  "remove menu bar
    set guioptions-=T   " remove toolbar
    set guioptions-=r   " remove right-hand scroll bar
    set guioptions-=L   " remove (far) left scroll bar
    set guioptions+=c   " use console dialog instead of popup for simple choice
    set guioptions+=g   " grey menu items instead of not showing them
    set guioptions-=t   " remove tearoff menu items
"    set guitablabel=%-0.12t%M
"    set listchars=tab:?\ ,eol:¬         " Invisibles using the Textmate style
    if has("gui_win32")
        set guifont=Consolas:h10:cANSI
    else
        "silent redir => ScreenRes
        "silent call GetScreenSize()
        "silent system('xrandr | grep "*" | sed "s/\s*\([^x]*\)x\(\S*\).*/\1 \2/"')
        "redir END
        "echo ScreenRes
        set guifont=Monospace\ 9
    endif
endif
" END: ---------------- GUI Options -----------------------------         2}}}

" ---------------- Wildmenu / Wildignore ------------------------         {{{2
" Wildmenu completion "
set wildmenu
set wildmode=list:longest
set wildignore+=.hg,.git,.svn " Version Controls"
set wildignore+=*.aux,*.toc "Latex Indermediate files"
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg "Binary Imgs"
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest "Compiled Object files"
set wildignore+=*.atsuo "atmel studio binary file"
set wildignore+=*.spl "Compiled spelling world list"
set wildignore+=*.sw? "Vim swap files"
set wildignore+=*.DS_Store "OSX SHIT"
set wildignore+=*.luac "Lua byte code"
set wildignore+=migrations "Django migrations"
set wildignore+=*.pyc "Python Object codes"
set wildignore+=*.orig "Merge resolution files"
set wildignore+=*.pdf "pdf binary files"
set suffixes+=*.out "Latex intermediate"
" END: ----------- Wildmenu / Wildignore ------------------------         2}}}

" ------------------- CTags / CScope ----------------------------         {{{2
" search from the current directory to ~ for ctags and cscope files
set tags=./tags;~

function! LoadCscope()
    let db = findfile("cscope.out", ".;~")
    if (!empty(db))
        let path = strpart(db, 0, match(db, "/cscope.out$"))
        set nocscopeverbose " suppress 'duplicate connection' error
        exe "cs add " . db . " " . path
        set cscopeverbose
    endif
endfunction
au BufEnter /* call LoadCscope()

if has("cscope") && !has("win32") && 0
    set csto=0
    set cst
    set nocsverb
    set csverb
endif
" END: -------------- CTags / CScope ----------------------------         2}}}
" END: =============== VIM SETTINGS =============================         1}}}

" =================== PLUGIN SETTINGS ===========================         {{{1
" -------------------- TagHighlight -----------------------------         {{{2
if ! exists('g:TagHighlightSettings')
    let g:TagHighlightSettings = {}
endif

if has("win32")
    let g:TagHighlightSettings['CtagsExecutable'] =
                \ "C:\\Program Files (x86)\\ctags58\\ctags.exe"
else
    let g:TagHighlightSettings['CtagsExecutable'] = "/usr/bin/ctags-exuberant"
end

let g:TagHighlightSettings['TagFileName'] = 'tags'
" END: --------------- TagHighlight -----------------------------         2}}}

" ---------------------- NERDTree -------------------------------         {{{2
let NERDTreeIgnore = ['\.((jpe?g)|(png)|(PNG)|o|atsuo|docx?|xlsx?|pyc|pdf)$',
            \'\~$', '^cscope.files$', '^cscope.out$', '^tags$', '\.taghl$',
            \'\.pyc$', '\.pdf$', '\.o$', '__pycache__']
" END: ----------------- NERDTree -------------------------------         2}}}

" ---------------------- UltiSnips ------------------------------         {{{2
if has("win32")
    let g:UltiSnipsSnippetsDir = g:softwaredir . "\\environment\\snippits"
    let &runtimepath.=','.g:softwaredir . "\\environment"
else
    let g:UltiSnipsSnippetsDir = g:softwaredir . "/environment/snippits"
    let &runtimepath.=','.g:softwaredir . "/environment"
endif
let g:UltiSnipsSnippetDirectories = ["snippits","UltiSnips"]
" END: ----------------- UltiSnips ------------------------------         2}}}

" Syntastic settings
let g:syntastic_python_checkers = ['flake8']

" Ropevim settings
"let g:ropevim_autoimport_modules = ["os.*", "PyQt4.*"]
"let g:ropevim_enable_autoimport = 1
"let g:ropevim_guess_project=1

" ----------------- Personal Functions --------------------------         {{{2
au BufWritePre * call DelWhiteSpace()

call DarkColorscheme()
" END: ------------ Personal Functions --------------------------         2}}}
" END: ============== PLUGIN SETTINGS ===========================         1}}}

" ==================== KEY MAPPINGS =============================         {{{1
" ---------------------- Favorites ------------------------------         {{{2
" use B to get buffer list
nnoremap B :ls<CR>:b
" NOTE : autocmd runs at write, to disable use :noautocmd w
nnoremap Y y$

" map s to insert a space
nnoremap s i <Esc>

" comment out N number of lines (use N@c)
nnoremap @c :call Comment()<CR>

" jump between split screens
nmap <silent> <C-j> :wincmd j<CR>
nmap <silent> <C-k> :wincmd k<CR>
nmap <silent> <C-h> :wincmd h<CR>
nmap <silent> <C-l> :wincmd l<CR>
" END: ----------------- Favorites ------------------------------         2}}}

" -------------------- Command Mode -----------------------------         {{{2
" .................... Control Keys .............................         {{{3
" Ctrl S saves
nnoremap <C-s> :w<CR>

" map ctrl up and down to increment and decrement number
nnoremap <C-up> <C-a>
nnoremap <C-down> <C-x>

" Mapping to NERDTree
nnoremap <C-n> :NERDTreeToggle<cr>
" END: ............... Control Keys .............................         3}}}

" .................... Function Keys ............................         {{{3
" toggle relative line numbers
map <F2> :call ToggleLineNo()<CR>
map <F3> <Esc>:call ChangeColorScheme()<CR>
map <F4> <Esc>:call ToggleWidth()<CR>
map <F5> <Esc>:call ToggleSpelling()<CR>
map <F6> <Esc>:call ShowLineExtents()<CR>

map <F8> <ESC>{v}gq

"map <F8> :!/usr/bin/ctags-exuberant -R <CR>

" Mapping rope
"map <leader>j <ESC>:RopeGotoDefinition<cr>
map <F9> <ESC>:call TryGoToDefine()<CR>
map <F10> <C-c>rd

"goto definition with F11
map <F11> <C-]>

" Attempts to compile c / run python / open html
map <F12> :execute Run()<CR>
" END: ............... Function Keys ............................         3}}}

" ......................... g. ..................................         {{{3
" open URL under cursor in browser
nnoremap gb :OpenURL <cfile><CR>
nnoremap gG :OpenURL http://www.google.com/search?q=<cword><CR>
nnoremap gW :OpenURL http://en.wikipedia.org/wiki/Special:Search?search=<cword><CR>

nnoremap gK :call GitKeepAbove()<CR>
nnoremap gJ :call GitKeepBelow()<CR>
nnoremap gN /<<<<<<< <CR>zt
" END: .................... g. ..................................         3}}}

" ....................... CScope ................................         {{{3
nmap <C-Space>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-Space>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-Space>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-Space>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-Space>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-Space>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-Space>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
nmap <C-Space>d :cs find d <C-R>=expand("<cword>")<CR><CR>
" END: .................. CScope ................................         3}}}

" ................. Searching / Moving ..........................         {{{3
" nnoremap / /\v
" vnoremap / /\v
" nnoremap <leader><space> :noh<cr>
" nnoremap <tab> %
" vnoremap <tab> %
" END: ............ Searching / Moving ..........................         3}}}

" END: --------------- Command Mode -----------------------------         2}}}

" ------------------- Windows Options ---------------------------         {{{2
" backspace in Visual mode deletes selection
vnoremap <BS> d

" Alt-Space is System menu - use <M-Space>x to maximize/restore (n to minimize)
if has("gui")
  noremap <M-Space> :simalt ~<CR>
  inoremap <M-Space> <C-O>:simalt ~<CR>
  cnoremap <M-Space> <C-C>:simalt ~<CR>
endif

" CTRL-Tab is Next window
noremap <C-Tab> <C-W>w
inoremap <C-Tab> <C-O><C-W>w
cnoremap <C-Tab> <C-C><C-W>w
onoremap <C-Tab> <C-C><C-W>w
" END: -------------- Windows Options ---------------------------         2}}}

" --------------------- Insert Mode -----------------------------         {{{2
" insert local time
inoremap <silent> <C-G><C-T> <C-R>=repeat(complete(col('.'), map([
            \"%Y-%m-%d %H:%M:%S", "%a, %d %b %Y %H:%M:%S %z",
            \"%Y %b %d","%d-%b-%y", "%a %b %d %T %Z %Y"
            \], 'strftime(v:val)') + [localtime()]), 0)<CR>

" jj For Qicker Escaping between normal and editing mode.
inoremap jj <ESC>

" map control-backspace to delete the previous word
imap <C-BS> <C-W>
" END: ---------------- Insert Mode -----------------------------         2}}}

" -------------------- Removing Keys ----------------------------         {{{2
" help keys - accidentally pressed instead of escape
nnoremap <F1> <ESC>
inoremap <F1> <ESC>
vnoremap <F1> <ESC>

" U seems to always be the first key pressed when caps lock is on...
nnoremap U <ESC>:echo " < < ===== C H E C K   C A P S   L O C K ===== > > "<CR>
vnoremap U <ESC>:echo " < < ===== C H E C K   C A P S   L O C K ===== > > "<CR>

" home key - accidentally pressed instead of backspace
inoremap <home> <nop>
nnoremap <home> <nop>
vnoremap <home> <nop>

" Disable <C-d> and <C-u> because keep accidentally calling w/o <C
nnoremap <C-u> <nop>
nnoremap <C-d> <nop>
" END: --------------- Removing Keys ----------------------------         2}}}

" -------------------- Abbreviations ----------------------------         {{{2
abbr pty property(fget=
abbr frmt .format("
iabbr comnt <CR>\begin{comment}
\<CR>\end{comment}
\<up><esc>0
" END: --------------- Abbreviations ----------------------------         2}}}
" END: =============== KEY MAPPINGS =============================         1}}}

" vim600:foldmethod=marker
