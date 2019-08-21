let g:snips#snippet#dir = expand('<sfile>:p:h') . '/../../snippet'

let s:cache = {}

function! snips#snippet#get_definition(filetype)
  call s:cache(a:filetype)
  if has_key(s:cache, a:filetype)
    return s:cache[a:filetype]
  endif
  return {}
endfunction

function! s:cache(filetype)
  if has_key(s:cache, a:filetype)
    return
  endif

  let l:filepath = printf('%s/%s.json', g:snips#snippet#dir, a:filetype)
  echomsg string(l:filepath)
  if filereadable(l:filepath)
    let s:cache[a:filetype] = s:normalize(json_decode(readfile(l:filepath)))
  else
    let s:cache[a:filetype] = s:normalize({})
  endif
endfunction

function! s:normalize(snippets)
  let l:normalized = { 'index': {}, 'snippets': [] }
  for [l:label, l:snippet] in items(a:snippets)
    let l:snippet['prefix'] = s:to_list(l:snippet['prefix'])
    let l:snippet['body'] = s:to_list(l:snippet['body'])
    for l:prefix in l:snippet['prefix']
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

