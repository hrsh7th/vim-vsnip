function! vsnip#command#open#call(filetype) abort
  let l:filepath = vsnip#command#prepare_for_edit(a:filetype)
  if empty(l:filepath)
    return
  endif
  execute printf('vnew %s', l:filepath)
endfunction

