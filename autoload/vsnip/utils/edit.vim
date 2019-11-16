"
" Replace buffer text.
"
" @param vim_range - start: inclusive, end: exclusive
"
function! vsnip#utils#edit#replace_buffer(vim_range, lines) abort
  let l:range_len = a:vim_range['end'][0] - a:vim_range['start'][0] + 1
  let l:lines_len = len(a:lines)

  let l:start_line = getline(a:vim_range['start'][0])
  let l:start_line_before = a:vim_range['start'][1] > 1 ? l:start_line[0 : a:vim_range['start'][1] - 2] : ''
  let l:end_line = getline(a:vim_range['end'][0])
  let l:end_line_after = a:vim_range['end'][1] <= strlen(l:end_line) ? l:end_line[a:vim_range['end'][1] - 1 : -1] : ''

  let l:i = 0
  while l:i < l:lines_len
    " create text.
    let l:text = ''
    if l:i == 0 | let l:text .= l:start_line_before | endif
    let l:text .= a:lines[l:i]
    if l:i == l:lines_len - 1 | let l:text .= l:end_line_after | endif

    " change or append.
    let l:lnum = a:vim_range['start'][0] + l:i
    if l:lnum <= a:vim_range['end'][0]
      call setline(l:lnum, l:text)
    else
      call append(l:lnum - 1, l:text)
    endif

    let l:i += 1
  endwhile

  " remove.
  let l:i = l:lines_len
  while l:i < l:range_len
    call deletebufline('%', a:vim_range['start'][0] + l:lines_len)
    let l:i +=1
  endwhile
endfunction

"
" Replace text.
"
" @param vim_range - start: inclusive, end: exclusive
"
function! vsnip#utils#edit#replace_text(target, vim_range, lines) abort
  let l:target = a:target
  let l:range_len = a:vim_range['end'][0] - a:vim_range['start'][0] + 1
  let l:lines_len = len(a:lines)

  let l:start_line = l:target[a:vim_range['start'][0] - 1]
  let l:start_line_before = a:vim_range['start'][1] > 1 ? l:start_line[0 : a:vim_range['start'][1] - 2] : ''
  let l:end_line = l:target[a:vim_range['end'][0] - 1]
  let l:end_line_after = a:vim_range['end'][1] <= strlen(l:end_line) ? l:end_line[a:vim_range['end'][1] - 1 : -1] : ''

  let l:i = 0
  while l:i < l:lines_len
    " create text.
    let l:text = ''
    if l:i == 0 | let l:text .= l:start_line_before | endif
    let l:text .= a:lines[l:i]
    if l:i == l:lines_len - 1 | let l:text .= l:end_line_after | endif

    " change or append.
    let l:lnum = a:vim_range['start'][0] + l:i
    if l:lnum <= a:vim_range['end'][0]
      let l:target[l:lnum - 1] = l:text
    else
      call insert(l:target, l:text, l:lnum - 1)
    endif

    let l:i += 1
  endwhile

  " remove.
  let l:i = l:lines_len
  while l:i < l:range_len
    call remove(l:target, a:vim_range['start'][0] + l:lines_len - 1)
    let l:i +=1
  endwhile

  return l:target
endfunction

"
" Select or insert start.
"
" @param vim_range - start: inclusive, end: exclusive
"
function! vsnip#utils#edit#select_or_insert(vim_range) abort
  if vsnip#utils#range#has_length(a:vim_range)
    let l:mode = mode()
    call cursor(a:vim_range['end'])
    normal! hgh
    if l:mode[0] ==# 'i'
      call cursor([a:vim_range['start'][0], a:vim_range['start'][1] + 1])
      stopinsert
    else
      call cursor(a:vim_range['start'])
    endif
  else
    call cursor(a:vim_range['start'])
    startinsert
  endif
endfunction

"
" Choise.
"
function! vsnip#utils#edit#choice(vim_range, choices) abort
  function! s:start_complete(vim_range, choices, timer_id) abort
    if mode() ==# 'i'
      call complete(a:vim_range['start'][1], map(copy(a:choices), { i, v -> {
            \   'word': v,
            \   'abbr': v,
            \   'menu': '[choice]'
            \ }}))
      call timer_start(0, { -> timer_stop(a:timer_id) }, { 'repeat': 1 })
    endif
  endfunction

  call cursor(a:vim_range['end'])
  startinsert

  " TODO: Sometimes, pupupmenu was close unexpectedly. Probably caused by auto-completion plugins.
  call timer_start(&updatetime, function('s:start_complete', [a:vim_range, a:choices]), { 'repeat': -1 })
endfunction

