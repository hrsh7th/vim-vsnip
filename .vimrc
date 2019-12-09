if has('vim_starting')
  set encoding=utf-8
endif
scriptencoding utf-8

if &compatible
  " vint: -ProhibitSetNoCompatible
  set nocompatible
endif

if !isdirectory(expand('~/.vim/plugged/vim-plug'))
  silent !curl -fLo ~/.vim/plugged/vim-plug/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
end
execute printf('source %s', expand('~/.vim/plugged/vim-plug/plug.vim'))

call plug#begin('~/.vim/plugged')
Plug 'Shougo/deoplete.nvim'
Plug 'gruvbox-community/gruvbox'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
call plug#end()

colorscheme gruvbox

let g:mapleader = ' '

"
" required options.
"
set hidden
set ambiwidth=double
set completeopt=menu,menuone,noselect

"
" deoplete configuration.
"
let g:deoplete#enable_at_startup = 1

"
" vim-vsnip mapping.
"
imap <expr><Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
smap <expr><Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'

