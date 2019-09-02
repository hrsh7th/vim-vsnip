function! vsnip#snippet#find_by_prefix(prefix)
  for l:snippet in vsnip#snippet#get_snippets(&filetype)
    if index(l:snippet['prefixes'], a:prefix) >= 0
      return l:snippet
    endif
  endfor
  return {}
endfunction

function! vsnip#snippet#get_prefixes(filetype)
  let l:prefixes = []
  for l:snippet in vsnip#snippet#get_snippets(a:filetype)
    call extend(l:prefixes, l:snippet['prefixes'])
  endfor
  return l:prefixes
endfunction

function! vsnip#snippet#get_filepaths(filetype)
  let l:filepaths = []
  for l:filetype in uniq([a:filetype] + split(a:filetype, '\.'))
    for l:dir in g:vsnip_snippet_dirs
      let l:filepath = printf('%s/%s.json', l:dir, l:filetype)
      if filereadable(l:filepath)
        call add(l:filepaths, l:filepath)
      endif
    endfor
  endfor
  return reverse(l:filepaths)
endfunction

function! vsnip#snippet#get_snippets(filetype)
  let l:snippets = []
  for l:filepath in vsnip#snippet#get_filepaths(a:filetype)
    call extend(l:snippets, s:normalize(json_decode(join(readfile(l:filepath), "\n"))))
  endfor
  return l:snippets
endfunction

function! vsnip#snippet#get_snippet_with_prefix_under_cursor(filetype)
  let l:snippets = vsnip#snippet#get_snippets(a:filetype)
  if empty(l:snippets)
    return {}
  endif

  let l:pos = vsnip#utils#curpos()
  let l:line = getline(l:pos[0])
  let l:col = min([l:pos[1] - 1, strlen(l:line) - 1])
  if mode() == 'i' &&  l:pos[1] <= strlen(l:line)
    let l:col = l:col - 1
  endif

  let l:text = l:line[0 : l:col]
  for l:snippet in l:snippets
    for l:prefix in l:snippet['prefixes']
      if strlen(l:text) < strlen(l:prefix)
        continue
      endif
      if l:text =~# '\<' . l:prefix . '\>$'
        return { 'prefix': l:prefix, 'snippet': l:snippet }
      endif
    endfor
  endfor
  return {}
endfunction

function! s:normalize(snippets)
  let l:snippets = []
  for [l:label, l:snippet] in items(a:snippets)
    let l:snippet['label'] = l:label
    let l:snippet['prefix'] = s:to_list(l:snippet['prefix'])
    let l:snippet['prefixes'] = s:prefixes(l:snippet['prefix'])
    let l:snippet['body'] = s:to_list(l:snippet['body'])
    let l:snippet['description'] = vsnip#utils#get(l:snippet, 'description', l:label)
    let l:snippet['name'] = l:snippet['label'] . ': ' . l:snippet['description']
    call add(l:snippets, l:snippet)
  endfor
  return l:snippets
endfunction

function! s:to_list(v)
  if type(a:v) ==# v:t_list
    return a:v
  endif
  return [a:v]
endfunction

function! s:prefixes(prefixes)
  let l:prefixes = []
  for l:prefix in a:prefixes
    call add(l:prefixes, l:prefix)
    if l:prefix =~# '^\a\w\+\%(-\w\+\)\+$'
      call add(l:prefixes, join(map(split(l:prefix, '-'), { i, v -> v[0] }), ''))
    endif
  endfor

  if strlen(g:vsnip_prefix_shortcut) > 0
    for l:prefix in copy(l:prefixes)
      call add(l:prefixes, g:vsnip_prefix_shortcut . l:prefix)
    endfor
  endif

  return l:prefixes
endfunction

