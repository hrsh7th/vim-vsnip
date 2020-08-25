let s:uid = 0

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
  let s:uid += 1

  let l:resolver = vsnip#variable#get(a:ast.name)
  let l:arguments = vsnip#snippet#node#create_from_ast(get(a:ast, 'children', []))
  return extend(deepcopy(s:Variable), {
  \   'uid': s:uid,
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'unknown': empty(l:resolver),
  \   'resolved': join(map(copy(l:arguments), 'v:val.text()'), ''),
  \   'resolver': l:resolver,
  \   'children': [],
  \   'arguments': l:arguments,
  \ })
endfunction

"
" evaluate.
"
function! s:Variable.evaluate(origin_map) abort
  let l:arguments = []
  for l:argument in self.arguments
    if index(['placeholder', 'variable'], l:argument.type) >= 0
      call add(l:arguments, l:argument.evaluate(a:origin_map))
    else
      call add(l:arguments, l:argument.text())
    endif
  endfor
  return self.resolver.func({ 'node': self, 'arguments': l:arguments })
endfunction

"
" text.
"
function! s:Variable.text() abort
  return self.resolved
endfunction

"
" resolve.
"
function! s:Variable.resolve(resolved) abort
  let self.resolved = a:resolved
endfunction

"
" to_string
"
function! s:Variable.to_string() abort
  return printf('%s(name=%s, unknown=%s, text=%s)',
  \   self.type,
  \   self.name,
  \   self.unknown ? 'true' : 'false',
  \   self.text()
  \ )
endfunction

