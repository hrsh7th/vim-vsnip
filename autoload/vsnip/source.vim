"
" vsnip#source#refresh.
"
function! vsnip#source#refresh(path) abort
  call vsnip#source#user_snippet#refresh(a:path)
endfunction

"
" vsnip#source#find.
"
function! vsnip#source#find(filetype) abort
  let l:sources = []
  call extend(l:sources, vsnip#source#user_snippet#find(a:filetype))
  return l:sources
endfunction

"
" vsnip#source#create.
"
function! vsnip#source#create(path) abort
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

