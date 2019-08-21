if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

inoremap <Plug>(snips-expand) <Esc>:<C-u>call snips#expand()<CR>i

