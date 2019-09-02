if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [expand('<sfile>:p:h') . '/../resource/snippets'])
let g:vsnip_sync_delay = 100
let g:vsnip_prefix_shortcut = 'snip_'
let g:vsnip_verbose = get(g:, 'snip_verbose', v:false)

inoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>
snoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>

command! VsnipEdit call s:cmd_edit()
command! -range=% VsnipSelect call s:cmd_select(<range>)

augroup vsnip
  autocmd!
  autocmd! vsnip TextChanged * call s:on_text_changed()
  autocmd! vsnip TextChangedI * call s:on_text_changed()
  autocmd! vsnip TextChangedP * call s:on_text_changed()
  autocmd! vsnip InsertLeave * call s:on_insert_leave()
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

function! s:cmd_select(cmd_range)
  let l:range = vsnip#utils#range#get_range_under_cursor(a:cmd_range)
  let l:lines = vsnip#utils#range#get_lines(l:range)
  call vsnip#select(join(l:lines, "\n"))
endfunction

function! s:on_text_changed()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_insert_leave()
  " Avoid <Plug>(vsnip-expand-or-jump)'s `<Esc>`.
  call timer_start(200, { -> vsnip#select('') }, { 'repeat': 1 })
endfunction

