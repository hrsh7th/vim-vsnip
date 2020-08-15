let s:max_tabstop = 1000000
let s:Position = vital#vsnip#import('VS.LSP.Position')

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
  let l:pos = s:Position.lsp_to_vim('%', a:position)
  let l:snippet = extend(deepcopy(s:Snippet), {
  \   'type': 'snippet',
  \   'position': a:position,
  \   'before_text': getline(l:pos[0])[0 : l:pos[1] - 2],
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
" NOTE: Must not use the node range in this method.
"
function s:Snippet.init() abort
  let l:fn = {}
  let l:fn.self = self
  let l:fn.group = {}
  let l:fn.variable_placeholder = {}
  let l:fn.has_final_tabstop = v:false
  function! l:fn.traverse(context) abort
    if a:context.node.type ==# 'placeholder'
      " Mark as follower placeholder.
      if !has_key(self.group, a:context.node.id)
        let self.group[a:context.node.id] = a:context.node
      else
        let a:context.node.follower = v:true
      endif

      " Mark as having final tabstop
      if a:context.node.is_final
        let self.has_final_tabstop = v:true
      endif
    elseif a:context.node.type ==# 'variable'
      " TODO refactor
      " variable placeholder
      if a:context.node.unknown
        let a:context.node.type = 'placeholder'
        let a:context.node.choice = []

        if !has_key(self.variable_placeholder, a:context.node.name)
          let self.variable_placeholder[a:context.node.name] = s:max_tabstop - (len(self.variable_placeholder) + 1)
          let a:context.node.id = self.variable_placeholder[a:context.node.name]
          let a:context.node.follower = v:false
          let a:context.node.children = empty(a:context.node.children) ? [vsnip#snippet#node#create_text(a:context.node.name)] : a:context.node.children
          let self.group[a:context.node.id] =  a:context.node
        else
          let a:context.node.id = self.variable_placeholder[a:context.node.name]
          let a:context.node.follower = v:true
          let a:context.node.children = [vsnip#snippet#node#create_text(self.group[a:context.node.id].text())]
        endif
      else
        let l:text = a:context.node.resolve(a:context)
        let l:text = l:text is# v:null ? a:context.text : l:text
        let l:index = index(a:context.parent.children, a:context.node)
        call remove(a:context.parent.children, l:index)
        call insert(a:context.parent.children, vsnip#snippet#node#create_text(l:text), l:index)
      endif
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  " Append ${MAX_TABSTOP} for the end of snippet.
  if !l:fn.has_final_tabstop
    let self.children += [vsnip#snippet#node#create_from_ast({
    \   'type': 'placeholder',
    \   'id': 0,
    \   'choice': [],
    \ })]
  endif
endfunction

"
" follow.
"
function! s:Snippet.follow(current_tabstop, diff) abort
  let l:range = self.range()
  let l:in_range = v:true
  let l:in_range = l:in_range && (l:range.start.line < a:diff.range.start.line || l:range.start.line == a:diff.range.start.line && l:range.start.character <= a:diff.range.start.character)
  let l:in_range = l:in_range && (l:range.end.line > a:diff.range.start.line || l:range.end.line == a:diff.range.end.line && l:range.end.character >= a:diff.range.end.character)
  if !l:in_range
    return v:false
  endif

  let a:diff.range = [
  \   self.position_to_offset(a:diff.range.start),
  \   self.position_to_offset(a:diff.range.end),
  \ ]

  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.diff = a:diff
  let l:fn.context = v:null
  function! l:fn.traverse(context) abort
    " diff:     s-------e
    " text:   1-----------2
    " expect:       ^
    if a:context.range[0] <= self.diff.range[0] && self.diff.range[1] <= a:context.range[1]
      let l:should_update = v:false
      let l:should_update = l:should_update || empty(self.context)
      let l:should_update = l:should_update || a:context.node.type ==# 'placeholder'
      let l:should_update = l:should_update || self.context.node.type ==# 'text' && self.diff.range[0] == self.diff.range[1]
      if l:should_update
        let self.context = a:context
      endif
      " Stop traversing when acceptable node is current tabstop.
      return self.context.node.type ==# 'placeholder' && self.context.node.id == self.current_tabstop
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  let l:context = l:fn.context
  if empty(l:context)
    return v:false
  endif

  " Create patched new text.
  let l:start = a:diff.range[0] - l:context.range[0]
  let l:end = a:diff.range[1] - l:context.range[0]
  let l:new_text = ''
  let l:new_text .= strcharpart(l:context.text, 0, l:start)
  let l:new_text .= a:diff.text
  let l:new_text .= strcharpart(l:context.text, l:end, l:context.length - l:end)

  " Apply patched new text.
  if l:context.node.type ==# 'text'
    let l:context.node.value = l:new_text
  else
    let l:context.node.children = [vsnip#snippet#node#create_text(l:new_text)]
  endif

  " Convert to text node when edited node is follower node.
  if len(l:context.parents) > 1
    echomsg string(["map(copy(l:context.parents), 'v:val.type)')", l:context.node.type, map(copy(l:context.parents), 'v:val.type . get(v:val, "follower", v:false)')])
    for l:i in range(1, len(l:context.parents) - 1)
      let l:parent = l:context.parents[l:i - 1]
      let l:node = l:context.parents[l:i]
      if get(l:node, 'follower', v:false)
        let l:index = index(l:parent.children, l:node)
        call remove(l:parent.children, l:index)
        call insert(l:parent.children, vsnip#snippet#node#create_text(l:node.text()), l:index)
        break
      endif
    endfor
  endif

  return v:true
endfunction

"
" sync.
"
function! s:Snippet.sync() abort
  let l:fn = {}
  let l:fn.new_texts = {}
  let l:fn.targets = []
  function! l:fn.traverse(context) abort
    if a:context.node.type ==# 'placeholder'
      if !has_key(self.new_texts, a:context.node.id)
        let self.new_texts[a:context.node.id] = a:context.text
      else
        if self.new_texts[a:context.node.id] !=# a:context.text
          call add(self.targets, {
          \   'range': a:context.range,
          \   'node': a:context.node,
          \   'new_text': self.new_texts[a:context.node.id],
          \ })
        endif
      endif
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  " Create text_edits.
  let l:text_edits = []
  for l:target in l:fn.targets
    call add(l:text_edits, {
    \   'node': l:target.node,
    \   'range': {
    \     'start': self.offset_to_position(l:target.range[0]),
    \     'end': self.offset_to_position(l:target.range[1]),
    \   },
    \   'newText': l:target.new_text
    \ })
  endfor

  " Sync placeholder text after created text_edits (the reason is to avoid using a modified range).
  for l:text_edit in l:text_edits
    let l:text_edit.node.children = [vsnip#snippet#node#create_text(l:text_edit.newText)]
  endfor

  return l:text_edits
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
  return join(map(copy(self.children), 'v:val.text()'), '')
endfunction

"
" get_placeholder_nodes
"
function! s:Snippet.get_placeholder_nodes() abort
  let l:fn =  {}
  let l:fn.nodes = []
  function! l:fn.traverse(context) abort
    if a:context.node.type ==# 'placeholder'
      call add(self.nodes, a:context.node)
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  return sort(l:fn.nodes, { a, b -> a.id - b.id })
endfunction

"
" get_next_jump_point.
"
function! s:Snippet.get_next_jump_point(current_tabstop) abort
  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.context = v:null
  function! l:fn.traverse(context) abort
    if a:context.node.type ==# 'placeholder' && self.current_tabstop < a:context.node.id
      if !empty(self.context) && self.context.node.id <= a:context.node.id
        return v:false
      endif

      let self.context = copy(a:context)
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  let l:context = l:fn.context
  if empty(l:context)
    return {}
  endif

  return {
  \   'placeholder': l:context.node,
  \   'range': {
  \     'start': self.offset_to_position(l:context.range[0]),
  \     'end': self.offset_to_position(l:context.range[1])
  \   }
  \ }
endfunction

"
" get_prev_jump_point.
"
function! s:Snippet.get_prev_jump_point(current_tabstop) abort
  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.context = v:null
  function! l:fn.traverse(context) abort
    if a:context.node.type ==# 'placeholder' && self.current_tabstop > a:context.node.id
      if !empty(self.context) && self.context.node.id >= a:context.node.id
        return v:false
      endif
      let self.context = copy(a:context)
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  let l:context = l:fn.context
  if empty(l:context)
    return {}
  endif

  return {
  \   'placeholder': l:context.node,
  \   'range': {
  \     'start': self.offset_to_position(l:context.range[0]),
  \     'end': self.offset_to_position(l:context.range[1])
  \   }
  \ }
endfunction

"
" normalize
"
" - merge adjacent text-nodes
"
function! s:Snippet.normalize() abort
  let l:fn = {}
  let l:fn.prev_context = v:null
  function! l:fn.traverse(context) abort
    if !empty(self.prev_context)
      if self.prev_context.node.type ==# 'text' && a:context.node.type ==# 'text' && self.prev_context.parent is# a:context.parent
        let a:context.node.value = self.prev_context.node.value . a:context.node.value
        call remove(self.prev_context.parent.children, index(self.prev_context.parent.children, self.prev_context.node))
      endif
    endif
    let self.prev_context = copy(a:context)
  endfunction
  call self.traverse(self, l:fn.traverse)
endfunction

"
" insert_node
"
function! s:Snippet.insert_node(position, nodes_to_insert) abort
  let l:offset = self.position_to_offset(a:position)

  " Search target node for inserting nodes.
  let l:fn = {}
  let l:fn.offset = l:offset
  let l:fn.context = v:null
  function! l:fn.traverse(context) abort
    if a:context.range[0] <= self.offset && self.offset <= a:context.range[1] && a:context.node.type ==# 'text'
      " prefer more deeper node.
      if empty(self.context) || self.context.depth <= a:context.depth
        let self.context = copy(a:context)
      endif
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  " This condition is unexpected normally
  let l:context = l:fn.context
  if empty(l:context)
    return
  endif

  " Remove target text node
  let l:index = index(l:context.parent.children, l:context.node)
  call remove(l:context.parent.children, l:index)

  " Should insert into existing text node when position is middle of node
  let l:nodes_to_insert = reverse(a:nodes_to_insert)
  if l:context.node.value !=# ''
    let l:off = l:offset - l:context.range[0]
    let l:before = vsnip#snippet#node#create_text(strcharpart(l:context.node.value, 0, l:off))
    let l:after = vsnip#snippet#node#create_text(strcharpart(l:context.node.value, l:off, strchars(l:context.node.value) - l:off))
    let l:nodes_to_insert = [l:after] + l:nodes_to_insert + [l:before]
  endif

  " Insert nodes.
  for l:node in l:nodes_to_insert
    call insert(l:context.parent.children, l:node, l:index)
  endfor

  call self.normalize()
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
" traverse.
"
function! s:Snippet.traverse(node, callback) abort
  let l:state = {
  \   'offset': 0,
  \   'before_text': '',
  \ }
  let l:context = {
  \   'depth': 0,
  \   'parent': v:null,
  \   'parents': [],
  \ }
  call s:traverse(a:node, a:callback, l:state, l:context)
endfunction
function! s:traverse(node, callback, state, context) abort
  let l:text = ''
  let l:length = 0
  if a:node.type !=# 'snippet'
    let l:text = a:node.text()
    let l:length = strchars(l:text)
    if a:callback({
    \   'node': a:node,
    \   'text': l:text,
    \   'length': l:length,
    \   'parent': a:context.parent,
    \   'parents': a:context.parents,
    \   'depth': a:context.depth,
    \   'offset': a:state.offset,
    \   'before_text': a:state.before_text,
    \   'range': [a:state.offset, a:state.offset + l:length],
    \ })
      return v:true
    endif
  endif

  if len(a:node.children) > 0
    let l:next_context = {
      \   'parent': a:node,
      \   'parents': a:context.parents + [a:node],
      \   'depth': len(a:context.parents) + 1,
      \ }
    for l:child in copy(a:node.children)
      if s:traverse(l:child, a:callback, a:state, l:next_context)
        return v:true
      endif
    endfor
  else
    let a:state.before_text .= l:text
    let a:state.offset += l:length
  endif
endfunction

"
" debug
"
function! s:Snippet.debug() abort
  echomsg 'snippet.text()'
  for l:line in split(self.text(), "\n", v:true)
    echomsg string(l:line)
  endfor
  echomsg '-----'

  let l:fn = {}
  function! l:fn.traverse(context) abort
    echomsg repeat('    ', a:context.depth - 1) . a:context.node.to_string()
  endfunction
  call self.traverse(self, l:fn.traverse)
  echomsg ' '
endfunction
