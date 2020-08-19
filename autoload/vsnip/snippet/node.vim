let s:Snippet = vsnip#snippet#node#snippet#import()
let s:Placeholder = vsnip#snippet#node#placeholder#import()
let s:Variable = vsnip#snippet#node#variable#import()
let s:Text = vsnip#snippet#node#text#import()

let s:id = 0

"
" vsnip#snippet#node#id
"
function! vsnip#snippet#node#id() abort
  let s:id += 1
  return s:id
endfunction

"
" vsnip#snippet#node#create_from_ast
"
function! vsnip#snippet#node#create_from_ast(ast) abort
  if type(a:ast) == type([])
    return map(a:ast, 'vsnip#snippet#node#create_from_ast(v:val)')
  endif

  if a:ast.type ==# 'snippet'
    return s:Snippet.new(a:ast)
  endif
  if a:ast.type ==# 'placeholder'
    return s:Placeholder.new(a:ast)
  endif
  if a:ast.type ==# 'variable'
    return s:Variable.new(a:ast)
  endif
  if a:ast.type ==# 'text'
    return s:Text.new(a:ast)
  endif

  throw 'vsnip: invalid node type'
endfunction

"
" vsnip#snippet#node#create_text
"
function! vsnip#snippet#node#create_text(text) abort
  return s:Text.new({
  \   'type': 'text',
  \   'raw': a:text,
  \   'escaped': a:text
  \ })
endfunction
