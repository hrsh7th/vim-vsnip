let s:AbstractNode = vsnip#snippet#node#abstract_node#import()

function! vsnip#snippet#node#text#import() abort
  return s:Text
endfunction

let s:Text = deepcopy(s:AbstractNode)

"
" new.
"
function! s:Text.new(ast) abort
  return extend(deepcopy(s:Text), {
  \   '_id': vsnip#snippet#node#id(),
  \   'type': 'text',
  \   'value': a:ast.escaped,
  \   'children': [],
  \ })
endfunction

"
" text.
"
function! s:Text.text() abort
  return self.value
endfunction

"
" insert.
"
function! s:Text.insert(...) abort
  throw 's:Text.insert: invalid call'
endfunction

"
" remove.
"
function! s:Text.remove(...) abort
  throw 's:Text.remove: invalid call'
endfunction

"
" replace.
"
function! s:Text.replace(...) abort
  throw 's:Text.replace: invalid call'
endfunction

"
" replace_all.
"
function! s:Text.replace_all(value) abort
  let l:value = a:value
  if type(a:value) != ''
    let l:value = a:value.text()
  endif
  let self.value = l:value
  call self.invalidate()
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
