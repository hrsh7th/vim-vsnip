let g:snips#snippet#dir = expand('<sfile>:p:h') . '/../../sample-snippet'

function! snips#snippet#get_filepath(filetype)
  for l:filetype in split(a:filetype, '\.')
    let l:filepath = printf('%s/%s.json', g:snips#snippet#dir, l:filetype)
    if filereadable(l:filepath)
      return l:filepath
    endif
  endfor
  return ''
endfunction

function! snips#snippet#get_definition(filetype)
  for l:filetype in split(a:filetype, '\.')
    let l:filepath = printf('%s/%s.json', g:snips#snippet#dir, l:filetype)
    if filereadable(l:filepath)
      return s:normalize(json_decode(join(readfile(l:filepath), "\n")))
    endif
  endfor
  return s:normalize({})
endfunction

function! snips#snippet#get_snippet_with_prefix_under_cursor(filetype)
  let l:definition = snips#snippet#get_definition(a:filetype)
  if empty(l:definition)
    return {}
  endif

  let l:pos = snips#utils#curpos()
  let l:line = getline(l:pos[0])
  let l:col = min([l:pos[1] - 1, strlen(l:line) - 1])
  if mode() == 'i' &&  l:pos[1] <= strlen(l:line)
    let l:col = l:col - 1
  endif

  let l:text = l:line[0 : l:col]
  for [l:prefix, l:idx] in items(l:definition['index'])
    if strlen(l:text) < strlen(l:prefix)
      continue
    endif
    if l:text =~# '\<' . l:prefix . '\>$'
      return { 'prefix': l:prefix, 'snippet': l:definition['snippets'][l:idx] }
    endif
  endfor
  return {}
endfunction

function! s:normalize(snippets)
  let l:normalized = { 'index': {}, 'snippets': [] }
  for [l:label, l:snippet] in items(a:snippets)
    let l:snippet['prefix'] = s:to_list(l:snippet['prefix'])
    let l:snippet['body'] = s:to_list(l:snippet['body'])
    for l:prefix in s:prefixes(l:snippet['prefix'])
      let l:normalized['index'][l:prefix] = len(l:normalized['snippets'])
    endfor
    call add(l:normalized['snippets'], l:snippet)
  endfor
  return l:normalized
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
  return l:prefixes
endfunction

