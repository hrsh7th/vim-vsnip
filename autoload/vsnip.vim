let s:session = {}

"
" Get current session.
"
function! vsnip#get_session() abort
  return s:session
endfunction

"
" Deactivate session.
"
function! vsnip#deactivate() abort
  let s:session = {}
endfunction

"
" Select text.
"
function! vsnip#select(text) abort
  let g:vsnip#syntax#variable#selected_text = a:text
endfunction

"
" Check expandable.
"
function! vsnip#expandable() abort
  return !empty(vsnip#snippet#get_snippet_with_prefix_under_cursor(&filetype))
endfunction

"
" Check jumpable.
"
function! vsnip#jumpable() abort
  return !empty(s:session) && s:session.jumpable()
endfunction

"
" Check jumpable.
"
function! vsnip#expandable_or_jumpable() abort
  return vsnip#expandable() || vsnip#jumpable()
endfunction

"
" Expand or Jump when available.
"
function! vsnip#expand_or_jump() abort
  let l:virtualedit = &virtualedit
  let l:lazyredraw = &lazyredraw
  let &virtualedit = 'onemore'
  let &lazyredraw = 1

  if vsnip#expandable()
    " remove prefix.
    let l:curpos = vsnip#utils#curpos()
    let l:target = vsnip#snippet#get_snippet_with_prefix_under_cursor(&filetype)
    call vsnip#utils#edit#replace_buffer({
          \   'start': [l:curpos[0], l:curpos[1] - strlen(l:target['prefix']) + 1],
          \   'end': [l:curpos[0], l:curpos[1] + 1]
          \ }, [''])

    " start & expand snippet.
    let s:session = vsnip#session#new(l:target['snippet'])
    call s:session.expand()

    " remove selected text.
    call vsnip#select('')
  endif

  if vsnip#jumpable()
    call s:session.jump()
  endif

  let &virtualedit = l:virtualedit
  let &lazyredraw = l:lazyredraw
endfunction

