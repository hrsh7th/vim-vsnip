" MIT License
"
" Copyright 2009-2010 Michael Sanders. All rights reserved.

" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:

" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.

" The software is provided "as is", without warranty of any kind, express or
" implied, including but not limited to the warranties of merchantability,
" fitness for a particular purpose and noninfringement. In no event shall the
" authors or copyright holders be liable for any claim, damages or other
" liability, whether in an action of contract, tort or otherwise, arising from,
" out of or in connection with the software or the use or other dealings in the
" software." From https://github.com/garbas/vim-snipmate


" Syntax highlighting for .snippets files (used for snipMate.vim)
" Hopefully this should make snippets a bit nicer to write!
syn match snipComment '^#.*'
syn match placeHolder '\${\d\+\(:.\{-}\)\=}' contains=snipCommand
syn match tabStop '\$\d\+'
syn match snipEscape '\\\\\|\\`'
syn match snipCommand '\%(\\\@<!\%(\\\\\)*\)\@<=`.\{-}\%(\\\@<!\%(\\\\\)*\)\@<=`'
syn match snippet '^snippet.*' contains=multiSnipText,snipKeyword
syn match snippet '^extends.*' contains=snipKeyword
syn match multiSnipText '\S\+ \zs.*' contained
syn match snipKeyword '^(snippet|extends)'me=s+8 contained
syn match snipError "^[^#vse\t].*$"

hi link snippet       Identifier
hi link snipComment   Comment
hi link multiSnipText String
hi link snipKeyword   Keyword
hi link snipEscape    SpecialChar
hi link placeHolder   Special
hi link tabStop       Special
hi link snipCommand   String
hi link snipError     Error
