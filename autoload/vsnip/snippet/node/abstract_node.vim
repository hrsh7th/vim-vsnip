"
" vsnip#snippet#node#abstract_node#import
"
function! vsnip#snippet#node#abstract_node#import() abort
  return s:AbstractNode
endfunction

let s:AbstractNode = {
\   'parent': v:null,
\   'children': [],
\   'cache': {
\     'text': v:null,
\   },
\ }

"
" text
"
function! s:AbstractNode.text() abort
  if self.cache.text isnot# v:null
    return self.cache.text
  endif
  let self.cache.text = join(map(copy(self.children), 'v:val.text()'), '')
  return self.cache.text
endfunction

"
" invalidate
"
function! s:AbstractNode.invalidate() abort
  let self.cache.text = v:null
  if self.parent isnot v:null
    call self.parent.invalidate()
  endif
endfunction

"
" insert
"
function! s:AbstractNode.insert(node, idx) abort
  call insert(self.children, self.to_child(a:node), a:idx)
  call self.invalidate()
endfunction

"
" remove
"
function! s:AbstractNode.remove(node) abort
  call remove(self.children, a:node)
  call self.invalidate()
endfunction

"
" replace
"
function! s:AbstractNode.replace(old_node, new_node) abort
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
  let l:children = len(l:children) == 0 ? [vsnip#snippet#node#create_text('')] : l:children
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

"
" to_string
"
function! s:AbstractNode.to_string() abort
  throw 's:AbstractNode.to_string: invalid call'
endfunction

