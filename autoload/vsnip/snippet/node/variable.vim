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
  \   'resolver': l:resolver,
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \   'transform': vsnip#snippet#node#create_transform(get(a:ast, 'transform')),
  \ })
endfunction

"
" text.
"
function! s:Variable.text() abort
  return self.transform.text(join(map(copy(self.children), 'v:val.text()'), ''))
endfunction

"
" resolve.
"
function! s:Variable.resolve(context) abort
  if !self.unknown
    let l:resolved = self.transform.text(self.resolver.func({ 'node': self }))
    if l:resolved isnot v:null
      " Fix indent when one variable returns multiple lines
      let l:base_indent = vsnip#indent#get_base_indent(split(a:context.before_text, "\n", v:true)[-1])
      return substitute(l:resolved, "\n\\zs", l:base_indent, 'g')
    endif
  endif
  return v:null
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

