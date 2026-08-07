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

# basedpyright rather than pyright: the semantic token support this is here
# for is one of the things the fork adds.  Installed from brew rather than
# `uv tool install`, so it does not depend on a PyPI that is reachable - the
# index configured here is a private one whose token expires.
#
# ALE keeps python diagnostics through ruff, which reads each repo's own
# ruff.toml.  This is registered for the highlighting, so the type checking is
# turned down to avoid a second and much noisier opinion on the same buffer.
if executable('basedpyright-langserver')
    servers->add({
        name: 'basedpyright',
        filetype: ['python'],
        path: exepath('basedpyright-langserver'),
        args: ['--stdio'],
        workspaceConfig: {
            basedpyright: {
                analysis: {
                    typeCheckingMode: 'off',
                    diagnosticMode: 'openFilesOnly',
                },
            },
        },
    })
endif

# vhdl_ls (VHDL-LS/rust_hdl) is here for the same reason clangd is: the tags
# file matched names globally, so a signal declared in one file coloured that
# name in every buffer, and one declared nowhere else stayed plain.  VHDL was
# the last filetype still highlighted that way.
#
# There is no brew formula or apt package, so config_vim.sh unpacks a release
# build.  Its layout is load-bearing.  The binary locates its bundled ieee and
# std libraries relative to its own path, and the path it resolves is the one
# it was launched from rather than a symlink's target, so the real file has to
# sit on PATH.  Linked instead, it panics at startup before answering
# anything, naming only the relative paths it looked in.
#
# Full analysis wants a vhdl_ls.toml mapping libraries to files, the way
# clangd wants compile_commands.json; helpers/mkvhdlls.py writes one.  Without
# it the server still starts and still highlights, but reports each file as
# outside the project and resolves nothing across files - 43 fewer identifiers
# on stopsen's main_top.vhd, silently mis-coloured rather than left plain.
#
# rootSearch is what makes that file findable.  The default workspace root is
# the current directory, so opening fpga/main_top.vhd from anywhere but the
# project root put the root below the config and the server reported it
# missing.  Searched upwards instead, editing from a subdirectory works.
#
# The token types are the standard LSP set, so signals, ports and generics
# arrive as variable, property and parameter rather than as kinds of their
# own - the same remapping clangd needs for struct fields.
if executable('vhdl_ls')
    servers->add({
        name: 'vhdl_ls',
        filetype: ['vhdl'],
        path: exepath('vhdl_ls'),
        args: [],
        rootSearch: ['vhdl_ls.toml'],
    })
endif

if !empty(servers)
    g:LspAddServer(servers)
endif

# semanticHighlight is the point of the exercise.  The rest are deliberate:
#
# autoHighlightDiags is off because ALE already reports diagnostics and two
# sets of signs in the same gutter is noise.
# showDiagOnStatusLine is off because this server sees every keystroke, so
# the status line churned with half-typed errors mid-edit.  ALE covers
# diagnostics on save; :LspDiag current fetches this server's message on
# demand.
g:LspOptionsSet({
    semanticHighlight: true,
    autoHighlightDiags: false,
    showDiagOnStatusLine: false,
})
