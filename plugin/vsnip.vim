if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

"
" variable
"
let g:vsnip_extra_mapping = get(g:, 'vsnip_extra_mapping', v:true)
let g:vsnip_snippet_dir = get(g:, 'vsnip_snippet_dir', expand('~/.vsnip'))
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = get(g:, 'vsnip_sync_delay', 0)
let g:vsnip_choice_delay = get(g:, 'vsnip_choice_delay', 500)
let g:vsnip_auto_select_trigger = get(g:, 'vsnip_auto_select_trigger', ';')
let g:vsnip_namespace = get(g:, 'vsnip_namespace', '')

"
" command
"
command! -bang VsnipOpen call s:open_command(<bang>0, 'vsplit')
command! -bang VsnipOpenEdit call s:open_command(<bang>0, 'edit')
command! -bang VsnipOpenVsplit call s:open_command(<bang>0, 'vsplit')
command! -bang VsnipOpenSplit call s:open_command(<bang>0, 'split')
function! s:open_command(bang, cmd)
  let l:candidates = split(&filetype, '\.') + ['global']
  if a:bang
    let l:idx = 1
  else
    let l:idx = inputlist(['Select type: '] + map(copy(l:candidates), { k, v -> printf('%s: %s', k + 1, v) }))
    if l:idx == 0
      return
    endif
  endif

  if !isdirectory(g:vsnip_snippet_dir)
    let l:prompt = printf('`%s` does not exists, create? y(es)/n(o): ', g:vsnip_snippet_dir)
    if index(['y', 'ye', 'yes'], input(l:prompt)) >= 0
      call mkdir(g:vsnip_snippet_dir, 'p')
    else
      return
    endif
  endif

  execute printf('%s %s', a:cmd, fnameescape(printf('%s/%s.json',
        \   g:vsnip_snippet_dir,
        \   l:candidates[l:idx - 1]
        \ )))
endfunction

"
" extra mapping
"
if g:vsnip_extra_mapping
  snoremap <BS> <BS>i
endif

"
" <Plug>(vsnip-expand-or-jump)
"
inoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call <SID>expand_or_jump()<CR>
snoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call <SID>expand_or_jump()<CR>
function! s:expand_or_jump()
  let l:ctx = {}
  function! l:ctx.callback() abort
    let l:context = vsnip#get_context()
    let l:session = vsnip#get_session()
    if !empty(l:context)
      call vsnip#expand()
    elseif !empty(l:session) && l:session.jumpable(1)
      call l:session.jump(1)
    endif
  endfunction
  return s:map({ -> l:ctx.callback() })
endfunction

"
" <Plug>(vsnip-expand)
"
inoremap <silent> <Plug>(vsnip-expand) <Esc>:<C-u>call <SID>expand()<CR>
snoremap <silent> <Plug>(vsnip-expand) <C-g>o<Esc>:<C-u>call <SID>expand()<CR>
function! s:expand() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    call vsnip#expand()
  endfunction
  return s:map({ -> l:ctx.callback() })
endfunction

"
" <Plug>(vsnip-jump-next)
" <Plug>(vsnip-jump-prev)
"
inoremap <silent> <Plug>(vsnip-jump-next) <Esc>:<C-u>call <SID>jump(1)<CR>
snoremap <silent> <Plug>(vsnip-jump-next) <Esc>:<C-u>call <SID>jump(1)<CR>
inoremap <silent> <Plug>(vsnip-jump-prev) <Esc>:<C-u>call <SID>jump(-1)<CR>
snoremap <silent> <Plug>(vsnip-jump-prev) <Esc>:<C-u>call <SID>jump(-1)<CR>
function! s:jump(direction) abort
  let l:ctx = {}
  let l:ctx.direction = a:direction
  function! l:ctx.callback() abort
    let l:session = vsnip#get_session()
    if !empty(l:session) && l:session.jumpable(self.direction)
      call l:session.jump(self.direction)
    endif
  endfunction
  return s:map({ -> l:ctx.callback() })
endfunction

"
" map
"
function! s:map(fn) abort
  let l:virtualedit = &virtualedit
  let &virtualedit = 'onemore'

  try
    normal! l
    call a:fn()
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
" on_text_changed
"
function! s:on_text_changed() abort
  let l:session = vsnip#get_session()
  if !empty(l:session)
    call l:session.on_text_changed()
  endif
endfunction

"
" on_buf_write_post
"
function! s:on_buf_write_post() abort
  call vsnip#source#refresh(fnamemodify(bufname('%'), ':p'))
endfunction

