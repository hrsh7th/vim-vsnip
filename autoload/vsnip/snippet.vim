let s:max_tabstop = 1000000

"
" import.
"
function! vsnip#snippet#import() abort
  return s:Snippet
endfunction

let s:Snippet = {}

"
" new.
"
function! s:Snippet.new(position, text) abort
  let l:snippet = extend(deepcopy(s:Snippet), {
  \   'type': 'snippet',
  \   'position': a:position,
  \   'children': vsnip#snippet#node#create_from_ast(
  \     vsnip#snippet#parser#parse(a:text)
  \   )
  \ })
  call l:snippet.init()
  call l:snippet.sync()
  return l:snippet
endfunction

"
" init.
"
function s:Snippet.init() abort
  let l:fn = {}
  let l:fn.self = self
  let l:fn.group = {}
  let l:fn.variable_placeholder = {}
  let l:fn.has_final_tabstop = v:false
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder'
      " Mark as follower placeholder.
      if !has_key(self.group, a:node.id)
        let self.group[a:node.id] = a:node
      else
        let a:node.follower = v:true
      endif

      " Mark as having final tabstop
      if a:node.is_final
        let self.has_final_tabstop = v:true
      endif
    elseif a:node.type ==# 'variable'
      " TODO refactor
      " variable placeholder
      if empty(a:node.resolver)
        let a:node.type = 'placeholder'
        let a:node.choice = []

        if !has_key(self.variable_placeholder, a:node.name)
          let self.variable_placeholder[a:node.name] = s:max_tabstop - (len(self.variable_placeholder) + 1)
          let a:node.id = self.variable_placeholder[a:node.name]
          let a:node.follower = v:false
          let a:node.children = empty(a:node.children) ? [vsnip#snippet#node#create_text(a:node.name)] : a:node.children
          let self.group[a:node.id] =  a:node
        else
          let a:node.id = self.variable_placeholder[a:node.name]
          let a:node.follower = v:true
          let a:node.children = [vsnip#snippet#node#create_text(self.group[a:node.id].text())]
        endif
      endif
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " Append ${MAX_TABSTOP} for the end of snippet.
  if !l:fn.has_final_tabstop
    let self.children += [vsnip#snippet#node#create_from_ast({
    \   'type': 'placeholder',
    \   'id': 0,
    \   'follower': v:false,
    \   'choice': [],
    \   'children': [{
    \     'type': 'text',
    \     'raw': '',
    \     'escaped': ''
    \   }]
    \ })]
  endif
endfunction

