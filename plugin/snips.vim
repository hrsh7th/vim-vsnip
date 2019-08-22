if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

inoremap <Plug>(snips-expand-or-jump) <C-o>:<C-u>call snips#expand_or_jump()<CR>

