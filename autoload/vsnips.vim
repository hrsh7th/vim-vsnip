let s:session = {}

function! vsnips#get_session()
  return s:session
endfunction

"
" Select text.
"
function! vsnips#selected_text(text)
  let g:vsnips#syntax#variable#selected_text = a:text
endfunction

"
" Check expandable.
"
function! vsnips#expandable()
  return s:expandable()
endfunction

"
" Check jumpable.
"
function! vsnips#jumpable()
  return s:jumpable()
endfunction

"
" Check jumpable.
"
function! vsnips#expandable_or_jumpable()
  return s:expandable() || s:jumpable()
endfunction

"
" Expand or Jump when available.
"
function! vsnips#expand_or_jump()
  let l:virtualedit = &virtualedit
  let &virtualedit = 'onemore'

  if s:expandable()
    " remove prefix.
    let l:curpos = vsnips#utils#curpos()
    let l:target = vsnips#snippet#get_snippet_with_prefix_under_cursor(&filetype)
    call vsnips#utils#edit#replace_buffer({
          \   'start': [l:curpos[0], l:curpos[1] - strlen(l:target['prefix']) + 1],
          \   'end': [l:curpos[0], l:curpos[1] + 1]
          \ }, [''])

    " start & expand snippet.
    let s:session = vsnips#session#new(l:target['snippet'])
    call s:session.expand()
  endif

  if s:jumpable()
    call s:session.jump()
  endif

  let &virtualedit = l:virtualedit
endfunction

function! s:expandable()
  return !empty(vsnips#snippet#get_snippet_with_prefix_under_cursor(&filetype))
endfunction

function! s:jumpable()
  return !empty(s:session) && s:session.jumpable()
endfunction

