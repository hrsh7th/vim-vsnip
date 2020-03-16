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
  call l:snippet.sync()
  return l:snippet
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
" follow.
"
function! s:Snippet.follow(current_tabstop, diff) abort
  let a:diff.range = [
        \   self.position_to_offset(a:diff.range.start),
        \   self.position_to_offset(a:diff.range.end),
        \ ]

  let l:fn = {}
  let l:fn.diff = a:diff
  let l:fn.candidates = []
  function! l:fn.traverse(range, node, parent, depth) abort
    let l:is_before = a:range[1] < self.diff.range[0]
    let l:is_after = self.diff.range[1] < a:range[0]

    " diff:      s-----e
    " text:   1-----2-----3-----4
    " expect:                ^
    if l:is_before && !l:is_after
      return v:false
    endif

    " diff:            s-----e
    " text:   1-----2-----3-----4
    " expect:    ^
    if !l:is_before && l:is_after
      return v:false
    endif

    " diff:     s-------e
    " text:   1-----------2
    " expect:       ^
    if a:range[0] <= self.diff.range[0] && self.diff.range[1] <= a:range[1]
      call add(self.candidates, {
            \   'range': a:range,
            \   'node': a:node,
            \   'parent': a:parent
            \ })
    endif

    return v:false
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)

  if len(l:fn.candidates) == 0
    return v:false
  endif

  let l:target = v:null
  for l:candidate in l:fn.candidates
    if l:candidate.node.type ==# 'placelhoder' && l:candidate.range[0] ==# a:diff.range[0] && a:diff.range[1] ==# l:candidate.range[1]
      let l:target = l:candidate
      break
    else
      let l:target = l:candidate
      if l:target.parent.type ==# 'placeholder' && l:target.parent.id == a:current_tabstop
        break
      endif
    endif
  endfor

  if l:target.node.type ==# 'placeholder'
    let l:target.node.children = [vsnip#session#snippet#node#create_text(a:diff.text)]
    if l:target.node.follower
      let l:index = index(l:target.parent.children, l:target.node)
      call remove(l:target.parent.children, l:index)
      call insert(l:target.parent.children, vsnip#session#snippet#node#create_text(l:target.node.text()), l:index)
    endif
  else
    let l:start = a:diff.range[0] - l:target.range[0] - 1
    let l:end = a:diff.range[1] - l:target.range[0]
    let l:value = ''
    let l:value .= l:start >= 0 ? strcharpart(l:target.node.value, 0, l:start + 1) : ''
    let l:value .= a:diff.text
    let l:value .= strcharpart(l:target.node.value, l:end, strchars(l:target.node.value) - l:end)
    let l:target.node.value = l:value

    if get(l:target.parent, 'follower', v:false)
      let l:parent = self.get_parent(l:target.parent)
      let l:index = index(l:parent.children, l:target.parent)
      call remove(l:parent.children, l:index)
      call insert(l:parent.children, vsnip#session#snippet#node#create_text(l:target.parent.text()), l:index)
    endif
  endif

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
  " create edits.
  let l:fn1 = {}
  let l:fn1.self = self
  let l:fn1.group = {}
  let l:fn1.edits = []
  function! l:fn1.traverse(range, node, parent, depth) abort
    if a:node.type !=# 'placeholder'
      return v:false
    endif

    if !has_key(self.group, a:node.id)
      let self.group[a:node.id] = a:node
    else
      call add(self.edits, {
            \   'range': {
            \     'start': self.self.offset_to_position(a:range[0]),
            \     'end': self.self.offset_to_position(a:range[1])
            \   },
            \   'newText': self.group[a:node.id].text()
            \ })
    endif
  endfunction
  call self.traverse(self, self.children, l:fn1.traverse, 0, 0)

  " sync placeholder.
  let l:fn2 = {}
  let l:fn2.self = self
  let l:fn2.found_final_tabstop = v:false
  let l:fn2.group = {}
  function! l:fn2.traverse(range, node, parent, depth) abort
    if a:node.type ==# 'placeholder'
      " append text node when placeholder has no children.
      if len(a:node.children) == 0
        let a:node.children = [vsnip#session#snippet#node#create_text('')]
      endif

      " sync same tabstop placeholders.
      if !has_key(self.group, a:node.id)
        " first occurrence.
        let self.group[a:node.id] = a:node
      else
        " sync.
        let a:node.follower = v:true
        let a:node.children = [vsnip#session#snippet#node#create_text(self.group[a:node.id].text())]
      endif

      " fix 0-tabstop to max tabstop.
      if a:node.id == 0
        let a:node.id = s:max_tabstop
      endif

      let self.found_final_tabstop = self.found_final_tabstop || a:node.id == s:max_tabstop
    elseif a:node.type ==# 'variable'
      let l:index = index(a:parent.children, a:node)
      call remove(a:parent.children, l:index)
      call insert(a:parent.children, vsnip#session#snippet#node#create_text(a:node.text()), l:index)
    endif
  endfunction
  call self.traverse(self, self.children, l:fn2.traverse, 0, 0)

  " add 0 tabstop to end of snippet if has no 0 tabstop.
  if !l:fn2.found_final_tabstop
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

  return l:fn1.edits
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
  let l:fn.recent = {
  \   'range': [-1, -1],
  \   'node': v:null,
  \   'parent': v:null
  \ }
  function! l:fn.traverse(range, node, parent, depth) abort
    " Check same depth.
    if !empty(self.recent.node) && self.recent.depth == a:depth

      " Check duplicate placeholder.
      if self.recent.node.type ==# 'placeholder' && a:node.type ==# 'placeholder'
        " same range.
        if self.recent.range[0] == a:range[0] && self.recent.range[1] == a:range[1]
          call remove(a:parent.children, index(a:parent.children, a:node))
        endif
      endif

      " Check duplicate text.
      if self.recent.node.type ==# 'text' && a:node.type ==# 'text'
        call remove(a:parent.children, index(a:parent.children, a:node))
        let self.recent.node.value .= a:node.value
      endif
    endif

    let self.recent = {
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
      let l:before = vsnip#session#snippet#node#create_text(l:node.value[0 : l:offset - l:range[0] - 1])
      let l:after = vsnip#session#snippet#node#create_text(l:node.value[l:offset - l:range[0] : -1])
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
    echomsg l:level . string(extend({ 'children': [], 'new': '', 'text': '', }, a:node, 'keep'))
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0, 0)
  echomsg ' '
endfunction

