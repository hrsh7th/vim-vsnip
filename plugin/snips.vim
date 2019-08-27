if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

inoremap <Plug>(snips-expand-or-jump) <Esc>:<C-u>call snips#expand_or_jump()<CR>

command! SnipsEdit call s:cmd_snips_edit()

augroup snips
  autocmd!
  autocmd! snips InsertCharPre * call s:on_insert_char_pre()
augroup END

function! s:cmd_snips_edit()
  let l:filepath = snips#snippet#get_filepath(&filetype)
  if empty(l:filepath)
    echoerr printf('filetype(%s): snippet file is not found.', &filetype)
  endif
  execute printf('tabedit %s', l:filepath)
endfunction

function! s:on_insert_char_pre()
  let l:session = snips#get_session()
  if snips#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_insert_char_pre(v:char)
  endif
endfunction

