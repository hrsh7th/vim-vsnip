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
      return s:normalize(json_decode(readfile(l:filepath)))
    endif
  endfor
  return s:normalize({})
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

