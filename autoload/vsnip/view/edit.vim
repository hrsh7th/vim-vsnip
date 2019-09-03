let s:default = [
      \   '{',
      \   '  "Label": {',
      \   '    "prefix": [""],',
      \   '    "body": [',
      \   '      ""',
      \   '    ],',
      \   '    "description": ""',
      \   '  }',
      \   '}',
      \ ]

function! vsnip#view#edit#call(filetype)
  if empty(a:filetype)
    echomsg 'Please specify filetype.'
    return
  endif

  let l:filetype = vsnip#utils#inputlist('Select new snippet target: ', split(a:filetype, '\.'))
  if empty(l:filetype)
    echomsg 'Cenceled.'
    return
  endif

  call s:prepare()

  let l:filepath = printf('%s/%s.json', g:vsnip_snippet_dir, l:filetype)
  if !filereadable(l:filepath)
    call writefile(s:default, l:filepath)
  endif

  execute printf('vnew %s', l:filepath)
endfunction

function! s:prepare()
  if !isdirectory(g:vsnip_snippet_dir)
    call mkdir(g:vsnip_snippet_dir, 'p')
  endif
endfunction

