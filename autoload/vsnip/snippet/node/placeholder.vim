function! vsnip#snippet#node#placeholder#import() abort
  return s:Placeholder
endfunction

let s:Placeholder = {}

"
" new.
"
function! s:Placeholder.new(ast) abort
  return extend(deepcopy(s:Placeholder), {
        \   'type': 'placeholder',
        \   'ast': a:ast,
        \   'id': a:ast.id,
        \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', []))
        \ })
endfunction

"
" text.
"
function! s:Placeholder.text(snippet) abort
  return join(map(copy(self.children), { k, v -> v.text(a:snippet) }), '')
endfunction

