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
" Start snippet.
"
function! vsnip#anonymous(body) abort
  let l:virtualedit = &virtualedit
  let l:lazyredraw = &lazyredraw
  let &virtualedit = 'onemore'
  let &lazyredraw = 1

  let l:col_offset = 0
  if mode()[0] ==# 'i'
    stopinsert
    let l:col_offset = 1
  endif

  let l:fn = {}
  function! l:fn.next_tick(virtualedit, lazyredraw, col_offset, body) abort
    " start & expand snippet.
    call cursor([line('.'), col('.') + a:col_offset])
    let s:session = vsnip#session#new([line('.'), col('.')], { 'body': a:body })
    call s:session.expand()
    call s:session.jump()

    " remove selected text.
    call vsnip#select('')

    let &virtualedit = a:virtualedit
    let &lazyredraw = a:lazyredraw
  endfunction
  call timer_start(0, { -> l:fn.next_tick(l:virtualedit, l:lazyredraw, l:col_offset, a:body) }, { 'repeat': 1 })
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
    let l:target = vsnip#snippet#get_snippet_with_prefix_under_cursor(&filetype)

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

