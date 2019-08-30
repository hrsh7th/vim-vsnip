if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

inoremap <Plug>(snips-expand-or-jump) <Esc>:<C-u>call snips#expand_or_jump()<CR>
snoremap <Plug>(snips-expand-or-jump) <Esc>:<C-u>call snips#expand_or_jump()<CR>

command! SnipsEdit call s:cmd_snips_edit()

augroup snips
  autocmd!
  autocmd! snips TextChanged * call s:on_text_changed()
  autocmd! snips TextChangedI * call s:on_text_changed()
  autocmd! snips TextChangedP * call s:on_text_changed()
augroup END

function! s:cmd_snips_edit()
  let l:filepath = snips#snippet#get_filepath(&filetype)
  if empty(l:filepath)
    echoerr printf('filetype(%s): snippet file is not found.', &filetype)
  endif
  execute printf('tabedit %s', l:filepath)
endfunction

function! s:on_text_changed()
  let l:session = snips#get_session()
  if snips#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

