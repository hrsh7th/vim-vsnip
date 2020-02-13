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
function! vsnip#available(...) abort
  let l:direction = get(a:000, 0, 1)
  let l:expandable = !empty(vsnip#get_context())
  let l:jumpable = !empty(s:session) && s:session.jumpable(l:direction)
  return l:expandable || l:jumpable
endfunction

"
" vsnip#expand
"
function! vsnip#expand() abort
  let l:context = vsnip#get_context()
  if !empty(l:context)
    let l:line = line('.')
    let l:col = col('.')
    call vsnip#edits#text_edit#apply(bufnr('%'), [{
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

"
" vsnip#anonymous.
"
function! vsnip#anonymous(text) abort
  let s:session = s:Session.new(
        \   bufnr('%'),
        \   {
        \     'line': line('.') - 1,
        \     'character': col('.') - 1
        \   },
        \   a:text
        \ )
  call s:session.insert()
  call s:session.jump(1)
  call vsnip#selected_text('')
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
  let l:before_text = getline('.')[0 : col('.') - 2]
  for l:source in vsnip#source#find(&filetype)
    for l:snippet in l:source
      for l:prefix in (l:snippet.prefix + l:snippet.prefix_alias)
        let l:match = matchlist(l:before_text, printf('\%(\(\k\+\)\V%s\m\)\=\<\(\V%s\m\)\>$',
              \   escape(g:vsnip_auto_select_trigger, '\'),
              \   escape(l:prefix, '\'),
              \ ))

        " check match.
        if len(l:match) == 0 || l:match[3] ==# ''
          continue
        endif

        " check selected text.
        let l:length = strlen(l:prefix)
        if l:match[2] !=# ''
          let l:length += 1
          let l:length += strlen(l:match[2])
          call vsnip#selected_text(l:match[2])
        endif

        return {
              \   'length': l:length,
              \   'snippet': l:snippet
              \ }
      endfor
    endfor
  endfor

  return {}
endfunction

