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

