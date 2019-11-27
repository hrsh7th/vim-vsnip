function! vsnip#session#snippet#node#text#import() abort
  return s:Text
endfunction

let s:Text = {}

"
" new.
"
function! s:Text.new(ast) abort
  let l:text = extend(deepcopy(s:Text), {
        \   'type': 'text',
        \   'value': a:ast.escaped,
        \   'history': {},
        \ })
  let l:text[changenr() + 1] = a:ast.escaped
  return l:text
endfunction

"
" text.
"
function! s:Text.text() abort
  return self.value
endfunction

