if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

"
" variable
"
let g:vsnip_extra_mapping = get(g:, 'vsnip_extra_mapping', v:true)
let g:vsnip_deactivate_on = get(g:, 'vsnip_deactivate_on', g:vsnip#DeactivateOn.OutsideOfCurrentTabstop)
let g:vsnip_snippet_dir = get(g:, 'vsnip_snippet_dir', expand('~/.vsnip'))
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = get(g:, 'vsnip_sync_delay', 0)
let g:vsnip_choice_delay = get(g:, 'vsnip_choice_delay', 500)
let g:vsnip_append_final_tabstop = get(g:, 'vsnip_append_final_tabstop', v:true)
let g:vsnip_namespace = get(g:, 'vsnip_namespace', '')
let g:vsnip_filetypes = get(g:, 'vsnip_filetypes', {})
let g:vsnip_filetypes.typescriptreact = get(g:vsnip_filetypes, 'typescriptreact', ['typescript'])
let g:vsnip_filetypes.javascriptreact = get(g:vsnip_filetypes, 'javascriptreact', ['javascript'])
let g:vsnip_filetypes.vimspec = get(g:vsnip_filetypes, 'vimspec', ['vim'])

augroup vsnip#silent
  autocmd!
  autocmd User vsnip#expand silent
  autocmd User vsnip#jump silent
augroup END

"
" command
"
command! -nargs=* -bang VsnipOpen call s:open_command(<bang>0, 'vsplit', <q-args>)
command! -nargs=* -bang VsnipOpenEdit call s:open_command(<bang>0, 'edit', <q-args>)
command! -nargs=* -bang VsnipOpenVsplit call s:open_command(<bang>0, 'vsplit', <q-args>)
command! -nargs=* -bang VsnipOpenSplit call s:open_command(<bang>0, 'split', <q-args>)
function! s:open_command(bang, cmd, arg)
  let l:candidates = vsnip#source#filetypes(bufnr('%'))
  if a:bang
    let l:idx = 1
  else
    let l:idx = inputlist(['Select type: '] + map(copy(l:candidates), { k, v -> printf('%s: %s', k + 1, v) }))
    if l:idx == 0
      return
    endif
  endif

  let l:expanded_dir = expand(g:vsnip_snippet_dir)
  if !isdirectory(l:expanded_dir)
    let l:prompt = printf('`%s` does not exists, create? y(es)/n(o): ', g:vsnip_snippet_dir)
    if index(['y', 'ye', 'yes'], input(l:prompt)) >= 0
      call mkdir(l:expanded_dir, 'p')
    else
      return
    endif
  endif

  let l:ext = a:arg =~# '-format\s\+snipmate' ? 'snippets' : 'json'

  execute printf('%s %s', a:cmd, fnameescape(printf('%s/%s.%s',
  \   resolve(l:expanded_dir),
  \   l:candidates[l:idx - 1],
  \   l:ext
  \ )))
endfunction

command! -range -nargs=? -bar VsnipYank call s:add_command(<line1>, <line2>, <q-args>)
function! s:add_command(start, end, name) abort
  let lines = map(getbufline('%', a:start, a:end), { key, val -> json_encode(substitute(val, '\$', '\\$', 'ge')) })
  let format = "  \"%s\": {\n    \"prefix\": [\"%s\"],\n    \"body\": [\n      %s\n    ]\n  }"
  let name = empty(a:name) ? 'new' : a:name

  let reg = &clipboard =~# 'unnamed' ? '*' : '"'
  let reg = &clipboard =~# 'unnamedplus' ? '+' : reg
  call setreg(reg, printf(format, name, name, join(lines, ",\n      ")), 'l')
endfunction

"
" extra mapping
"
if g:vsnip_extra_mapping
  snoremap <expr> <BS> ("\<BS>" . (&virtualedit ==# '' && getcurpos()[2] >= col('$') - 1 ? 'a' : 'i'))
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

  " This is needed to keep normal-mode during 0ms to prevent CompleteDone handling by LSP Client.
  let l:maybe_complete_done = !empty(v:completed_item) && has_key(v:completed_item, 'user_data') && !empty(v:completed_item.user_data)
  if l:maybe_complete_done
    call timer_start(0, { -> l:ctx.callback() })
  else
    call l:ctx.callback()
  endif
endfunction

"
" <Plug>(vsnip-expand)
"
inoremap <silent> <Plug>(vsnip-expand) <Esc>:<C-u>call <SID>expand()<CR>
snoremap <silent> <Plug>(vsnip-expand) <C-g><Esc>:<C-u>call <SID>expand()<CR>
function! s:expand() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    call vsnip#expand()
  endfunction

  " This is needed to keep normal-mode during 0ms to prevent CompleteDone handling by LSP Client.
  let l:maybe_complete_done = !empty(v:completed_item) && has_key(v:completed_item, 'user_data') && !empty(v:completed_item.user_data)
  if l:maybe_complete_done
    call timer_start(0, { -> l:ctx.callback() })
  else
    call l:ctx.callback()
  endif
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
  autocmd InsertLeave * call s:on_insert_leave()
  autocmd TextChanged,TextChangedI,TextChangedP * call s:on_text_changed()
  autocmd BufWritePost * call s:on_buf_write_post()
  autocmd BufRead,BufNewFile *.snippets setlocal filetype=snippets
augroup END

"
" on_insert_leave
"
function! s:on_insert_leave() abort
  let l:session = vsnip#get_session()
  if !empty(l:session)
    call l:session.on_insert_leave()
  endif
endfunction

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
  call vsnip#source#refresh(resolve(fnamemodify(bufname('%'), ':p')))
endfunction

