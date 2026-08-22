" volatile, lifted out of cStorageClass into its own group.
"
" It is the one storage class whose misuse is a correctness bug rather
" than a style choice: a value another context writes has to be read ONCE
" into a local, because naming it twice emits two loads and lets them
" disagree.  Two defects of exactly that shape were found in this tree in
" one night - a ring length that went negative across a wrap, and a loss
" counter that snapshotted increments it had not reported.  Both read as
" ordinary code until you notice the qualifier, which is the argument for
" not letting it look like `static`.
"
" containedin is needed because the stock c.vim names cStorageClass in
" its contains= lists and knows nothing about this group.
syntax keyword cVolatile volatile
        \ containedin=cDefine,cBlock,cParen,cStruct,cMemberDecl

hi def link cVolatile Volatile
