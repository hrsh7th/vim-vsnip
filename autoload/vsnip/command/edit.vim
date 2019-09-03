
function! vsnip#command#edit#call(filetype)
  let l:filepath = vsnip#command#prepare_user_snippet(a:filetype)
  if empty(l:filepath)
    return
  endif
  execute printf('vnew %s', l:filepath)
endfunction

