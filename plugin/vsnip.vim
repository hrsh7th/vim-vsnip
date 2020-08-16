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
let g:vsnip_namespace = get(g:, 'vsnip_namespace', '')
let g:vsnip_filetypes = get(g:, 'vsnip_filetypes', {})
let g:vsnip_filetypes.typescriptreact = get(g:vsnip_filetypes, 'typescriptreact', ['typescript'])
let g:vsnip_filetypes.javascriptreact = get(g:vsnip_filetypes, 'javascriptreact', ['javascript'])
let g:vsnip_filetypes.vimspec = get(g:vsnip_filetypes, 'vimspec', ['vim'])

"
" command
"
command! -bang VsnipOpen call s:open_command(<bang>0, 'vsplit')
command! -bang VsnipOpenEdit call s:open_command(<bang>0, 'edit')
command! -bang VsnipOpenVsplit call s:open_command(<bang>0, 'vsplit')
command! -bang VsnipOpenSplit call s:open_command(<bang>0, 'split')
function! s:open_command(bang, cmd)
  let l:candidates = vsnip#source#filetypes(bufnr('%'))
  if a:bang
    let l:idx = 1
  else
    let l:idx = inputlist(['Select type: '] + map(copy(l:candidates), { k, v -> printf('%s: %s', k + 1, v) }))
    if l:idx == 0
      return
    endif
  endif

  " if no valid directories, use g:vsnip_snippet_dir
  let l:dirs = filter(vsnip#source#user_snippet#dirs(), 'isdirectory(v:val)')
  if empty(l:dirs)
    let l:dirs = [g:vsnip_snippet_dir]
  endif

  let l:target_dir = l:dirs[0]

  if !isdirectory(l:target_dir)
    if confirm(printf('`%s` does not exists, create? ', l:target_dir), "&Yes\n&No") == 1
      call mkdir(l:target_dir, 'p')
    else
      return
    endif
  endif

  execute printf('%s %s', a:cmd, fnameescape(printf('%s/%s.json',
  \   l:target_dir,
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
  let l:context = vsnip#get_context()
  let l:session = vsnip#get_session()
  if !empty(l:context)
    call vsnip#expand()
  elseif !empty(l:session) && l:session.jumpable(1)
    call l:session.jump(1)
  endif
endfunction

"
" <Plug>(vsnip-expand)
"
inoremap <silent> <Plug>(vsnip-expand) <Esc>:<C-u>call <SID>expand()<CR>
snoremap <silent> <Plug>(vsnip-expand) <C-g><Esc>:<C-u>call <SID>expand()<CR>
function! s:expand() abort
  call vsnip#expand()
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
  let l:session = vsnip#get_session()
  if !empty(l:session) && l:session.jumpable(a:direction)
    call l:session.jump(a:direction)
  endif
endfunction

"
" <Plug>(vsnip-select-text)
"
nnoremap <silent> <Plug>(vsnip-select-text) :set operatorfunc=<SID>vsnip_select_text_normal<CR>g@
snoremap <silent> <Plug>(vsnip-select-text) <C-g>:<C-u>call <SID>vsnip_visual_text(visualmode())<CR>gv<C-g>
xnoremap <silent> <Plug>(vsnip-select-text) :<C-u>call <SID>vsnip_visual_text(visualmode())<CR>gv
function! s:vsnip_select_text_normal(type) abort
  call s:vsnip_set_text(a:type)
endfunction

"
" <Plug>(vsnip-cut-text)
"
nnoremap <silent> <Plug>(vsnip-cut-text) :set operatorfunc=<SID>vsnip_cut_text_normal<CR>g@
snoremap <silent> <Plug>(vsnip-cut-text) <C-g>:<C-u>call <SID>vsnip_visual_text(visualmode())<CR>gv"_c
xnoremap <silent> <Plug>(vsnip-cut-text) :<C-u>call <SID>vsnip_visual_text(visualmode())<CR>gv"_c

function! s:vsnip_cut_text_normal(type) abort
  call feedkeys(s:vsnip_set_text(a:type) . '"_c', 'n')
endfunction
function! s:vsnip_visual_text(type) abort
  call s:vsnip_set_text(a:type)
endfunction
function! s:vsnip_set_text(type) abort
  let oldreg = [getreg('"'), getregtype('"')]
  if a:type ==# 'v'
    let select = '`<v`>'
  elseif a:type ==# 'V'
    let select = "'<V'>"
  elseif a:type ==? "\<C-V>"
    let select = "`<\<C-V>`>"
  elseif a:type ==# 'char'
    let select = '`[v`]'
  elseif a:type ==# 'line'
    let select = "'[V']"
  else
    return
  endif
  execute 'normal! ' . select . 'y'
  call vsnip#selected_text(@")
  call setreg('"', oldreg[0], oldreg[1])
  return select
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

