if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

let g:vsnip_snippet_dir = expand('~/.vsnip')
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = 100
let g:vsnip_namespace = 'snip_'
let g:vsnip_select_trigger = ' '
let g:vsnip_select_pattern = '\k\+'

let s:timer_ids = {
      \   'on_insert_leave': -1,
      \   'on_win_leave': -1
      \ }

inoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>
snoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>

command! VsnipOpen
      \ call vsnip#command#open#call(&filetype)
command! -nargs=? -complete=customlist,vsnip#command#edit#complete VsnipEdit
      \ call vsnip#command#edit#call(&filetype, '<args>')

augroup vsnip
  autocmd!
  autocmd! vsnip TextChanged * call s:on_text_changed()
  autocmd! vsnip TextChangedI * call s:on_text_changed_i()
  autocmd! vsnip TextChangedP * call s:on_text_changed_p()
  autocmd! vsnip InsertEnter * call s:on_insert_enter()
  autocmd! vsnip InsertLeave * call s:on_insert_leave()
  autocmd! vsnip WinLeave * call s:on_win_leave()
  autocmd! vsnip BufWritePre * call s:on_buf_write_pre()
augroup END

function! s:on_text_changed() abort
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_text_changed_i() abort
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_text_changed_p() abort
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_insert_enter() abort
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_insert_enter()
  endif
endfunction

function! s:on_insert_leave() abort
  let l:fn = {}
  function! l:fn.tick() abort
    if mode()[0] ==# 'n'
      call vsnip#deactivate()
    endif
  endfunction
  call timer_stop(s:timer_ids['on_insert_leave'])
  call timer_start(500, { -> l:fn.tick() }, { 'repeat': 1 })
endfunction

function! s:on_win_leave() abort
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    function! s:on_tick(session, id)
      if a:session['bufnr'] != bufnr('%')
        call vsnip#deactivate()
      endif
    endfunction
    call timer_stop(s:timer_ids['on_win_leave'])
    let s:timer_ids['on_win_leave'] = timer_start(500, function('s:on_tick', [l:session]), { 'repeat': 1 })
  endif
endfunction

function! s:on_buf_write_pre() abort
  call vsnip#snippet#invalidate(fnamemodify(bufname('%'), ':p'))
endfunction

