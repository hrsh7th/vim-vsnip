let s:cache = {}

"
" vsnip#source#user_snippet#find.
"
function! vsnip#source#user_snippet#find(bufnr) abort
  let l:sources = []
  for l:path in s:get_source_paths(a:bufnr)
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

function! s:get_source_dirs(bufnr) abort
  let l:dirs = []
  let l:buf_dir = getbufvar(a:bufnr, 'vsnip_snippet_dir', v:null)
  if l:buf_dir isnot v:null
      let l:dirs += [l:buf_dir]
  endif
  let l:dirs += getbufvar(a:bufnr, 'vsnip_snippet_dirs', [])
  let l:dirs += [g:vsnip_snippet_dir]
  let l:dirs += g:vsnip_snippet_dirs
  return l:dirs
endfunction

"
" get_source_paths.
"
function! s:get_source_paths(bufnr) abort
  let l:filetypes = vsnip#source#filetypes(a:bufnr)

  let l:paths = []
  for l:dir in s:get_source_dirs(a:bufnr)
    for l:filetype in l:filetypes
      let l:path = resolve(expand(printf('%s/%s.json', l:dir, l:filetype)))
      if has_key(s:cache, l:path) || filereadable(l:path)
        call add(l:paths, l:path)
      endif
    endfor
  endfor
  return l:paths
endfunction

"
" vsnip#source#user_snippet#dirs
"
fun! vsnip#source#user_snippet#dirs(...) abort
  return s:get_source_dirs(a:0 ? a:1 : bufnr(''))
endfun

"
" vsnip#source#user_snippet#paths
"
fun! vsnip#source#user_snippet#paths(...) abort
  return s:get_source_paths(a:0 ? a:1 : bufnr(''))
endfun

