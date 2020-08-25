let s:max_tabstop = 1000000
let s:uid = 0

function! vsnip#snippet#node#placeholder#import() abort
  return s:Placeholder
endfunction

let s:Placeholder = {}

"
" new.
"
function! s:Placeholder.new(ast) abort
  let s:uid += 1

  let l:node = extend(deepcopy(s:Placeholder), {
  \   'uid': s:uid,
  \   'type': 'placeholder',
  \   'id': a:ast.id,
  \   'is_final': a:ast.id == 0,
  \   'origin': v:false,
  \   'choice': get(a:ast, 'choice', []),
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })

  if l:node.is_final
    let l:node.id = s:max_tabstop
  endif

  if len(l:node.children) == 0
    let l:node.children = [vsnip#snippet#node#create_text('')]
  endif

  return l:node
endfunction

"
" evaluate
"
function! s:Placeholder.evaluate(origin_map) abort
  if self.origin
    return self.text()
  endif
  return a:origin_map[self.id].text()
endfunction

"
" resolved
"
function! s:Placeholder.resolve(resolved) abort
  if self.origin
    return
  endif
  let self.children = [vsnip#snippet#node#create_text(a:resolved)]
endfunction

"
" text.
"
function! s:Placeholder.text() abort
  return join(map(copy(self.children), 'v:val.text()'), '')
endfunction

"
" to_string
"
function! s:Placeholder.to_string() abort
  return printf('%s(id=%s, origin=%s, choise=%s)',
  \   self.type,
  \   self.id,
  \   self.origin ? 'true' : 'false',
  \   self.choice
  \ )
endfunction

