if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

let g:vsnip_snippet_dir = expand('~/.vsnip')
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = 0
let g:vsnip_namespace = 'vsnip_'

"
" command.
"
command! VsnipOpen call s:open_command('vsplit')
command! VsnipOpenEdit call s:open_command('edit')
command! VsnipOpenVsplit call s:open_command('vsplit')
command! VsnipOpenSplit call s:open_command('split')
function! s:open_command(cmd)
  let l:candidates = split(&filetype, '\.') + ['global']
  let l:idx = inputlist(['Select type: '] + map(copy(l:candidates), { k, v -> printf('%s: %s', k + 1, v) }))
  if l:idx == 0
    return
  endif

  execute printf('%s %s', a:cmd, fnameescape(printf('%s/%s.json',
        \   g:vsnip_snippet_dir,
        \   l:candidates[l:idx - 1]
        \ )))
endfunction

"
" mapping.
"
inoremap <expr> <Plug>(vsnip-expand-or-jump) "\<C-o>:call \<SID>expand_or_jump()\<CR>"
snoremap <expr> <Plug>(vsnip-expand-or-jump) "\<C-o>:call \<SID>expand_or_jump()\<CR>"
function! s:expand_or_jump()
  let l:session = vsnip#get_session()
  if !empty(l:session)
    call l:session.jump()
  else
    call vsnip#expand()
  endif
  return ''
endfunction

"
" augroup.
"
augroup vsnip
  autocmd!
  autocmd TextChanged,TextChangedI,TextChangedP * call s:on_text_changed()
  autocmd BufWritePost * call s:on_buf_write_post()
augroup END

"
" on_text_changed.
"
function! s:on_text_changed() abort
  let l:session = vsnip#get_session()
  if !empty(l:session)
    call l:session.on_text_changed()
  endif
endfunction

"
" on_buf_write_post.
"
function! s:on_buf_write_post() abort
  call vsnip#source#refresh(fnamemodify(bufname('%'), ':p'))
endfunction

