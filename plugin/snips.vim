if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

" command.

command! SnipsEdit call s:snips_edit()

" mapping.

inoremap <Plug>(snips-expand-or-jump) <Esc>:<C-u>call snips#expand_or_jump()<CR>

" function.

function! s:snips_edit()
  let l:filepath = snips#snippet#get_filepath(&filetype)
  if empty(l:filepath)
    echoerr printf('filetype(%s): snippet file is not found.', &filetype)
  endif
  execute printf('tabedit %s', l:filepath)
endfunction

