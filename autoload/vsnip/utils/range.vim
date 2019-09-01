function! vsnip#utils#range#in(vim_range1, vim_range2)
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

function! vsnip#utils#range#after(vim_range1, vim_range2)
  return a:vim_range1['start'][0] < a:vim_range2['start'][0]
        \ || (
        \   a:vim_range1['start'][0] == a:vim_range2['start'][0]
        \   && a:vim_range1['start'][1] <= a:vim_range2['start'][1]
        \ )
endfunction

function! vsnip#utils#range#has_length(vim_range)
  return vsnip#utils#range#valid(a:vim_range)
        \ && a:vim_range['start'][0] < a:vim_range['end'][0]
        \ || (
        \   a:vim_range['start'][0] <= a:vim_range['end'][0]
        \   && a:vim_range['start'][1] < a:vim_range['end'][1]
        \ )
endfunction

function! vsnip#utils#range#relative(vim_pos, vim_range)
  return {
        \   'start': [a:vim_range['start'][0] - a:vim_pos[0] + 1, a:vim_range['start'][1] - a:vim_pos[1] + 1],
        \   'end': [a:vim_range['end'][0] - a:vim_pos[0] + 1, a:vim_range['end'][1] - a:vim_pos[1] + 1],
        \ }
endfunction

function! vsnip#utils#range#valid(vim_range)
  return a:vim_range['start'][0] >= 1
        \ && a:vim_range['start'][1] >= 1
        \ && a:vim_range['end'][0] >= 1
        \ && a:vim_range['end'][1] >= 1
endfunction

