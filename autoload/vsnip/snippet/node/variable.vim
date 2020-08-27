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

  return extend(deepcopy(s:Variable), {
  \   'uid': s:uid,
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'unknown': !vsnip#variable#has(a:ast.name),
  \   'resolver': vsnip#variable#get(a:ast.name),
  \   'resolved': v:null,
  \   'arguments': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \   'children': [],
  \ })
endfunction

"
" evaluate.
"
function! s:Variable.evaluate(context) abort
  let l:resolved = self.resolved

  if (self.unknown || self.resolver.once) && self.resolved isnot# v:null
    return self.resolved
  endif

  if self.unknown
    let l:resolved = len(self.arguments) > 0 ? join(map(copy(self.arguments), 'v:val.text()'), '') : self.name
  else
    let l:arguments = map(copy(self.arguments), 'v:val.evaluate(a:context)')
    let l:resolved = self.resolver.func(a:context, l:arguments)
    let l:resolved = l:resolved isnot# v:null ? l:resolved : self.resolved
    let l:resolved = l:resolved isnot# v:null ? l:resolved : join(map(copy(self.arguments), 'v:val.text()'), '')
  endif

  if l:resolved isnot# v:null
    let l:base_indent = vsnip#indent#get_base_indent(split(a:context.before_text, "\n", v:true)[-1])
    let l:resolved = substitute(l:resolved, "\n\\zs", l:base_indent, 'g')
  endif
  return l:resolved
endfunction

"
" resolve.
"
function! s:Variable.resolve(resolved) abort
  let self.resolved = a:resolved
endfunction

"
" text.
"
function! s:Variable.text() abort
  return self.resolved isnot# v:null ? self.resolved : ''
endfunction

"
" to_string
"
function! s:Variable.to_string() abort
  return printf('%s(name=%s, unknown=%s, arguments=%s, text=%s)',
  \   self.type,
  \   self.name,
  \   self.unknown ? 'true' : 'false',
  \   map(copy(self.arguments), 'v:val.to_string()'),
  \   self.text()
  \ )
endfunction

