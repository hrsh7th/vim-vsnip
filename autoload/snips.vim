let s:session = {}

function! snips#expandable_or_jumpable()
  return s:expandable() || s:jumpable()
endfunction

function! snips#expand_or_jump()
  if s:expandable()
    let l:target = snips#cursor#get_snippet_with_prefix(&filetype)
    let s:session = snips#session#activate(l:target['prefix'], l:target['snippet'])
    call s:session.expand()
    call s:session.jump()
  elseif s:jumpable()
    call s:session.jump()
  endif
endfunction

function! s:expandable()
  return !empty(snips#cursor#get_snippet_with_prefix(&filetype))
endfunction

function! s:jumpable()
  return !empty(s:session) && s:session.jumpable()
endfunction

