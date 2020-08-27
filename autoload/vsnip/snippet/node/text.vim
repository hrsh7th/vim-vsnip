let s:uid = 0

function! vsnip#snippet#node#text#import() abort
  return s:Text
endfunction

let s:Text = {}

"
" new.
"
function! s:Text.new(ast) abort
  let s:uid += 1

  return extend(deepcopy(s:Text), {
  \   'uid': s:uid,
  \   'type': 'text',
  \   'value': a:ast.escaped,
  \   'children': [],
  \ })
endfunction

"
" evaluate
"
function! s:Text.evaluate(context) abort
  return self.value
endfunction

"
" resolved
"
function! s:Text.resolve(resolved) abort
  let self.value = a:resolved
endfunction

"
" text.
"
function! s:Text.text() abort
  return self.value
endfunction

"
" to_string
"
function! s:Text.to_string() abort
  return printf('%s(%s)',
  \   self.type,
  \   self.value
  \ )
endfunction
