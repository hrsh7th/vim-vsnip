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
  return !empty(vsnip#definition#get_snippet_with_prefix_under_cursor(&filetype))
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
" Start snippet.
"
function! vsnip#anonymous(body) abort
  let l:virtualedit = &virtualedit
  let l:lazyredraw = &lazyredraw
  let &virtualedit = 'onemore'

  " start & expand snippet.
  call cursor(vsnip#utils#curpos())
  let s:session = vsnip#session#new(vsnip#utils#curpos(), { 'body': a:body })
  call s:session.expand()
  call s:session.jump()

  " remove selected text.
  call vsnip#select('')

  let &virtualedit = l:virtualedit
  let &lazyredraw = l:lazyredraw
endfunction

"
" Expand or Jump when available.
"
function! vsnip#expand_or_jump() abort
  let l:virtualedit = &virtualedit
  let l:lazyredraw = &lazyredraw
  let &virtualedit = 'onemore'
  let &lazyredraw = 1

  if vsnip#jumpable()
    call s:session.jump()
  elseif vsnip#expandable()
    " remove prefix.
    let l:curpos = vsnip#utils#curpos()
    let l:target = vsnip#definition#get_snippet_with_prefix_under_cursor(&filetype)

    let l:start_position = [l:curpos[0], l:curpos[1] - strlen(l:target['prefix']) + 1]
    let l:end_position = [l:curpos[0], l:curpos[1] + 1]
    call vsnip#utils#edit#replace_buffer({
          \   'start': l:start_position,
          \   'end': l:end_position
          \ }, [''])

    " start & expand snippet.
    let s:session = vsnip#session#new(l:start_position, l:target['snippet'])
    call s:session.expand()
    call s:session.jump()

    " remove selected text.
    call vsnip#select('')
  endif

  let &virtualedit = l:virtualedit
  let &lazyredraw = l:lazyredraw
endfunction

