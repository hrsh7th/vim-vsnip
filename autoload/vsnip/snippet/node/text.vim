function! vsnip#snippet#node#text#import() abort
  return s:Text
endfunction

let s:Text = {}

"
" new.
"
function! s:Text.new(ast) abort
  let l:node = extend(deepcopy(s:Text), {
  \   'type': 'text',
  \   'value': a:ast.escaped,
  \ })

  function! l:node.unique()
  endfunction
  return l:node
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
