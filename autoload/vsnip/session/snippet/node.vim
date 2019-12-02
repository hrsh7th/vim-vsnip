let s:Placeholder = vsnip#session#snippet#node#placeholder#import()
let s:Variable = vsnip#session#snippet#node#variable#import()
let s:Text = vsnip#session#snippet#node#text#import()

"
" vsnip#session#snippet#node#create_from_ast
"
function! vsnip#session#snippet#node#create_from_ast(ast) abort
  if type(a:ast) == type([])
    return map(a:ast, { k, v -> vsnip#session#snippet#node#create_from_ast(v) })
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
" vsnip#session#snippet#node#create_text
"
function! vsnip#session#snippet#node#create_text(text) abort
  return s:Text.new({
        \   'type': 'text',
        \   'raw': a:text,
        \   'escaped': a:text
        \ })
endfunction
