let s:cache = {}

function! vsnip#snippet#invalidate(filepath) abort
  if has_key(s:cache, a:filepath)
    unlet s:cache[a:filepath]
  endif
endfunction

function! vsnip#snippet#get_prefixes(filetype) abort
  let l:prefixes = []
  for l:snippet in vsnip#snippet#get_snippets(a:filetype)
    call extend(l:prefixes, l:snippet['prefixes'])
  endfor
  return l:prefixes
endfunction

function! vsnip#snippet#get_filepaths(filetype) abort
  let l:filepaths = []
  for l:filetype in uniq([a:filetype] + split(a:filetype, '\.'))
    for l:dir in uniq(g:vsnip_snippet_dirs + [g:vsnip_snippet_dir])
      let l:filepath = resolve(printf('%s/%s.json', l:dir, l:filetype))
      if filereadable(l:filepath)
        call add(l:filepaths, l:filepath)
      endif
    endfor
  endfor
  return reverse(l:filepaths)
endfunction

function! vsnip#snippet#get_snippets(filetype) abort
  let l:snippets = []
  for l:filepath in vsnip#snippet#get_filepaths(a:filetype)
    if !has_key(s:cache, l:filepath)
      let s:cache[l:filepath] = s:normalize(vsnip#utils#json#read(l:filepath))
    endif
    call extend(l:snippets, s:cache[l:filepath])
  endfor
  return l:snippets
endfunction

function! vsnip#snippet#get_snippet_with_prefix_under_cursor(filetype) abort
  let l:snippets = vsnip#snippet#get_snippets(a:filetype)
  if empty(l:snippets)
    return {}
  endif

  let l:pos = vsnip#utils#curpos()
  let l:line = getline(l:pos[0])
  let l:col = min([l:pos[1] - 1, strlen(l:line) - 1])
  if mode() ==# 'i' &&  l:pos[1] <= strlen(l:line)
    let l:col = l:col - 1
  endif

  let l:text = l:line[0 : l:col]
  for l:snippet in l:snippets
    for l:prefix in l:snippet['prefixes']

      let l:pattern = '\(\<' . l:prefix . '\>\)' . '\(' . g:vsnip_auto_select_trigger . '\)' . '\(' . g:vsnip_auto_select_pattern . '\)$'
      let l:matches = matchlist(l:text, l:pattern)

      if empty(get(l:matches, 1, ''))
        continue
      endif
      let l:prefix = l:matches[1]
      let l:prefix .= get(l:matches, 2, '')
      let l:prefix .= get(l:matches, 3, '')

      if !empty(get(l:matches, 3, ''))
        call vsnip#select(l:matches[3])
      endif

      return { 'prefix': l:prefix, 'snippet': l:snippet }
    endfor
  endfor
  return {}
endfunction

function! s:normalize(snippet_map) abort
  let l:snippets = []
  for [l:label, l:snippet] in items(a:snippet_map)
    let l:snippet['label'] = l:label
    let l:snippet['prefix'] = vsnip#utils#to_list(l:snippet['prefix'])
    let l:snippet['prefixes'] = s:prefixes(l:snippet['prefix'])
    let l:snippet['body'] = vsnip#utils#to_list(l:snippet['body'])
    let l:snippet['description'] = vsnip#utils#get(l:snippet, 'description', l:label)
    let l:snippet['name'] = l:snippet['label'] . ': ' . l:snippet['description']
    call add(l:snippets, l:snippet)
  endfor
  return l:snippets
endfunction

function! s:prefixes(prefixes) abort
  let l:prefixes = []
  for l:prefix in a:prefixes
    " user defined prefix.
    call add(l:prefixes, l:prefix)

    " namespace prefix.
    if strlen(g:vsnip_namespace) > 0
      call add(l:prefixes, g:vsnip_namespace . l:prefix)
    endif

    " prefix abbr.
    if l:prefix =~# '^\a\w\+\%(-\w\+\)\+$'
      call add(l:prefixes, join(map(split(l:prefix, '-'), { i, v -> v[0] }), ''))
    endif
  endfor

  return l:prefixes
endfunction

