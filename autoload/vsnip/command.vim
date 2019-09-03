let s:default = [
      \   '{',
      \   '  "Label": {',
      \   '    "body": [',
      \   '      ""',
      \   '    ],',
      \   '    "description": ""',
      \   '    "prefix": [""],',
      \   '  }',
      \   '}',
      \ ]

function! vsnip#command#prepare_for_edit(filetype)
  if empty(a:filetype)
    echomsg 'Please specify filetype.'
    return ''
  endif

  let l:filetype = vsnip#utils#inputlist('Select new snippet target: ', split(a:filetype, '\.'))
  if empty(l:filetype)
    echomsg 'Cenceled.'
    return ''
  endif

  if !isdirectory(g:vsnip_snippet_dir)
    call mkdir(g:vsnip_snippet_dir, 'p')
  endif

  let l:filepath = printf('%s/%s.json', g:vsnip_snippet_dir, l:filetype)
  if !filereadable(l:filepath)
    call writefile(s:default, l:filepath)
  endif

  return l:filepath
endfunction

