if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [expand('<sfile>:p:h') . '/../resource/snippets'])
let g:vsnip_snippet_dirs = map(g:vsnip_snippet_dirs, { i, v -> resolve(v) })
let g:vsnip_sync_delay = 100
let g:vsnip_namespace = 'snip_'
let g:vsnip_verbose = get(g:, 'snip_verbose', v:false)

inoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>
snoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>

command! VsnipEdit call s:cmd_edit()

augroup vsnip
  autocmd!
  autocmd! vsnip TextChanged * call s:on_text_changed()
  autocmd! vsnip TextChangedI * call s:on_text_changed()
  autocmd! vsnip TextChangedP * call s:on_text_changed()
  autocmd! vsnip InsertLeave * call s:on_insert_leave()
  autocmd! vsnip TextYankPost * call s:on_text_yank_post()
  autocmd! vsnip BufWritePre * call s:on_buf_write_pre()
augroup END

function! s:cmd_edit()
  let l:filepaths = vsnip#snippet#get_filepaths(&filetype)
  if len(l:filepaths) == 0
    echoerr printf('filetype(%s): Snippet file is not found.', &filetype)
    return
  endif

  if len(l:filepaths) > 1
    let l:index = inputlist(['Select snippet file: '] + map(copy(l:filepaths), { k, v -> printf('%s: %s', l:k + 1, l:v) }))
    if l:index < 1
      return
    endif
    let l:filepath = l:filepaths[l:index - 1]
  else
    let l:filepath = l:filepaths[0]
  endif

  execute printf('tabedit %s', l:filepath)
endfunction

function! s:on_text_changed()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_text_yank_post()
  if v:operator == 'y'
    call vsnip#select(getreg(v:register))
  endif
endfunction

function! s:on_insert_leave()
  " Avoid <Plug>(vsnip-expand-or-jump)'s `<Esc>`.
  call timer_start(200, { -> vsnip#select('') }, { 'repeat': 1 })
endfunction

function! s:on_buf_write_pre()
  let l:filepath = fnamemodify(bufname('%'), ':p')
  for l:dir in g:vsnip_snippet_dirs
    if stridx(l:filepath, l:dir) >= 0
      call vsnip#snippet#invalidate(l:filepath)
    endif
  endfor
endfunction

