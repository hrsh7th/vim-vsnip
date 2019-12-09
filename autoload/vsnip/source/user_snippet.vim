let s:cache = {}

"
" vsnip#source#user_snippet#find.
"
function! vsnip#source#user_snippet#find(filetype) abort
  let l:sources = []
  for l:path in s:get_source_paths(a:filetype)
    if !has_key(s:cache, l:path)
      let s:cache[l:path] = vsnip#source#create(l:path)
    endif
    call add(l:sources, s:cache[l:path])
  endfor
  return l:sources
endfunction

"
" vsnip#source#user_snippet#refresh.
"
function! vsnip#source#user_snippet#refresh(path) abort
  if has_key(s:cache, a:path)
    unlet s:cache[a:path]
  endif
endfunction

"
" get_source_paths.
"
function! s:get_source_paths(filetype) abort
  let l:paths = []
  for l:dir in [g:vsnip_snippet_dir] + g:vsnip_snippet_dirs
    for l:name in split(a:filetype, '\.') + ['global']
      let l:path = expand(printf('%s/%s.json', l:dir, l:name))
      if has_key(s:cache, l:path) || filereadable(l:path)
        call add(l:paths, l:path)
      endif
    endfor
  endfor
  return l:paths
endfunction

