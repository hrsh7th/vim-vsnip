function! snips#expandable()
  let [l:prefix, l:snippet] = snips#cursor#get_snippet_with_prefix(&filetype)
  return !empty(l:prefix)
endfunction

function! snips#expand()
  let [l:prefix, l:snippet] = snips#cursor#get_snippet_with_prefix(&filetype)
  if empty(l:prefix)
    return
  endif

  " move to start of prefix.
  execute printf('normal! %dh', strlen(l:prefix) - 1)

  " store cursor pos.
  let l:save_paste = &paste
  let l:save_pos = getcurpos()

  " edit.
  set paste
  execute printf('normal! %dxi%s', strlen(l:prefix), join(l:snippet['body'], "\n"))

  " restore cursor pos.
  call setpos('.', l:save_pos)
  let &paste = l:save_paste
endfunction

