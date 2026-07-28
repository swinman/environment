vim9script
# Language server registration for yegappan/lsp.
#
# This lives in after/plugin rather than in _vimrc because pack/*/start
# packages are sourced after vimrc has finished, so g:LspAddServer does not
# exist yet at that point.  config_vim.sh symlinks ~/.vim/after to this
# repo's after_vim, so dropping the file here is all the installation needed.
#
# What this buys over the tags-driven highlighting it replaces: the server
# reports what each identifier actually is, in this file, in this scope.  A
# tags file could only match names globally, so a signal declared in one file
# coloured every occurrence of that name everywhere, and a name declared
# nowhere else was left plain.

if !exists('*g:LspAddServer')
    finish
endif

var servers: list<dict<any>> = []

# clangd comes from the Xcode command line tools on mac (/usr/bin/clangd) and
# from the clangd package on linux.
#
# --query-driver is what makes the arm-none-eabi trees work: without it clangd
# uses the host's system headers and every firmware file opens with
# "'stdio.h' file not found".  A glob rather than a path, since the toolchain
# is under /opt/homebrew on mac and ~/tools on the linux boxes.
#
# --background-index builds a project-wide index in .cache/clangd, which is
# what makes find-references work across files rather than only in the open
# buffer.
if executable('clangd')
    servers->add({
        name: 'clangd',
        filetype: ['c', 'cpp'],
        path: exepath('clangd'),
        args: ['--background-index', '--query-driver=**/arm-none-eabi-*'],
    })
endif

if !empty(servers)
    g:LspAddServer(servers)
endif

# semanticHighlight is the point of the exercise.  The rest are deliberate:
#
# autoHighlightDiags is off because ALE already reports diagnostics and two
# sets of signs in the same gutter is noise.
# showDiagOnStatusLine keeps the message reachable without a popup.
g:LspOptionsSet({
    semanticHighlight: true,
    autoHighlightDiags: false,
    showDiagOnStatusLine: true,
})
