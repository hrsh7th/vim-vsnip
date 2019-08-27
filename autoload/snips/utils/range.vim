function! snips#utils#range#in(a, b)
  let l:in_start = a:a['start'][0] < a:b['start'][0]
        \ || (
        \   a:a['start'][0] == a:b['start'][0] && a:a['start'][1] <= a:b['start'][1]
        \ )
  let l:in_end = a:b['end'][0] < a:a['end'][0]
        \ || (
        \   a:b['end'][0] == a:a['end'][0] && a:b['end'][1] <= a:a['end'][1]
        \ )
  return l:in_start && l:in_end
endfunction

