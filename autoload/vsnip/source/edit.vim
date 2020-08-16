""
" vsnip#source#edit#snippet
""
fun! vsnip#source#edit#snippet(name) abort
  if executable('python')
    let s:pretty_print = '%!python -m json.tool'
  elseif executable('python3')
    let s:pretty_print = '%!python3 -m json.tool'
  else
    echo '[vsnip] no python executable found in $PATH'
    return
  endif

  let paths = vsnip#source#user_snippet#paths()
  if empty(paths)
    echo '[vsnip] no valid snippets json files found'
    return
  endif

  let s:name = a:name == '' ? input('Enter snippet name: ') : a:name
  if s:name !~ '^\p\+$'
    echo '[vsnip] invalid name'
    return
  endif

  let s:json_path = paths[0]
  let s:snippets = json_decode(readfile(s:json_path))
  call s:temp_buffer(&filetype)
endfun

""
" s:temp_buffer
""
fun! s:temp_buffer(ft) abort
  noautocmd keepalt new! Vsnip\ snippet
  exe 'setf' a:ft
  setlocal noexpandtab
  setlocal list
  setlocal buftype=acwrite
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  if has_key(s:snippets, s:name)
    call setline(1, s:snippets[s:name]['body'])
  endif
  call matchadd('PreProc', '\${.\{-}\%(:.\{-}\)\?}')
  call matchadd('PreProc', '\$[A-Z0-9_]\+')
  call matchadd('String', '\${.\{-}\zs:.\{-}\ze}')
  call matchadd('NonText', '\s\+')
  setlocal nomodified
  let &l:statusline = ' Editing snippet: %#CursorLine#  ' . s:name . '%=%#WarningMsg# (:w to save snippet) '
  autocmd BufWriteCmd <buffer> call s:save_snippet()
endfun

""
" s:save_snippet
""
fun! s:save_snippet() abort
  let lines = getline(1, line('$'))
  bwipeout!
  exe 'topleft vsplit' fnameescape(s:json_path)
  setf json
  if has_key(s:snippets, s:name)
    let s:snippets[s:name]['body'] = lines
    call s:update_snipptes_file()
  else
    call s:save_new_snippet(lines)
  endif
endfun

""
" s:update_snipptes_file
""
fun! s:update_snipptes_file() abort
  %d _
  put =json_encode(s:snippets)
  1d _
  exe s:pretty_print
  setlocal noexpandtab tabstop=4 softtabstop=4 shiftwidth=4
  retab!
  update
  call search('^\s*"' . s:name)
endfun

""
" s:save_new_snippet
""
fun! s:save_new_snippet(lines) abort
  let snip = {'body': a:lines}

  let desc = input('Enter a description: ')
  if desc !~ '^\p*$'
    echo '[vsnip] invalid description'
    let desc = 'invalid description'
  endif
  let prefix = input('Enter a prefix (no spaces): ')
  if prefix !~ '^\p*$'
    echo '[vsnip] invalid prefix'
    let prefix = split(s:name)[0]
  else
    let prefix = split(prefix)[0]
  endif

  let snip.description = desc
  let snip.prefix = [prefix]
  let s:snippets[s:name] = snip
  call s:update_snipptes_file()
endfun

