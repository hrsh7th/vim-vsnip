if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

let g:vsnip_snippet_dir = expand('~/.vsnip')
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = 100
let g:vsnip_namespace = 'snip_'
let g:vsnip_select_pattern = '\k\+'

inoremap <expr> <Plug>(vsnip-expand-or-jump) "\<C-o>:call \<SID>expand_or_jump()\<CR>"
snoremap <expr> <Plug>(vsnip-expand-or-jump) "\<C-o>:call \<SID>expand_or_jump()\<CR>"

"
" expand_or_jump.
"
function! s:expand_or_jump()
  let l:session = vsnip#get_session()
  if !empty(l:session)
    call l:session.jump()
  else
    call vsnip#expand()
  endif
  return ''
endfunction

augroup vsnip
  autocmd!
  autocmd TextChanged,TextChangedI,TextChangedP * call s:on_text_changed()
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

