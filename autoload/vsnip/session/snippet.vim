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
        \   'end': self.offset_to_position(strlen(self.text()))
        \ }
endfunction

"
" store.
"
function! s:Snippet.store(changenr) abort
  let l:ctx = {}
  let l:ctx.changenr = a:changenr
  function! l:ctx.traverse(range, node, next, parent) abort
    if a:node.type !=# 'text'
      return v:false
    endif
    let a:node.history[self.changenr] = a:node.value
  endfunction
  call self.traverse(self, self.children, l:ctx.traverse, 0)
endfunction

"
" restore.
"
function! s:Snippet.restore(changenr) abort
  let l:ctx = {}
  let l:ctx.changenr = a:changenr
  function! l:ctx.traverse(range, node, next, parent) abort
    if a:node.type !=# 'text'
      return v:false
    endif
    if has_key(a:node.history, self.changenr)
      let a:node.value = a:node.history[self.changenr]
    endif
  endfunction
  call self.traverse(self, self.children, l:ctx.traverse, 0)
endfunction

"
" follow.
"
function! s:Snippet.follow(diff) abort
  let a:diff.range = [
        \   self.position_to_offset(a:diff.range.start),
        \   self.position_to_offset(a:diff.range.end),
        \ ]

  let l:ctx = {}
  let l:ctx.diff = a:diff
  let l:ctx.found = v:false
  function! l:ctx.traverse(range, node, next, parent) abort
    if a:node.type !=# 'text'
      return v:false
    endif

    let l:is_before = a:range[1] < self.diff.range[0]
    let l:is_after = self.diff.range[1] < a:range[0]

    " Skip before range.
    " diff:      s-----e
    " text:   1-----2-----3-----4
    " expect:                ^
    if l:is_before && !l:is_after
      return v:false
    endif

    " Skip after range.
    " diff:            s-----e
    " text:   1-----2-----3-----4
    " expect:    ^
    if !l:is_before && l:is_after
      return v:false
    endif

    " If diff is empty and position is just gap, use after node.
    " diff:               d
    " text:   1-----2-----3-----4
    " expect:          ^
    if a:range[1] == self.diff.range[0] && !empty(a:next)
      return v:false
    endif

    " Process included range.
    " diff:      s-----e
    " text:   1-----------2
    " expect:       ^
    if a:range[0] <= self.diff.range[0] && self.diff.range[1] <= a:range[1]
      let l:start = self.diff.range[0] - a:range[0] - 1
      let l:end = self.diff.range[1] - a:range[0]
      let l:value = ''
      let l:value .= l:start >= 0 ? a:node.value[0: l:start] : ''
      let l:value .= self.diff.text
      let l:value .= a:node.value[l:end : -1]
      let a:node.value = l:value
      let self.found = v:true
      return v:true
    endif

    return v:false
  endfunction
  call self.traverse(self, self.children, l:ctx.traverse, 0)

  return l:ctx.found
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
  let l:ctx1 = {}
  let l:ctx1.self = self
  let l:ctx1.group = {}
  let l:ctx1.edits = []
  function! l:ctx1.callback(range, node, next, parent) abort
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
  call self.traverse(self, self.children, l:ctx1.callback, 0)

  " sync placeholder.
  let l:ctx2 = {}
  let l:ctx2.self = self
  let l:ctx2.group = {}
  function! l:ctx2.callback(range, node, next, parent) abort
    if a:node.type ==# 'placeholder'
      if !has_key(self.group, a:node.id)
        let self.group[a:node.id] = a:node
      else
        let a:node.children = deepcopy(self.group[a:node.id].children)
      endif
      if a:node.id == 0
        let a:node.id = s:max_tabstop
      endif
    elseif a:node.type ==# 'variable'
      let l:index = index(a:parent.children, a:node)
      call remove(a:parent.children, l:index)
      call insert(a:parent.children, vsnip#session#snippet#node#create_from_ast({
            \   'type': 'text',
            \   'raw': a:node.text(),
            \   'escaped': a:node.text()
            \ }), l:index)
    endif
  endfunction
  call self.traverse(self, self.children, l:ctx2.callback, 0)

  return l:ctx1.edits
endfunction

"
" text.
"
function! s:Snippet.text() abort
  return join(map(copy(self.children), { k, v -> v.text() }), '')
endfunction

"
" get_placeholder_with_range.
"
function! s:Snippet.get_next_jump_point(current_tabstop) abort
  let l:ctx = {}
  let l:ctx.current_tabstop = a:current_tabstop
  let l:ctx.self = self
  function! l:ctx.callback(range, node, next, parent) abort
    if a:node.type ==# 'placeholder' && self.current_tabstop < a:node.id
      let self.jump_point = {
            \   'range': {
            \     'start': self.self.offset_to_position(a:range[0]),
            \     'end': self.self.offset_to_position(a:range[1]),
            \   },
            \   'placeholder': a:node
            \ }
      return v:true
    endif
    return v:false
  endfunction
  call self.traverse(self, self.children, l:ctx.callback, 0)

  " deactivate when jump to final tabstop.
  if l:ctx.jump_point.placeholder.id == s:max_tabstop
    call vsnip#deactivate()
  endif

  return l:ctx.jump_point
endfunction

"
" traverse.
"
function! s:Snippet.traverse(parent, children, callback, pos) abort
  let l:pos = a:pos
  let l:skip = v:false
  let l:children = copy(a:children)
  for l:i in range(0, len(l:children) - 1)
    let l:next = get(l:children, l:i + 1, v:null)
    let l:node = l:children[l:i]
    let l:length = strlen(l:node.text())

    " child.
    let l:skip = a:callback([l:pos, l:pos + l:length], l:node, l:next, a:parent)
    if l:skip
      return l:skip
    endif

    " child.children.
    if has_key(l:node, 'children') && len(l:node.children) > 0
      let l:skip = self.traverse(l:node, l:node.children, a:callback, l:pos)
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

    let l:width = strlen(l:char)
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
      let l:offset += strlen(l:lines[l:i]) + 1
    elseif l:i == a:position.line
      if a:position.character > 0
        let l:offset += strlen(l:lines[l:i][0 : a:position.character - 1])
      endif
    endif

    let l:i += 1
  endwhile

  return l:offset
endfunction

