function! snips#expandable_or_jumpable()
  let l:target = snips#cursor#get_snippet_with_prefix(&filetype)
  return !empty(l:target) || snips#session#jumpable()
endfunction

function! snips#expand_or_jump()
  let l:target = snips#cursor#get_snippet_with_prefix(&filetype)
  if empty(l:target)
    if snips#session#jumpable()
      call snips#session#jump()
    endif
  else
    call snips#session#activate(l:target['prefix'], l:target['snippet'])
    call snips#session#expand()
  endif
endfunction

