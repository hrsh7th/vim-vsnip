function! vsnip#session#snippet#node#placeholder#import() abort
  return s:Placeholder
endfunction

let s:Placeholder = {}

"
" new.
"
function! s:Placeholder.new(ast) abort
  return extend(deepcopy(s:Placeholder), {
  \   'type': 'placeholder',
  \   'id': a:ast.id,
  \   'follower': v:false,
  \   'choice': get(a:ast, 'choice', []),
  \   'children': vsnip#session#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })
endfunction

"
" text.
"
function! s:Placeholder.text() abort
  return join(map(copy(self.children), { k, v -> v.text() }), '')
endfunction

"
" to_string
"
function! s:Placeholder.to_string() abort
  return printf('%s(id=%s, follower=%s, choise=%s)',
  \   self.type,
  \   self.id,
  \   self.follower ? 'true' : 'false',
  \   self.choice
  \ )
endfunction