"
" follow.
"
function! s:Snippet.follow(current_tabstop, diff) abort
  let a:diff.range = [
  \   self.position_to_offset(a:diff.range.start),
  \   self.position_to_offset(a:diff.range.end),
  \ ]

  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.diff = a:diff
  let l:fn.target = v:null
  function! l:fn.traverse(range, node, parent, depth) abort
    " diff:     s-------e
    " text:   1-----------2
    " expect:       ^
    if a:range[0] <= self.diff.range[0] && self.diff.range[1] <= a:range[1]
      let l:should_update = v:false
      let l:should_update = l:should_update || empty(self.target)
      let l:should_update = l:should_update || a:node.type ==# 'placeholder'
      let l:should_update = l:should_update || self.target.node.type ==# 'text' && self.diff.range[0] == self.diff.range[1]
      if l:should_update
        let self.target = {
        \   'range': a:range,
        \   'node': a:node,
        \   'parent': a:parent,
        \ }
      endif
      " Stop traversing when acceptable node is current tabstop.
      return self.target.node.type ==# 'placeholder' && self.target.node.id == self.current_tabstop
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  let l:target = l:fn.target
  if empty(l:target)
    return v:false
  endif

  " Create patched new text.
  let l:start = a:diff.range[0] - l:target.range[0] - 1
  let l:end = a:diff.range[1] - l:target.range[0]
  let l:old_text = l:target.node.text()
  let l:new_text = ''
  let l:new_text .= l:start >= 0 ? strcharpart(l:old_text, 0, l:start + 1) : ''
  let l:new_text .= a:diff.text
  let l:new_text .= strcharpart(l:old_text, l:end, strchars(l:old_text) - l:end)

  " Apply patched new text.
  let l:node = l:target.node
  if l:node.type ==# 'placeholder'
    let l:node.children = [vsnip#snippet#node#create_text(l:new_text)]
  elseif l:node.type ==# 'variable'
    let l:index = index(l:target.parent.children, l:node)
    call remove(l:target.parent.children, l:index)
    call insert(l:target.parent.children, vsnip#snippet#node#create_text(l:new_text))
  else
    let l:node.value = l:new_text
  endif

  " Convert to text node when edited node is follower node.
  while !empty(l:node) && l:node.type !=# 'snippet'
    let l:parent = self.get_parent(l:node)
    if get(l:node, 'follower', v:false)
      let l:index = index(l:parent.children, l:node)
      call remove(l:parent.children, l:index)
      call insert(l:parent.children, vsnip#snippet#node#create_text(l:node.text()), l:index)
    endif
    let l:node = l:parent
  endwhile

  return v:true
endfunction

"
" sync.
"
function! s:Snippet.sync() abort
  let l:fn = {}
  let l:fn.self = self
  let l:fn.text = self.text()
  let l:fn.new_texts = {}
  let l:fn.text_edits = []
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder'
      if !has_key(self.new_texts, a:node.id)
        let self.new_texts[a:node.id] = a:node.text()
      else
        if a:node.text() !=# self.new_texts[a:node.id]
          call add(self.text_edits, {
          \   'node': a:node,
          \   'range': {
          \     'start': self.self.offset_to_position(a:range[0]),
          \     'end': self.self.offset_to_position(a:range[1]),
          \   },
          \   'newText': self.new_texts[a:node.id],
          \ })
        endif
      endif
    elseif a:node.type ==# 'variable' && a:node.should_resolve()
      let l:before = strcharpart(self.text, 0, a:range[0])
      let l:after = strcharpart(self.text, a:range[1], strchars(self.text) - a:range[1])
      call add(self.text_edits, {
      \   'node': a:node,
      \   'range': {
      \     'start': self.self.offset_to_position(a:range[0]),
      \     'end': self.self.offset_to_position(a:range[1]),
      \   },
      \   'newText': a:node.resolve({
      \     'node': a:node,
      \     'before': l:before,
      \     'after': l:after,
      \   }),
      \ })
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " Sync placeholder text after created text_edits (the reason is to avoid using a modified range).
  for l:text_edit in l:fn.text_edits
    let l:node = l:text_edit.node
    if l:node.type ==# 'placeholder'
      let l:node.children = [vsnip#snippet#node#create_text(l:text_edit.newText)]
    elseif l:node.type ==# 'variable'
      call l:node.update(l:text_edit.newText)
    endif
  endfor

  return l:fn.text_edits
endfunction

"
" range.
"
function! s:Snippet.range() abort
  return {
  \   'start': self.offset_to_position(0),
  \   'end': self.offset_to_position(strchars(self.text()))
  \ }
endfunction

"
" text.
"
function! s:Snippet.text() abort
  return join(map(copy(self.children), { k, v -> v.text() }), '')
endfunction

"
" get_placeholder_nodes
"
function! s:Snippet.get_placeholder_nodes() abort
  let l:fn =  {}
  let l:fn.nodes = []
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder'
      call add(self.nodes, a:node)
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  return sort(l:fn.nodes, { a, b -> a.id - b.id })
endfunction

"
" get_next_jump_point.
"
function! s:Snippet.get_next_jump_point(current_tabstop) abort
  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.self = self
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder' && self.current_tabstop < a:node.id
      if has_key(self, 'jump_point') && self.jump_point.placeholder.id <= a:node.id
        return v:false
      endif

      let self.jump_point = {
      \   'range': {
      \     'start': self.self.offset_to_position(a:range[0]),
      \     'end': self.self.offset_to_position(a:range[1]),
      \   },
      \   'placeholder': a:node
      \ }
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " can't detect next jump point.
  if !has_key(l:fn, 'jump_point')
    return {}
  endif

  return l:fn.jump_point
endfunction

"
" get_prev_jump_point.
"
function! s:Snippet.get_prev_jump_point(current_tabstop) abort
  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.self = self
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder' && self.current_tabstop > a:node.id
      if has_key(self, 'jump_point') && self.jump_point.placeholder.id >= a:node.id
        return v:false
      endif

      let self.jump_point = {
      \   'range': {
      \     'start': self.self.offset_to_position(a:range[0]),
      \     'end': self.self.offset_to_position(a:range[1]),
      \   },
      \   'placeholder': a:node
      \ }
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " can't detect next jump point.
  if !has_key(l:fn, 'jump_point')
    return {}
  endif

  return l:fn.jump_point
endfunction

"
" normalize
"
" - merge adjacent text-nodes
"
function! s:Snippet.normalize() abort
  let l:fn = {}
  let l:fn.text = v:null
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type !=# 'text'
      let self.text = v:null
      return
    endif

    if !empty(self.text) && self.text.depth == a:depth
      let self.text.node.value .= a:node.value
      call remove(a:parent.children, index(a:parent.children, a:node))
      return
    endif

    let self.text = {
    \   'range': a:range,
    \   'node': a:node,
    \   'parent': a:parent,
    \   'depth': a:depth,
    \ }
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)
endfunction

"
" insert_node
"
function! s:Snippet.insert_node(position, nodes_to_insert) abort
  let l:offset = self.position_to_offset(a:position)

  " Search target node for inserting nodes.
  let l:fn = {}
  let l:fn.offset = l:offset
  let l:fn.target = v:null
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:range[0] <= self.offset && self.offset <= a:range[1] && a:node.type ==# 'text'
      " prefer more deeper node.
      if empty(self.target) || self.target.depth <= a:depth
        let self.target = {
        \   'range': a:range,
        \   'node': a:node,
        \   'parent': a:parent,
        \   'depth': a:depth,
        \ }
      endif
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " This condition is unexpected normally
  let l:target = l:fn.target
  if empty(l:target)
    return
  endif

  " Remove target text node
  let l:idx = index(l:target.parent.children, l:target.node)
  call remove(l:target.parent.children, l:idx)

  " Should insert into existing text node when position is middle of node
  let l:nodes_to_insert = reverse(a:nodes_to_insert)
  if l:target.node.value !=# ''
    let l:off = l:offset - l:target.range[0]
    let l:before = vsnip#snippet#node#create_text(strcharpart(l:target.node.value, 0, l:off))
    let l:after = vsnip#snippet#node#create_text(strcharpart(l:target.node.value, l:off, strchars(l:target.node.value) - l:off))
    let l:nodes_to_insert = [l:after] + l:nodes_to_insert + [l:before]
  endif

  " Insert nodes.
  for l:node in l:nodes_to_insert
    call insert(l:target.parent.children, l:node, l:idx)
  endfor

  call self.normalize()
endfunction

"
" get_parent.
"
function! s:Snippet.get_parent(node) abort
  let l:fn = {}
  let l:fn.node = a:node
  let l:fn.parent = v:null
  function! l:fn.traverse(range, node, parent, depth) abort
    if self.node == a:node
      let self.parent = a:parent
      return v:true
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)
  return l:fn.parent
endfunction

"
" traverse.
"
function! s:Snippet.traverse(parent, children, callback, pos, depth) abort
  let l:pos = a:pos
  let l:skip = v:false
  let l:children = copy(a:children)
  for l:i in range(0, len(l:children) - 1)
    let l:node = l:children[l:i]
    let l:length = strchars(l:node.text())

    " child.
    let l:skip = a:callback([l:pos, l:pos + l:length], l:node, a:parent, a:depth)
    if l:skip
      return l:skip
    endif

    " child.children.
    if has_key(l:node, 'children') && len(l:node.children) > 0
      let l:skip = self.traverse(l:node, l:node.children, a:callback, l:pos, a:depth + 1)
      if l:skip
        return l:skip
      endif
    endif

    let l:pos += l:length
  endfor
  return l:skip
endfunction

"
" offset_to_position.
"
" @param offset 0-based index for snippet text.
" @return position buffer position
"
function! s:Snippet.offset_to_position(offset) abort
  let l:text = self.text()

  let l:line = 0
  let l:character = 0
  let l:offset = 0

  let l:i = 0
  while l:offset < min([a:offset, strchars(l:text)])
    let l:char = nr2char(strgetchar(l:text, l:i))
    if l:char ==# "\n"
      let l:line += 1
      let l:character = -1
    endif

    let l:width = strchars(l:char)
    let l:character += l:width
    let l:offset += l:width
    let l:i += 1
  endwhile

  return {
  \   'line': l:line + self.position.line,
  \   'character': l:line == 0 ? (self.position.character + l:character) : l:character
  \ }
endfunction

"
" position_to_offset.
"
" @param position buffer position
" @return 0-based index for snippet text.
"
function! s:Snippet.position_to_offset(position) abort
  let a:position.line -= self.position.line
  if a:position.line == 0
    let a:position.character -= self.position.character
  endif
  let l:lines = split(self.text(), "\n", v:true)

  let l:offset = 0
  let l:i = 0
  while l:i <= min([a:position.line, len(l:lines) - 1])
    if l:i != a:position.line
      let l:offset += strchars(l:lines[l:i]) + 1
    elseif l:i == a:position.line
      if a:position.character > 0
        let l:offset += strchars(strcharpart(l:lines[l:i], 0, a:position.character))
      endif
    endif

    let l:i += 1
  endwhile
  return l:offset
endfunction

"
" debug
"
function! s:Snippet.debug() abort
  echomsg 'snippet.text()'
  for l:line in split(self.text(), "\n", v:true)
    echomsg l:line
  endfor
  echomsg '-----'

  let l:fn = {}
  let l:fn.self = self
  function! l:fn.traverse(range, node, parent, depth) abort
    let l:level = ''
    let l:parent = a:parent
    while v:true
      if empty(l:parent)
        break
      endif
      let l:level .= '   '
      let l:parent = self.self.get_parent(l:parent)
    endwhile
    echomsg l:level . a:node.to_string()
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)
  echomsg ' '
endfunction
