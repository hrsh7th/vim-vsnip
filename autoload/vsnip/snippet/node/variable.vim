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
  return extend(deepcopy(s:Variable), {
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'value': '',
  \   'resolved': v:false,
  \   'resolver': vsnip#variable#get(a:ast.name),
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })
endfunction

"
" text.
"
function! s:Variable.text() abort
  if empty(self.resolver)
    return join(map(copy(self.children), { k, v -> v.text() }), '')
  endif
  return self.value
endfunction

"
" should_resolve.
"
function! s:Variable.should_resolve() abort
  return !empty(self.resolver) && !(self.resolver.once && self.resolved)
endfunction

"
" update.
"
function! s:Variable.update(value) abort
  let self.value = a:value
  let self.resolved = v:true
endfunction

"
" resolve.
"
function! s:Variable.resolve(context) abort
  if !empty(self.resolver)
    let l:value = self.resolver.func(a:context)
    if !empty(l:value)
      return l:value
    endif
  endif
  return v:null
endfunction

"
" to_string
"
function! s:Variable.to_string() abort
  return printf('%s(name=%s, unknown=%s, resolved=%s)',
  \   self.type,
  \   self.name,
  \   empty(self.resolver) ? 'true' : 'false',
  \   self.value
  \ )
endfunction

