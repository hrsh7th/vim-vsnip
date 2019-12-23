"
" vsnip#source#refresh.
"
function! vsnip#source#refresh(path) abort
  call vsnip#source#user_snippet#refresh(a:path)
  call vsnip#source#vscode#refresh(a:path)
endfunction

"
" vsnip#source#find.
"
function! vsnip#source#find(filetype) abort
  let l:sources = []
  let l:sources += vsnip#source#user_snippet#find(a:filetype)
  let l:sources += vsnip#source#vscode#find(a:filetype)
  return l:sources
endfunction

"
" vsnip#source#create.
"
function! vsnip#source#create(path) abort
  let l:source = []
  try
    let l:file = readfile(a:path)
    let l:file = type(l:file) == type([]) ? join(l:file, "\n") : l:file
    let l:file = iconv(l:file, 'utf-8', &encoding)
    for [l:label, l:snippet] in items(json_decode(l:file))
      let [l:prefixes, l:prefixes_alias] = s:resolve_prefix(l:snippet.prefix)
      call add(l:source, {
            \   'label': l:label,
            \   'prefix': l:prefixes,
            \   'prefix_alias': l:prefixes_alias,
            \   'body': type(l:snippet.body) == type([]) ? l:snippet.body : [l:snippet.body],
            \   'description': get(l:snippet, 'description', '')
            \ })
    endfor
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpint': v:throwpoint })
  endtry
  return sort(l:source, { a, b -> strlen(b.prefix[0]) - strlen(a.prefix[0]) })
endfunction

"
" resolve_prefix.
"
function! s:resolve_prefix(prefix) abort
  let l:prefixes = []
  let l:prefixes_alias = []

  for l:prefix in type(a:prefix) == type([]) ? a:prefix : [a:prefix]
    " namspace.
    if strlen(g:vsnip_namespace) > 0
      call add(l:prefixes, g:vsnip_namespace . l:prefix)
    endif

    " prefix.
    call add(l:prefixes, l:prefix)

    " alias.
    if l:prefix =~# '-'
      call add(l:prefixes_alias, join(map(split(l:prefix, '-'), { i, v -> v[0] }), ''))
    endif
  endfor

  return [
        \   sort(l:prefixes, { a, b -> strlen(b) - strlen(a) }),
        \   sort(l:prefixes_alias, { a, b -> strlen(b) - strlen(a) })
        \ ]
endfunction

