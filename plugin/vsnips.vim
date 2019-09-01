if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

let g:vsnips_snippet_dir = get(g:, 'vsnips_snippet_dir', expand('<sfile>:p:h') . '/../resource/snippets')

inoremap <Plug>(vsnips-expand-or-jump) <Esc>:<C-u>call vsnips#expand_or_jump()<CR>
snoremap <Plug>(vsnips-expand-or-jump) <Esc>:<C-u>call vsnips#expand_or_jump()<CR>

command! VsnipsEdit call s:cmd_edit()

augroup vsnips
  autocmd!

  " sync state.
  autocmd! vsnips TextChanged * call s:on_text_changed()
  autocmd! vsnips TextChangedI * call s:on_text_changed()
  autocmd! vsnips TextChangedP * call s:on_text_changed()
augroup END

function! s:cmd_edit()
  let l:filepath = vsnips#snippet#get_filepath(&filetype)
  if empty(l:filepath)
    echoerr printf('filetype(%s): snippet file is not found.', &filetype)
  endif
  execute printf('tabedit %s', l:filepath)
endfunction

function! s:on_text_changed()
  let l:session = vsnips#get_session()
  if vsnips#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

