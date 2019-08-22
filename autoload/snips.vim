function! snips#expandable()
  let l:target = snips#cursor#get_snippet_with_prefix(&filetype)
  return !empty(l:target)
endfunction

function! snips#expand()
  let l:target = snips#cursor#get_snippet_with_prefix(&filetype)
  if empty(l:target)
    return
  endif
  call snips#session#activate(l:target['prefix'], l:target['snippet'])
endfunction

