function! vsnip#command#edit#call(filetype)
  let l:filepath = vsnip#command#prepare_for_edit(a:filetype)
  if empty(l:filepath)
    return
  endif
  execute printf('vnew %s', l:filepath)
endfunction

