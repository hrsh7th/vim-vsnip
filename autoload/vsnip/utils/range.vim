function! vsnip#utils#range#in(range1, range2) abort
  let l:in_start = a:range1['start'][0] < a:range2['start'][0]
        \ || (
        \   a:range1['start'][0] == a:range2['start'][0]
        \   && a:range1['start'][1] <= a:range2['start'][1]
        \ )
  let l:in_end = a:range2['end'][0] < a:range1['end'][0]
        \ || (
        \   a:range2['end'][0] == a:range1['end'][0]
        \   && a:range2['end'][1] <= a:range1['end'][1]
        \ )
  return l:in_start && l:in_end
endfunction

function! vsnip#utils#range#after(pos1, pos2) abort
  return a:pos1[0] < a:pos2[0]
        \ || (
        \   a:pos1[0] == a:pos2[0]
        \   && a:pos1[1] <= a:pos2[1]
        \ )
endfunction

function! vsnip#utils#range#cover(range1, range2) abort
  return vsnip#utils#range#after(a:range1['start'], a:range2['start'])
        \ && vsnip#utils#range#after(a:range2['end'], a:range1['end'])
endfunction

function! vsnip#utils#range#has_length(range) abort
  return vsnip#utils#range#valid(a:range)
        \ && a:range['start'][0] < a:range['end'][0]
        \ || (
        \   a:range['start'][0] <= a:range['end'][0]
        \   && a:range['start'][1] < a:range['end'][1]
        \ )
endfunction

function! vsnip#utils#range#relative(pos, range) abort
  return {
        \   'start': [a:range['start'][0] - a:pos[0] + 1, a:range['start'][1] - a:pos[1] + 1],
        \   'end': [a:range['end'][0] - a:pos[0] + 1, a:range['end'][1] - a:pos[1] + 1],
        \ }
endfunction

function! vsnip#utils#range#valid(range) abort
  return vsnip#utils#range#after(a:range['start'], a:range['end'])
        \ && a:range['start'][0] >= 1
        \ && a:range['start'][1] >= 1
        \ && a:range['end'][0] >= 1
        \ && a:range['end'][1] >= 1
endfunction

