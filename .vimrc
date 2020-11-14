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
Plug 'gruvbox-community/gruvbox'
Plug expand('<sfile>:p:h:h') . '/vim-vsnip'
Plug expand('<sfile>:p:h:h') . '/vim-vsnip-integ'
call plug#end()

PlugInstall

colorscheme gruvbox

let g:mapleader = ' '

"
" required options.
"
set hidden
set ambiwidth=double
set completeopt=menu,menuone,noselect

let g:vsnip_snippet_dirs = [dein#get('vim-vsnip').rtp . '/misc']

"
" vim-vsnip mapping.
"
imap <expr><C-j>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-j>'
smap <expr><C-j>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-j>'

imap <expr><Tab>   vsnip#available(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr><Tab>   vsnip#available(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

