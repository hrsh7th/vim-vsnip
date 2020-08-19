let s:AbstractNode = vsnip#snippet#node#abstract_node#import()

function! vsnip#snippet#node#snippet#import() abort
  return s:Snippet
endfunction

let s:Snippet = deepcopy(s:AbstractNode)

function! s:Snippet.new(ast) abort
  return extend(deepcopy(s:Snippet), {
  \   'uid': vsnip#node_id(),
  \   'type': 'snippet',
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })
endfunction

