function! snips#utils#range#in(vim_range1, vim_range2)
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

function! snips#utils#range#after(vim_range1, vim_range2)
  return a:vim_range1['start'][0] < a:vim_range2['start'][0]
        \ || (
        \   a:vim_range1['start'][0] == a:vim_range2['start'][0]
        \   && a:vim_range1['start'][1] <= a:vim_range2['start'][1]
        \ )
endfunction

function! snips#utils#range#has_length(vim_range)
  return a:vim_range['start'][0] < a:vim_range['end'][0]
        \ || (
        \   a:vim_range['start'][0] <= a:vim_range['end'][0]
        \   && a:vim_range['start'][1] < a:vim_range['end'][1]
        \ )
endfunction

