let s:default = [
      \   '{',
      \   '  "key": {',
      \   '    "body": [',
      \   '      ""',
      \   '    ],',
      \   '    "description": "",',
      \   '    "prefix": [""]',
      \   '  }',
      \   '}',
      \ ]

function! vsnip#command#prepare_for_edit(filetype) abort
  if empty(a:filetype)
    echomsg 'Please specify filetype.'
    return ''
  endif

  let l:filepaths = vsnip#definition#get_filepaths(a:filetype)
  let l:filetype = vsnip#utils#inputlist('Select snippet file: ', split(a:filetype, '\.') + ['global'])
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

