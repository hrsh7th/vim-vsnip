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
function! vsnip#source#find(bufnr) abort
  let l:sources = []
  let l:sources += vsnip#source#user_snippet#find(a:bufnr)
  let l:sources += vsnip#source#vscode#find(a:bufnr)
  return l:sources
endfunction

"
" vsnip#source#filetypes
"
function! vsnip#source#filetypes(bufnr) abort
  let l:filetype = getbufvar(a:bufnr, '&filetype', '')
  return split(l:filetype, '\.') + get(g:vsnip_filetypes, l:filetype, []) + ['global']
endfunction

"
" vsnip#source#create.
"
function! vsnip#source#create(path) abort
  try
    let l:file = readfile(a:path)
    let l:file = type(l:file) == type([]) ? join(l:file, "\n") : l:file
    let l:file = iconv(l:file, 'utf-8', &encoding)
    let l:json = json_decode(l:file)

    if type(l:json) != type({})
      throw printf('%s is not valid json.', a:path)
    endif
  catch /.*/
    let l:json = {}
    echohl ErrorMsg
    echomsg printf('[vsnip] Parsing error occurred on: %s', a:path)
    echohl None
    echomsg string({ 'exception': v:exception, 'throwpint': v:throwpoint })
  endtry

  " @see https://github.com/microsoft/vscode/blob/0ba9f6631daec96a2b71eeb337e29f50dd21c7e1/src/vs/workbench/contrib/snippets/browser/snippetsFile.ts#L216
  let l:source = []
  for [l:key, l:value] in items(l:json)
    if s:is_snippet(l:value)
      call add(l:source, s:format_snippet(l:key, l:value))
    else
      for [l:key, l:value_] in items(l:value)
        if s:is_snippet(l:value_)
          call add(l:source, s:format_snippet(l:key, l:value_))
        endif
      endfor
    endif
  endfor
  return sort(l:source, { a, b -> strlen(b.prefix[0]) - strlen(a.prefix[0]) })
endfunction

"
" format_snippet
"
function! s:format_snippet(label, snippet) abort
  let [l:prefixes, l:prefixes_alias] = s:resolve_prefix(a:snippet.prefix)
  let l:description = get(a:snippet, 'description', '')

  return {
  \   'label': a:label,
  \   'prefix': l:prefixes,
  \   'prefix_alias': l:prefixes_alias,
  \   'body': type(a:snippet.body) == type([]) ? a:snippet.body : [a:snippet.body],
  \   'description': type(l:description) == type([]) ? join(l:description, '') :  l:description,
  \ }
endfunction

"
" is_snippet
"
function! s:is_snippet(snippet_or_source) abort
  return type(a:snippet_or_source) == type({}) && has_key(a:snippet_or_source, 'prefix') && has_key(a:snippet_or_source, 'body')
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
    if l:prefix =~# '^\h\w*\%(-\w\+\)\+$'
      call add(l:prefixes_alias, join(map(split(l:prefix, '-'), { i, v -> v[0] }), ''))
    endif
  endfor

  return [
  \   sort(l:prefixes, { a, b -> strlen(b) - strlen(a) }),
  \   sort(l:prefixes_alias, { a, b -> strlen(b) - strlen(a) })
  \ ]
endfunction

