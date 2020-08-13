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
  let l:node = extend(deepcopy(s:Variable), {
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'unknown': empty(l:resolver),
  \   'resolver': l:resolver,
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })

  function! l:node.unique()
  endfunction
  return l:node
endfunction

"
" text.
"
function! s:Variable.text() abort
  return join(map(copy(self.children), { k, v -> v.text() }), '')
endfunction

"
" resolve.
"
function! s:Variable.resolve(context) abort
  if !self.unknown
    let l:resolved = self.resolver.func({ 'node': self })
    if l:resolved isnot v:null
      " Fix indent when one variable returns multiple lines
      if !empty(get(a:context, 'prev_node', v:null))
        let l:base_indent = vsnip#indent#get_base_indent(split(a:context.prev_node.text(), "\n", v:true)[-1])
        let l:resolved = substitute(l:resolved, "\n\\zs", l:base_indent, 'g') " add base_indent for next all lines
      endif
      return l:resolved
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

