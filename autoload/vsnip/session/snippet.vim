let s:max_tabstop = 1000000

"
" import.
"
function! vsnip#session#snippet#import() abort
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
  \   'children': vsnip#session#snippet#node#create_from_ast(
  \     vsnip#session#snippet#parser#parse(a:text)
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
  let l:fn.found_final_tabstop = v:false
  let l:fn.group = {}
  let l:fn.sync_targets = []
  let l:fn.variable_placeholder = {}
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder'
      " append text node when placeholder has no children.
      if len(a:node.children) == 0
        let a:node.children = [vsnip#session#snippet#node#create_text('')]
      endif

      " sync same tabstop placeholders.
      if !has_key(self.group, a:node.id)
        let self.group[a:node.id] = a:node
      else
        let a:node.follower = v:true
      endif

      " fix 0-tabstop to max tabstop.
      if a:node.id == 0
        let a:node.id = s:max_tabstop
      endif

      let self.found_final_tabstop = self.found_final_tabstop || a:node.id == s:max_tabstop
    elseif a:node.type ==# 'variable'
      " variable placeholder
      if a:node.unknown
        let a:node.type = 'placeholder'
        let a:node.choice = []

        if !has_key(self.variable_placeholder, a:node.name)
          let self.variable_placeholder[a:node.name] = s:max_tabstop - (len(self.variable_placeholder) + 1)
          let a:node.id = self.variable_placeholder[a:node.name]
          let a:node.follower = v:false
          let a:node.children = empty(a:node.children) ?
          \ [vsnip#session#snippet#node#create_text(a:node.name)] :
          \ a:node.children
          let self.group[a:node.id] =  a:node
        else
          let a:node.id = self.variable_placeholder[a:node.name]
          let a:node.follower = v:true
          let a:node.children = [vsnip#session#snippet#node#create_text(self.group[a:node.id].text())]
        endif
      else
        let l:index = index(a:parent.children, a:node)
        call remove(a:parent.children, l:index)
        call insert(a:parent.children, vsnip#session#snippet#node#create_text(a:node.text()), l:index)
      endif
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " add 0 tabstop to end of snippet if has no 0 tabstop.
  if !l:fn.found_final_tabstop
    let self.children += [vsnip#session#snippet#node#create_from_ast({
    \   'type': 'placeholder',
    \   'id': s:max_tabstop,
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
      let self.target = {
      \   'range': a:range,
      \   'node': a:node,
      \   'parent': a:parent,
      \ }
      " Stop traversing when acceptable node is current tabstop.
      return a:node.type ==# 'placeholder' && a:node.id == self.current_tabstop
    endif

    return v:false
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  if empty(l:fn.target)
    return v:false
  endif

  let l:target = l:fn.target

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
    let l:node.children = [vsnip#session#snippet#node#create_text(l:new_text)]
  else
    let l:node.value = l:new_text
  endif

  " Convert to text node when edited node is follower node.
  while !empty(l:node)
    let l:parent = self.get_parent(l:node)
    if get(l:node, 'follower', v:false)
      let l:index = index(l:parent.children, l:node)
      call remove(l:parent.children, l:index)
      call insert(l:parent.children, vsnip#session#snippet#node#create_text(l:node.text()), l:index)
    endif
    let l:node = l:parent
  endwhile

  return v:true
endfunction

"
" sync.
"
" # placeholders.
" LSP spec says, multiple placeholders can has same tabstops.
" If the placeholders has multiple candidate of default text, use `first occurrence`.
"
" # variables.
" Variable should transform to text node.
"
function! s:Snippet.sync() abort
  let l:fn = {}
  let l:fn.group = {}
  let l:fn.sync_targets = []
  function! l:fn.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder'
      if !has_key(self.group, a:node.id)
        let self.group[a:node.id] = a:node
      else
        call add(self.sync_targets, {
        \   'range': a:range,
        \   'node': a:node,
        \   'from': self.group[a:node.id],
        \ })
      endif
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  " Create text_edits.
  let l:text_edits = []
  for l:target in l:fn.sync_targets
    let l:new_text = l:target.from.text()
    if l:new_text !=# l:target.node.text()
      call add(l:text_edits, {
      \   'node': l:target.node,
      \   'range': {
      \     'start': self.offset_to_position(l:target.range[0]),
      \     'end': self.offset_to_position(l:target.range[1]),
      \   },
      \   'newText': l:new_text
      \ })
    endif
  endfor

  " Sync placeholder text after created text_edits.
  for l:text_edit in l:text_edits
    let l:text_edit.node.children = [vsnip#session#snippet#node#create_text(l:text_edit.newText)]
  endfor

  return l:text_edits
endfunction

"
" range.
"
function! s:Snippet.range() abort
  " TODO: Should fix end range for next line?
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
function! s:Snippet.insert_node(position, nodes) abort
  let l:offset = self.position_to_offset(a:position)

  let l:fn1 = {}
  let l:fn1.offset = l:offset
  let l:fn1.nodes = a:nodes
  let l:fn1.returns = v:null
  function! l:fn1.traverse(range, node, parent, depth) abort
    if a:range[0] <= self.offset && self.offset <= a:range[1] && a:node.type ==# 'text'
      " prefer more deeper node.
      if empty(self.returns) || self.returns.depth <= a:depth
        let self.returns = {
        \   'range': a:range,
        \   'node': a:node,
        \   'parent': a:parent,
        \   'depth': a:depth,
        \ }
      endif
    endif
  endfunction
  call self.traverse(self, self.children, l:fn1.traverse, 0, 0)

  if !empty(l:fn1.returns)
    let l:range = l:fn1.returns.range
    let l:node = l:fn1.returns.node
    let l:parent = l:fn1.returns.parent
    let l:idx = index(l:parent.children, l:node)

    " remove target node.
    call remove(l:parent.children, l:idx)

    let l:inserts = reverse(a:nodes)

    " split target node.
    if l:node.value !=# ''
      let l:off = l:offset - l:range[0]
      let l:before = vsnip#session#snippet#node#create_text(strcharpart(l:node.value, 0, l:off))
      let l:after = vsnip#session#snippet#node#create_text(strcharpart(l:node.value, l:off, strchars(l:node.value) - l:off))
      let l:inserts = [l:after] + l:inserts + [l:before]
    endif

    " insert nodes.
    for l:node in l:inserts
      call insert(l:parent.children, l:node, l:idx)
    endfor
  endif

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
