let s:AbstractNode = vsnip#snippet#node#abstract_node#import()

let s:max_tabstop = 1000000

function! vsnip#snippet#node#placeholder#import() abort
  return s:Placeholder
endfunction

let s:Placeholder = deepcopy(s:AbstractNode)

"
" new.
"
function! s:Placeholder.new(ast) abort
  let l:node = extend(deepcopy(s:Placeholder), {
  \   '_id': vsnip#snippet#node#id(),
  \   'type': 'placeholder',
  \   'id': a:ast.id == 0 ? s:max_tabstop : a:ast.id,
  \   'is_final': a:ast.id == 0,
  \   'follower': v:false,
  \   'choice': get(a:ast, 'choice', []),
  \ })
  call l:node.replace_all(vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])))
  return l:node
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

