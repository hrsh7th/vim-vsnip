let s:Session = vsnip#session#import()
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
function! vsnip#available() abort
  return !empty(s:session) || !empty(s:get_context())
endfunction

"
" vsnip#anonymous.
"
function! vsnip#anonymous(text) abort
  let s:session = s:Session.new(
        \   bufnr('%'),
        \   lamp#protocol#position#get(),
        \   a:text
        \ )
  call s:session.insert()
  call s:session.jump()
  call vsnip#selected_text('')
endfunction

"
" vsnip#expand
"
function! vsnip#expand() abort
  let l:context = s:get_context()
  if !empty(l:context)
    let l:line = line('.')
    let l:col = col('.')
    call lamp#view#edit#apply(bufnr('%'), [{
          \   'range': {
          \     'start': {
          \       'line': l:line - 1,
          \       'character': l:col - 1 - l:context.length
          \     },
          \     'end': {
          \       'line': l:line - 1,
          \       'character': l:col - 1
          \     }
          \   },
          \   'newText': ''
          \ }])
    call cursor(l:line, l:col - l:context.length)
    call vsnip#anonymous(join(l:context.snippet.body, "\n"))
  endif
endfunction

function! vsnip#jump() abort
  if !empty(s:session)
    call s:session.jump()
  endif
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
  call lamp#view#notice#add({ 'lines': ['`Snippet`: session deactivated.'] })
  let s:session = {}
endfunction

"
" get_context.
"
function! s:get_context() abort
  let l:length = -1
  let l:before_text = getline('.')[0 : col('.') - 2]
  for l:source in vsnip#source#find(&filetype)
    for [l:label, l:snippet] in items(l:source)
      for l:prefix in l:snippet.prefix
        let l:match = matchlist(l:before_text, printf('\<\(\V%s\m\)\>\%(\V%s\m\<\(%s\)\>\)\?$',
              \   l:prefix,
              \   g:vsnip_select_trigger,
              \   g:vsnip_select_pattern
              \ ))
        if len(l:match) > 0 && l:match[1] !=# ''
          let l:length = strlen(l:match[1])
          if l:match[2] !=# ''
            let l:length += strlen(g:vsnip_select_trigger)
            let l:length += strlen(l:match[2])
            call vsnip#selected_text(l:match[2])
            break
          endif
        endif
      endfor
      if l:length != -1
        break
      endif
    endfor
    if l:length != -1
      break
    endif
  endfor

  if l:length != -1
    return {
          \   'length': l:length,
          \   'snippet': l:snippet
          \ }
  endif
  return {}
endfunction
