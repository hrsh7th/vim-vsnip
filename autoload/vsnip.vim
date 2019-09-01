let s:session = {}

function! vsnip#get_session()
  return s:session
endfunction

"
" Select text.
"
function! vsnip#select(text)
  let g:vsnip#syntax#variable#selected_text = a:text
endfunction

"
" Check expandable.
"
function! vsnip#expandable()
  return s:expandable()
endfunction

"
" Check jumpable.
"
function! vsnip#jumpable()
  return s:jumpable()
endfunction

"
" Check jumpable.
"
function! vsnip#expandable_or_jumpable()
  return s:expandable() || s:jumpable()
endfunction

"
" Expand or Jump when available.
"
function! vsnip#expand_or_jump()
  let l:virtualedit = &virtualedit
  let l:lazyredraw = &lazyredraw
  let &virtualedit = 'onemore'
  let &lazyredraw = 1

  if s:expandable()
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

  if s:jumpable()
    call s:session.jump()
  endif

  let &virtualedit = l:virtualedit
  let &lazyredraw = l:lazyredraw
endfunction

function! s:expandable()
  return !empty(vsnip#snippet#get_snippet_with_prefix_under_cursor(&filetype))
endfunction

function! s:jumpable()
  return !empty(s:session) && s:session.jumpable()
endfunction

