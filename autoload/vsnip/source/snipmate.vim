let s:cache = {}

function! vsnip#source#snipmate#refresh(path) abort
  if has_key(s:cache, a:path)
    unlet s:cache[a:path]
  endif
endfunction

function! vsnip#source#snipmate#find(bufnr) abort
  let filetypes = vsnip#source#filetypes(a:bufnr)
  return s:find(filetypes, a:bufnr)
endfunction

function! s:find(filetypes, bufnr) abort
  let sources = []
  for path in s:get_source_paths(a:filetypes, a:bufnr)
    if !has_key(s:cache, path)
      let s:cache[path] = s:create(path, a:bufnr)
    endif
    call add(sources, s:cache[path])
  endfor
  return sources
endfunction

function! s:get_source_paths(filetypes, bufnr) abort
  let paths = []
  for dir in s:get_source_dirs(a:bufnr)
    for filetype in a:filetypes
      let path = resolve(expand(printf('%s/%s.snippets', dir, filetype)))
      if has_key(s:cache, path) || filereadable(path)
        call add(paths, path)
      endif
    endfor
  endfor
  return paths
endfunction

function! s:get_source_dirs(bufnr) abort
  let dirs = []
  let buf_dir = getbufvar(a:bufnr, 'vsnip_snippet_dir', '')
  if buf_dir !=# ''
    let dirs += [buf_dir]
  endif
  let dirs += getbufvar(a:bufnr, 'vsnip_snippet_dirs', [])
  let dirs += [g:vsnip_snippet_dir]
  let dirs += g:vsnip_snippet_dirs
  return dirs
endfunction

function! s:create(path, bufnr) abort
  let file = readfile(a:path)
  let file = type(file) == v:t_list ? file : [file]
  call map(file, { _, f -> iconv(f, 'utf-8', &encoding) })
  let source = []
  let i = -1
  while i + 1 < len(file)
    let [i, line] = [i + 1, file[i + 1]]
    if line =~# '^\(#\|\s*$\)'
      " Comment, or blank line before snippets
    elseif line =~# '^extends\s\+\S'
      let filetypes = map(split(line[7:], ','), 'trim(v:val)')
      let source += flatten(s:find(filetypes, a:bufnr))
    elseif line =~# '^snippet\s\+\S' && i + 1 < len(file)
      let matched = matchlist(line, '^snippet\s\+\(\S\+\)\s*\(.*\)')
      let [prefix, description] = [matched[1], matched[2]]
      let body = []
      let indent = matchstr(file[i + 1], '^\s\+')
      while i + 1 < len(file) && file[i + 1] =~# '^\(' . indent . '\|\s*$\)'
        let [i, line] = [i + 1, file[i + 1]]
        call add(body, line[strlen(indent):])
      endwhile
      let [prefixes, prefixes_alias] = vsnip#source#resolve_prefix(prefix)
      call add(source, {
            \ 'label': prefix,
            \ 'prefix': prefixes,
            \ 'prefix_alias': prefixes_alias,
            \ 'body': body,
            \ 'description': description
            \ })
    else
      echohl ErrorMsg
      echomsg printf('[vsnip] Parsing error occurred on: %s#L%s', a:path, i + 1)
      echohl None
      break
    endif
  endwhile
  return sort(source, { a, b -> strlen(b.prefix[0]) - strlen(a.prefix[0]) })
endfunction
