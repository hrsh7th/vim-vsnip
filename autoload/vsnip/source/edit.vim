""
" vsnip#source#edit#snippet
""
fun! vsnip#source#edit#snippet(name, bang) abort
  if executable('python')
    let s:pretty_print = '%!python -m json.tool'
  elseif executable('python3')
    let s:pretty_print = '%!python3 -m json.tool'
  else
    echo '[vsnip] no python executable found in $PATH'
    return
  endif

  let create_new_file = 0

  let paths = filter(vsnip#source#user_snippet#paths(), 'filereadable(v:val)')
  if a:bang
    call filter(paths, 'v:val !~ "global.json"')
  endif

  if empty(paths)
    echo '[vsnip] no valid snippets json files found'
    if !s:create_new_file(a:bang)
      return
    else
      let create_new_file = 1
    endif
  endif

  let s:name = a:name == '' ? input('Enter snippet name: ') : a:name
  if s:name !~ '^\p\+$'
    echo '[vsnip] invalid name'
    return
  endif

  if !create_new_file
    let s:json_path = s:get_path(paths)
    if !filereadable(s:json_path)
      redraw
      echo '[vsnip] invalid path'
      return
    endif
  endif

  let s:snippets = json_decode(readfile(s:json_path))
  call s:temp_buffer(&filetype)
endfun

""
" s:create_new_file
""
fun! s:create_new_file(bang)
  if confirm('Do you want to create a snippet file at `' . g:vsnip_snippet_dir . '`?', "&Yes\n&No") == 1
    let [type, ft, global] = ['', &filetype, 'global']
    if a:bang
      let type = ft
    else
      let ix = inputlist(['Select type: '] + map([ft, global], { k,v -> printf('%s: %s', k + 1, v) }))
      if ix && ix <= 2
        let type = [ft, global][ix - 1]
      endif
    endif
    if type == ''
      return v:false
    else
      if !isdirectory(g:vsnip_snippet_dir)
        if confirm('Create directory `' .g:vsnip_snippet_dir . '`?' , "&Yes\n&No") == 1
          call mkdir(expand(g:vsnip_snippet_dir), 'p')
        else
          return v:false
        endif
      endif
      let s:json_path = expand(g:vsnip_snippet_dir) . '/' . type . '.json'
      call writefile(['{}'], s:json_path)
      return v:true
    endif
  else
    return v:false
  endif
endfun

""
" s:get_path
""
fun! s:get_path(paths) abort
  if len(a:paths) > 1
    let choices = map(copy(a:paths), { k, v -> printf('%s: %s', k + 1, v) })
    let idx = inputlist(['Select snippet file: '] + choices)
  else
    let idx = 1
  endif
  if !idx
    return v:null
  else
    return a:paths[idx - 1]
  endif
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
  silent %d _
  put =json_encode(s:snippets)
  silent 1d _
  exe s:pretty_print
  setlocal noexpandtab tabstop=4 softtabstop=4 shiftwidth=4
  retab!
  call search('^\s*"' . s:name)
endfun

""
" s:save_new_snippet
""
fun! s:save_new_snippet(lines) abort
  redraw
  let snip = {'body': a:lines}

  let desc = input('Enter a description: ')
  if desc !~ '^\p\+$'
    redraw
    echo '[vsnip] using' s:name 'as description'
    let desc = s:name
  endif
  let prefix = input('Enter a prefix (no spaces): ')
  if prefix !~ '^\p\+$'
    redraw
    let prefix = split(s:name)[0]
    echo '[vsnip] using' prefix 'as prefix'
  else
    let prefix = split(prefix)[0]
  endif

  let snip.description = desc
  let snip.prefix = [prefix]
  let s:snippets[s:name] = snip
  call s:update_snipptes_file()
endfun

