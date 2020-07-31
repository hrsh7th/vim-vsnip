let s:max_tabstop = 1000000

function! vsnip#session#snippet#node#placeholder#import() abort
  return s:Placeholder
endfunction

let s:Placeholder = {}

"
" new.
"
function! s:Placeholder.new(ast) abort
  let l:node = extend(deepcopy(s:Placeholder), {
  \   'type': 'placeholder',
  \   'id': a:ast.id,
  \   'is_final': a:ast.id == 0,
  \   'follower': v:false,
  \   'choice': get(a:ast, 'choice', []),
  \   'children': vsnip#session#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })

  if l:node.is_final
    let l:node.id = s:max_tabstop
  endif

  if len(l:node.children) == 0
    let l:node.children = [vsnip#session#snippet#node#create_text('')]
  endif

  return l:node
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
  return printf('%s(id=%s, follower=%s, choise=%s)',
  \   self.type,
  \   self.id,
  \   self.follower ? 'true' : 'false',
  \   self.choice
  \ )
endfunction
