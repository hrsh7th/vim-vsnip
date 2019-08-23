function! snips#cursor#get_snippet_with_prefix(filetype)
  let l:definition = snips#snippet#get_definition(a:filetype)
  if empty(l:definition)
    return {}
  endif

  let l:pos = snips#utils#curpos()
  let l:line = getline(l:pos[0])
  let l:col = min([l:pos[1] - 1, strlen(l:line) - 1])
  if mode() == 'i' &&  l:pos[1] < strlen(l:line)
    let l:col = l:col - 1
  endif
  let l:text = l:line[0 : l:col]

  for [l:prefix, l:idx] in items(l:definition['index'])
    if strlen(l:text) < strlen(l:prefix)
      continue
    endif
    if l:text[-strlen(l:prefix) : -1] ==# l:prefix
      return { 'prefix': l:prefix, 'snippet': l:definition['snippets'][l:idx] }
    endif
  endfor
  return {}
endfunction

