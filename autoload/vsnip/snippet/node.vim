let s:Placeholder = vsnip#snippet#node#placeholder#import()
let s:Variable = vsnip#snippet#node#variable#import()
let s:Text = vsnip#snippet#node#text#import()
let s:Transform = vsnip#snippet#node#transform#import()

"
" vsnip#snippet#node#create_from_ast
"
function! vsnip#snippet#node#create_from_ast(ast) abort
  if type(a:ast) == type([])
    return map(a:ast, 'vsnip#snippet#node#create_from_ast(v:val)')
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

"
" vsnip#snippet#node#create_transform
"
function! vsnip#snippet#node#create_transform(transform) abort
  return s:Transform.new(a:transform)
endfunction
