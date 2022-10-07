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
function! s:Snippet.init() abort
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
  if !l:fn.has_final_tabstop && g:vsnip_append_final_tabstop
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
  if !self.is_followable(a:current_tabstop, a:diff)
    return v:false
  endif

  let a:diff.range = [
  \   self.position_to_offset(a:diff.range.start),
  \   self.position_to_offset(a:diff.range.end),
  \ ]

  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.diff = a:diff
  let l:fn.is_target_context_fixed = v:false
  let l:fn.target_context = v:null
  let l:fn.contexts = []
  function! l:fn.traverse(context) abort
    if self.diff.range[1] < a:context.range[0]
      return v:true
    endif
    if a:context.node.type !=# 'text'
      return
    endif

    let l:included = v:false
    let l:included = l:included || a:context.range[0] <= self.diff.range[0] && self.diff.range[0] < a:context.range[1] " right
    let l:included = l:included || a:context.range[0] < self.diff.range[1] && self.diff.range[1] <= a:context.range[1] " left
    let l:included = l:included || self.diff.range[0] <= a:context.range[0] && a:context.range[1] <= self.diff.range[1] " middle
    if l:included
      if !self.is_target_context_fixed && (empty(self.target_context) && a:context.parent.type ==# 'placeholder' || get(a:context.parent, 'id', -1) == self.current_tabstop)
        let self.is_target_context_fixed = get(a:context.parent, 'id', -1) == self.current_tabstop
        let self.target_context = a:context
      endif
      call add(self.contexts, a:context)
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)

  if empty(l:fn.contexts)
    return v:false
  endif

  let l:fn.target_context = empty(l:fn.target_context) ? l:fn.contexts[-1] : l:fn.target_context

  let l:diff_text = a:diff.text
  for l:context in l:fn.contexts
    let l:diff_range = [max([a:diff.range[0], l:context.range[0]]), min([a:diff.range[1], l:context.range[1]])]
    let l:start = l:diff_range[0] - l:context.range[0]
    let l:end = l:diff_range[1] - l:context.range[0]

    " Create patched new text.
    let l:new_text = strcharpart(l:context.text, 0, l:start)
    if l:fn.target_context is# l:context
      let l:new_text .= l:diff_text
      let l:followed = v:true
    endif
    let l:new_text .= strcharpart(l:context.text, l:end, l:context.length - l:end)

    " Apply patched new text.
    let l:context.node.value = l:new_text
  endfor

  " Squash nodes when the edit was unexpected
  let l:squashed = []
  for l:context in l:fn.contexts
    let l:squash_targets = l:context.parents + [l:context.node]
    for l:i in range(len(l:squash_targets) - 1, 1, -1)
      let l:node = l:squash_targets[l:i]
      let l:parent = l:squash_targets[l:i - 1]

      let l:should_squash = v:false
      let l:should_squash = l:should_squash || get(l:node, 'follower', v:false)
      let l:should_squash = l:should_squash || get(l:parent, 'id', v:null) is# a:current_tabstop
      let l:should_squash = l:should_squash || l:context isnot# l:fn.target_context && strlen(l:node.text()) == 0
      if l:should_squash && index(l:squashed, l:node) == -1
        let l:index = index(l:parent.children, l:node)
        call remove(l:parent.children, l:index)
        call insert(l:parent.children, vsnip#snippet#node#create_text(l:node.text()), l:index)
        call add(l:squashed, l:node)
      endif
    endfor
  endfor

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
          \   'new_text': a:context.node.transform.text(self.new_texts[a:context.node.id]),
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
" is_followable.
"
function! s:Snippet.is_followable(current_tabstop, diff) abort
  if g:vsnip#DeactivateOn.OutsideOfSnippet == g:vsnip_deactivate_on
    return vsnip#range#cover(self.range(), a:diff.range)
  elseif g:vsnip#DeactivateOn.OutsideOfCurrentTabstop == g:vsnip_deactivate_on
    let l:context = self.get_placeholder_context_by_tabstop(a:current_tabstop)
    if empty(l:context)
      return v:false
    endif
    return vsnip#range#cover({
    \   'start': self.offset_to_position(l:context.range[0]),
    \   'end': self.offset_to_position(l:context.range[1]),
    \ }, a:diff.range)
  endif
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
" get_placeholder_context_by_tabstop
"
function! s:Snippet.get_placeholder_context_by_tabstop(current_tabstop) abort
  let l:fn =  {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.context = v:null
  function! l:fn.traverse(context) abort
    if a:context.node.type ==# 'placeholder' && a:context.node.id == self.current_tabstop
      let self.context = a:context
      return v:true
    endif
  endfunction
  call self.traverse(self, l:fn.traverse)
  return l:fn.context
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
" merge
"
function! s:Snippet.merge(tabstop, snippet) abort
  " increase new snippet's tabstop by current snippet's current tabstop
  let l:offset = 1
  let l:tabstop_map = {}
  for l:node in a:snippet.get_placeholder_nodes()
    if !has_key(l:tabstop_map, l:node.id)
      let l:tabstop_map[l:node.id] = a:tabstop + l:offset
    endif
    let l:node.id = l:tabstop_map[l:node.id]
    let l:offset += 1
  endfor
  if empty(l:tabstop_map)
    return
  endif

  let l:tail = l:node

  " re-assign current snippet's tabstop by new snippet's final tabstop
  let l:offset = 1
  let l:tabstop_map = {}
  for l:node in self.get_placeholder_nodes()
    if l:node.id > a:tabstop
      if !has_key(l:tabstop_map, l:node.id)
        let l:tabstop_map[l:node.id] = l:tail.id + l:offset
      endif
      let l:node.id = l:tabstop_map[l:node.id]
      let l:offset += 1
    endif
  endfor
endfunction

"
" insert
"
function! s:Snippet.insert(position, nodes_to_insert) abort
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
  let l:lines = split(strcharpart(self.text(), 0, a:offset), "\n", v:true)
  return {
  \   'line': self.position.line + len(l:lines) - 1,
  \   'character': strchars(l:lines[-1]) + (len(l:lines) == 1 ? self.position.character : 0),
  \ }
endfunction

"
" position_to_offset.
"
" @param position buffer position
" @return 0-based index for snippet text.
"
function! s:Snippet.position_to_offset(position) abort
  let l:line = a:position.line - self.position.line
  let l:char = a:position.character - (l:line == 0 ? self.position.character : 0)
  let l:lines = split(self.text(), "\n", v:true)[0 : l:line]
  let l:lines[-1] = strcharpart(l:lines[-1], 0, l:char)
  return strchars(join(l:lines, "\n"))
endfunction

"
" traverse.
"
function! s:Snippet.traverse(node, callback) abort
  let l:state = {
  \   'offset': 0,
  \   'before_text': self.before_text,
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
