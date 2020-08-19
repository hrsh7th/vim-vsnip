"
" vsnip#snippet#node#abstract_node#import
"
function! vsnip#snippet#node#abstract_node#import() abort
  return s:AbstractNode
endfunction

let s:AbstractNode = {
\   'parent': v:null,
\   'text_cache': v:null,
\ }

"
" text
"
function! s:AbstractNode.text() abort
  if self.cache isnot# v:null
    return self.cache
  endif
  let self.cache = join(map(copy(self.children), 'v:val.text()'), "\n")
  return self.cache
endfunction

"
" invalidate
"
function! s:AbstractNode.invalidate() abort
  let self.cache = v:null
  if self.parent isnot v:null
    call self.parent.invalidate()
  endif
endfunction

"
" replace_at
"
function! s:AbstractNode.replace_at(old_node, new_node) abort
  let l:idx = index(self.children, a:old_node)
  if l:idx >= 0
    call remove(self.children, l:idx)
    call insert(self.children, self.to_child(a:new_node), l:idx)
    call self.invalidate()
  endif
endfunction

"
" replace_all
"
function! s:AbstractNode.replace_all(children) abort
  let l:children = type(a:children) == type([]) ? a:children : [a:children]
  let l:children = map(l:children, 'self.to_child(v:val)')
  let self.children = l:children
  call self.invalidate()
endfunction

"
" to_child
"
function! s:AbstractNode.to_child(node) abort
  let a:node.parent = self
  return a:node
endfunction

