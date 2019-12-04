let s:sources = {}

"
" vsnip#source#refresh.
"
function! vsnip#source#refresh(path) abort
  if has_key(s:sources, a:path)
    unlet s:sources[a:path]
  endif
endfunction

"
" vsnip#source#find.
"
function! vsnip#source#find(filetype) abort
  let l:sources = []
  for l:path in s:get_source_paths(a:filetype)
    if !has_key(s:sources, l:path)
      let s:sources[l:path] = s:source(l:path)
    endif
    call add(l:sources, s:sources[l:path])
  endfor
  return l:sources
endfunction

"
" get_source_paths.
"
function! s:get_source_paths(filetype) abort
  let l:paths = []
  for l:dir in [g:vsnip_snippet_dir] + g:vsnip_snippet_dirs
    for l:name in split(a:filetype, '\.') + ['global']
      let l:path = resolve(printf('%s/%s.json', l:dir, l:name))
      if has_key(s:sources, l:path) || filereadable(l:path)
        call add(l:paths, l:path)
      endif
    endfor
  endfor
  return l:paths
endfunction

"
" source.
"
function! s:source(path) abort
  let l:source = []
  try
    let l:file = readfile(a:path)
    let l:file = type(l:file) == type([]) ? l:file : [l:file]
    for [l:label, l:snippet] in items(json_decode(join(l:file, "\n")))
      call add(l:source, {
            \   'label': l:label,
            \   'prefix': s:resolve_prefix(l:snippet.prefix),
            \   'body': type(l:snippet.body) == type([]) ? l:snippet.body : [l:snippet.body],
            \   'description': get(l:snippet, 'description', '')
            \ })
    endfor
  catch /.*/
  endtry
  return l:source
endfunction

"
" resolve_prefix.
"
function! s:resolve_prefix(prefix) abort
  let l:prefixes = []
  for l:prefix in type(a:prefix) == type([]) ? a:prefix : [a:prefix]
    if strlen(g:vsnip_namespace) > 0
      call add(l:prefixes, g:vsnip_namespace . l:prefix)
    endif
    call add(l:prefixes, l:prefix)
    if l:prefix =~# '-'
      call add(l:prefixes, join(map(split(l:prefix, '-'), { i, v -> v[0] }), ''))
    endif
  endfor

  return l:prefixes
endfunction

