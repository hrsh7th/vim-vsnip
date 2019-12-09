let s:snippets = {}
let s:runtimepaths = {}

"
" vsnip#source#vscode#refresh.
"
function! vsnip#source#vscode#refresh(path) abort
  if has_key(s:snippets, a:path)
    unlet s:snippets[a:path]

    for [l:rtp, l:v] in items(s:runtimepaths)
      if stridx(l:rtp, a:path) == 0
        unlet s:runtimepaths[l:rtp]
      endif
    endfor
  endif
endfunction

"
" vsnip#source#vscode#find.
"
function! vsnip#source#vscode#find(filetype) abort
  return s:find(s:get_language(a:filetype))
endfunction

"
" find.
"
function! s:find(language) abort
  let l:sources = []

  " load from `package.json#contributes.snippets`.
  for l:rtp in split(&runtimepath, ',')
    if has_key(s:runtimepaths, l:rtp)
      continue
    endif
    let s:runtimepaths[l:rtp] = v:true

    try
      let l:package_json = readfile(resolve(l:rtp . '/package.json'))
      let l:package_json = type(l:package_json) == type([]) ? join(l:package_json, "\n") : l:package_json
      let l:package_json = iconv(l:package_json, 'utf-8', &encoding)
      let l:package_json = json_decode(l:package_json)

      " if package.json has not `contributes.snippets` fields, skip it.
      if !has_key(l:package_json, 'contibutes')
            \ || !has_key(l:package_json.contributes, 'snippets')
        continue
      endif

      " create source.
      for l:snippet in l:package_json.contributes.snippets
        let l:path = resolve(l:rtp . '/' . l:snippet.path)

        " if already cached `snippets.json`, skip it.
        if has_key(s:snippets, l:path)
          continue
        endif

        let s:snippets[l:path] = {
              \   'languages': l:snippet.language,
              \   'source': vsnip#source#create()
              \ }
      endfor
    catch /.*/
    endtry
  endfor

  " filter by language.
  let l:sources = []
  for [l:path, l:snippet] in items(s:snippets)
    if index(l:snippet.languages, a:language) >= 0
      call add(l:sources, l:snippet.source)
    endif
  endfor
  return l:sources
endfunction

"
" get_language_id.
"
function! s:get_language(filetype) abort
  return get({
        \   'javascript.jsx': 'javascriptreact',
        \   'typescript.tsx': 'typescriptreact',
        \ }, a:filetype, a:filetype)
endfunction

