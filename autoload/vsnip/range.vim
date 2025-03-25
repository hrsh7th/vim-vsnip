"
" vsnip#range#cover
"
function! vsnip#range#cover(whole_range, target_range) abort
  let l:cover = v:true
  let l:cover = l:cover && (a:whole_range.start.line < a:target_range.start.line || a:whole_range.start.line == a:target_range.start.line && a:whole_range.start.character <= a:target_range.start.character)
  let l:cover = l:cover && (a:target_range.end.line < a:whole_range.end.line || a:target_range.end.line == a:whole_range.end.line && a:target_range.end.character <= a:whole_range.end.character)
  return l:cover
endfunction
