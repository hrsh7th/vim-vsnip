if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

" version check.
if !exists('*getbufline')
      \ || !exists('*setbufline')
      \ || !exists('*appendbufline')
      \ || !exists('*deletebufline')
  echomsg '[vim-vsnip] `vim-vsnip` was disabled.'
  echomsg '[vim-vsnip] `vim-vsnip` required getbufline/setbufline/appendbufline/deletebufline.'
  echomsg '[vim-vsnip] Please use nvim >= v0.4.0 or vim >= v8.1.0039'
  finish
endif

let g:vsnip_extra_mapping = get(g:, 'vsnip_extra_mapping', v:true)
let g:vsnip_snippet_dir = expand('~/.vsnip')
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = 0
let g:vsnip_namespace = 'vsnip:'

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
if g:vsnip_extra_mapping
  snoremap <BS> <BS>i
endif

inoremap <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call <SID>expand_or_jump()<CR>
snoremap <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call <SID>expand_or_jump()<CR>
function! s:expand_or_jump()
  let l:virtualedit = &virtualedit
  let &virtualedit = 'onemore'

  " <Plug>(vsnip-expand-or-jump) uses `<Esc>`, So should correct cursor position.
  normal! l

  try
    let l:session = vsnip#get_session()
    if !empty(l:session)
      call l:session.jump()
    else
      call vsnip#expand()
    endif
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry

  let &virtualedit = l:virtualedit
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

