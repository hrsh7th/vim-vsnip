if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

let g:vsnip_snippet_dir = get(g:, 'vsnip_snippet_dir', expand('<sfile>:p:h') . '/../resource/snippets')

inoremap <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>
snoremap <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>

command! VsnipEdit call s:cmd_edit()
command! VsnipSelect call s:cmd_select()

augroup vsnip
  autocmd!
  autocmd! vsnip TextChanged * call s:on_text_changed()
  autocmd! vsnip TextChangedI * call s:on_text_changed()
  autocmd! vsnip TextChangedP * call s:on_text_changed()
augroup END

function! s:cmd_edit()
  let l:filepath = vsnip#snippet#get_filepath(&filetype)
  if empty(l:filepath)
    echoerr printf('filetype(%s): snippet file is not found.', &filetype)
  endif
  execute printf('tabedit %s', l:filepath)
endfunction

function! s:cmd_select()
  " TODO: visual selection
  call vsnip#select(expand('<cWORD>'))
endfunction

function! s:on_text_changed()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

