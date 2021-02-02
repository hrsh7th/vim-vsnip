let s:Session = vsnip#session#import()
let s:Snippet = vsnip#snippet#import()
let s:TextEdit = vital#vsnip#import('VS.LSP.TextEdit')
let s:Position = vital#vsnip#import('VS.LSP.Position')

let s:session = v:null
let s:selected_text = ''

"
" vsnip#selected_text.
"
function! vsnip#selected_text(...) abort
  if len(a:000) == 1
    let s:selected_text = a:000[0]
  else
    return s:selected_text
  endif
endfunction

"
" vsnip#available.
"
function! vsnip#available(...) abort
  let l:direction = get(a:000, 0, 1)
  return vsnip#expandable() || vsnip#jumpable(l:direction)
endfunction

"
" vsnip#expandable.
"
function! vsnip#expandable() abort
  return !empty(vsnip#get_context())
endfunction

"
" vsnip#jumpable.
"
function! vsnip#jumpable(...) abort
  let l:direction = get(a:000, 0, 1)
  return !empty(s:session) && s:session.jumpable(l:direction)
endfunction

"
" vsnip#expand
"
function! vsnip#expand() abort
  let l:context = vsnip#get_context()
  if !empty(l:context)
    call s:TextEdit.apply(bufnr('%'), [{
    \   'range': l:context.range,
    \   'newText': ''
    \ }])
    call vsnip#anonymous(join(l:context.snippet.body, "\n"), {
    \   'position': l:context.range.start
    \ })
  endif
endfunction

"
" vsnip#anonymous.
"
function! vsnip#anonymous(text, ...) abort
  let l:option = get(a:000, 0, {})
  let l:prefix = get(l:option, 'prefix', v:null)
  let l:position = get(l:option, 'position', s:Position.cursor())

  if l:prefix isnot# v:null
    let l:position.character -= strchars(l:prefix)
    call s:TextEdit.apply(bufnr('%'), [{
    \   'range': {
    \     'start': l:position,
    \     'end': {
    \       'line': l:position.line,
    \       'character': l:position.character + strchars(l:prefix),
    \     },
    \   },
    \   'newText': ''
    \ }])
  endif

  let l:session = s:Session.new(bufnr('%'), l:position, a:text)

  call vsnip#selected_text('')

  if !empty(s:session)
    call s:session.flush_changes() " try to sync buffer content because vsnip#expand maybe remove prefix
  endif

  if empty(s:session)
    let s:session = l:session
    call s:session.expand()
  else
    call s:session.merge(l:session)
  endif

  doautocmd <nomodeline> User vsnip#expand

  call s:session.refresh()
  call s:session.jump(1)
endfunction

"
" vsnip#get_session
"
function! vsnip#get_session() abort
  return s:session
endfunction

"
" vsnip#deactivate
"
function! vsnip#deactivate() abort
  let s:session = {}
endfunction

"
" get_context.
"
function! vsnip#get_context() abort
  let l:offset = mode()[0] ==# 'i' ? 2 : 1
  let l:before_text = getline('.')[0 : col('.') - l:offset]
  let l:before_text_len = strchars(l:before_text)

  if l:before_text_len == 0
    return {}
  endif

  let l:sources = vsnip#source#find(bufnr('%'))

  " Search prefix
  for l:source in l:sources
    for l:snippet in l:source
      for l:prefix in l:snippet.prefix
        let l:prefix_len = strchars(l:prefix)
        if strcharpart(l:before_text, l:before_text_len - l:prefix_len, l:prefix_len) !=# l:prefix
          continue
        endif
        if l:prefix =~# '^\h' && l:before_text !~# '\<\V' . escape(l:prefix, '\/?') . '\m$'
          continue
        endif
        return s:create_context(l:snippet, l:before_text_len, l:prefix_len)
      endfor
    endfor
  endfor

  " Search prefix-alias
  for l:source in l:sources
    for l:snippet in l:source
      for l:prefix in l:snippet.prefix_alias
        let l:prefix_len = strchars(l:prefix)
        if strcharpart(l:before_text, l:before_text_len - l:prefix_len, l:prefix_len) !=# l:prefix
          continue
        endif
        if l:prefix =~# '^\h' && l:before_text !~# '\<\V' . escape(l:prefix, '\/?') . '\m$'
          continue
        endif
        return s:create_context(l:snippet, l:before_text_len, l:prefix_len)
      endfor
    endfor
  endfor

  return {}
endfunction

"
" vsnip#get_complete_items
"
function! vsnip#get_complete_items(bufnr) abort
  let l:uniq = {}
  let l:candidates = []

  for l:source in vsnip#source#find(a:bufnr)
    for l:snippet in l:source
      for l:prefix in l:snippet.prefix
        if has_key(l:uniq, l:prefix)
          continue
        endif
        let l:uniq[l:prefix] = v:true

        let l:menu = ''
        let l:menu .= '[v]'
        let l:menu .= ' '
        let l:menu .= (strlen(l:snippet.description) > 0 ? l:snippet.description : l:snippet.label)

        call add(l:candidates, {
        \   'word': l:prefix,
        \   'abbr': l:prefix,
        \   'kind': 'Snippet',
        \   'menu': l:menu,
        \   'dup': 1,
        \   'user_data': json_encode({
        \     'vsnip': {
        \       'snippet': l:snippet.body
        \     }
        \   })
        \ })
      endfor
    endfor
  endfor

  return l:candidates
endfunction

"
" vsnip#decode
"
function! vsnip#to_string(text) abort
  let l:text = type(a:text) == type([]) ? join(a:text, "\n") : a:text
  return s:Snippet.new(s:Position.cursor(), l:text).text()
endfunction

"
" vsnip#debug
"
function! vsnip#debug() abort
  if !empty(s:session)
    call s:session.snippet.debug()
  endif
endfunction

"
" create_context
"
function! s:create_context(snippet, before_text_len, prefix_len) abort
  let l:line = line('.') - 1
  return {
  \   'range': {
  \     'start': {
  \       'line': l:line,
  \       'character': a:before_text_len - a:prefix_len
  \     },
  \     'end': {
  \       'line': l:line,
  \       'character': a:before_text_len
  \     }
  \   },
  \   'snippet': a:snippet
  \ }
endfunction
