"
" vsnip#snippet#node#variable#import
"
function! vsnip#snippet#node#variable#import() abort
  return s:Variable
endfunction

let s:Variable = {}

"
" new.
"
function! s:Variable.new(ast) abort
  let l:resolver = vsnip#variable#get(a:ast.name)
  return extend(deepcopy(s:Variable), {
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'unknown': empty(l:resolver),
  \   'resolver': l:resolver,
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })
endfunction

"
" text.
"
function! s:Variable.text() abort
  return self.resolve()
endfunction

"
" resolve.
"
function! s:Variable.resolve() abort
  if !self.unknown
    return self.resolver.func({ 'node': self })
  endif

  return join(map(copy(self.children), { k, v -> v.text() }), '')
endfunction

"
" to_string
"
function! s:Variable.to_string() abort
  return printf('%s(name=%s, unknown=%s, resolved=%s)',
  \   self.type,
  \   self.unknown ? 'true' : 'false',
  \   self.resolve()
  \ )
endfunction

