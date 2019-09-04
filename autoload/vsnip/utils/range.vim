function! vsnip#utils#range#in(vim_range1, vim_range2) abort
  let l:in_start = a:vim_range1['start'][0] < a:vim_range2['start'][0]
        \ || (
        \   a:vim_range1['start'][0] == a:vim_range2['start'][0]
        \   && a:vim_range1['start'][1] <= a:vim_range2['start'][1]
        \ )
  let l:in_end = a:vim_range2['end'][0] < a:vim_range1['end'][0]
        \ || (
        \   a:vim_range2['end'][0] == a:vim_range1['end'][0]
        \   && a:vim_range2['end'][1] <= a:vim_range1['end'][1]
        \ )
  return l:in_start && l:in_end
endfunction

function! vsnip#utils#range#after(vim_pos1, vim_pos2) abort
  return a:vim_pos1[0] < a:vim_pos2[0]
        \ || (
        \   a:vim_pos1[0] == a:vim_pos2[0]
        \   && a:vim_pos1[1] <= a:vim_pos2[1]
        \ )
endfunction

function! vsnip#utils#range#has_length(vim_range) abort
  return vsnip#utils#range#valid(a:vim_range)
        \ && a:vim_range['start'][0] < a:vim_range['end'][0]
        \ || (
        \   a:vim_range['start'][0] <= a:vim_range['end'][0]
        \   && a:vim_range['start'][1] < a:vim_range['end'][1]
        \ )
endfunction

function! vsnip#utils#range#relative(vim_pos, vim_range) abort
  return {
        \   'start': [a:vim_range['start'][0] - a:vim_pos[0] + 1, a:vim_range['start'][1] - a:vim_pos[1] + 1],
        \   'end': [a:vim_range['end'][0] - a:vim_pos[0] + 1, a:vim_range['end'][1] - a:vim_pos[1] + 1],
        \ }
endfunction

function! vsnip#utils#range#valid(vim_range) abort
  return vsnip#utils#range#after(a:vim_range['start'], a:vim_range['end'])
        \ && a:vim_range['start'][0] >= 1
        \ && a:vim_range['start'][1] >= 1
        \ && a:vim_range['end'][0] >= 1
        \ && a:vim_range['end'][1] >= 1
endfunction

function! vsnip#utils#range#get_range_under_cursor(cmd_range) abort
  " range specified in visual mode.
  if a:cmd_range == 2
    let l:start = getpos("'<")
    let l:end = getpos("'>")

    let l:end_line = getline(l:end[1])
    if strlen(l:end_line) < l:end[2]
      let l:end[2] = strlen(l:end_line) + 1
    endif

    return {
          \   'start': [l:start[1], l:start[2]],
          \   'end': [l:end[1], l:end[2]]
          \ }
  endif

  " create current word range.
  let l:word = expand('<cword>')
  let l:word_len = strlen(l:word)
  let l:text = getline('.')
  let l:i = col('.')
  while 0 <= l:i
    if l:text[l:i - 1 : l:i + l:word_len - 2] == l:word
      return {
            \ 'start': [line('.'), l:i],
            \ 'end': [line('.'), l:i + l:word_len - 1]
            \ }
    endif
    let l:i -= 1
  endwhile
  return ''
endfunction

function! vsnip#utils#range#get_lines(vim_range) abort
  let l:lines = []
  for l:lnum in range(a:vim_range['start'][0], a:vim_range['end'][0])
    if a:vim_range['start'][0] == a:vim_range['end'][0]
      call add(l:lines, getline(l:lnum)[a:vim_range['start'][1] - 1 : a:vim_range['end'][1] - 1])
    else
      if l:lnum == a:vim_range['start'][0]
        call add(l:lines, getline(l:lnum)[a:vim_range['start'][1] - 1 : -1])
      elseif l:lnum == a:vim_range['end'][0]
        call add(l:lines, getline(l:lnum)[0 : a:vim_range['end'][1] - 1])
      else
        call add(l:lines, getline(l:lnum))
      endif
    endif
  endfor
  return l:lines
endfunction

