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
  return extend(deepcopy(s:Variable), {
  \   'uid': s:uid,
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'unknown': empty(l:resolver),
  \   'resolved': v:null,
  \   'resolver': l:resolver,
  \   'children': [],
  \   'arguments': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })
endfunction

"
" evaluate.
"
function! s:Variable.evaluate(context) abort
  let l:resolved = self.resolved

  if !(self.resolver.once && self.resolved isnot# v:null)
    let l:arguments = []
    for l:argument in self.arguments
      if index(['placeholder', 'variable'], l:argument.type) >= 0
        call add(l:arguments, l:argument.evaluate(a:context))
      else
        call add(l:arguments, l:argument.text())
      endif
    endfor
    let l:resolved = self.resolver.func(a:context, l:arguments)
    let l:resolved = l:resolved isnot# v:null ? l:resolved : join(l:arguments, '')
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
  if self.unknown
    return len(self.arguments) > 0 ? join(map(copy(self.arguments), 'v:val.text()'), '') : self.name
  endif
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

