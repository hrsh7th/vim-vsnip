let s:AbstractNode = vsnip#snippet#node#abstract_node#import()

function! vsnip#snippet#node#snippet#import() abort
  return s:Snippet
endfunction

let s:Snippet = deepcopy(s:AbstractNode)

function! s:Snippet.new(ast) abort
  let l:node = extend(deepcopy(s:Snippet), {
  \   '_id': vsnip#snippet#node#id(),
  \   'type': 'snippet',
  \ })
  call l:node.replace_all(vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])))
  return l:node
endfunction
