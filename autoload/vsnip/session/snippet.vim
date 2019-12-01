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
  let l:fn = {}
  let l:fn.changenr = a:changenr
  function! l:fn.traverse(range, node, parent) abort
    if a:node.type !=# 'text'
      return v:false
    endif
    let a:node.history[self.changenr] = a:node.value
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)
endfunction

"
" restore.
"
function! s:Snippet.restore(changenr) abort
  let l:fn = {}
  let l:fn.changenr = a:changenr
  function! l:fn.traverse(range, node, parent) abort
    if a:node.type !=# 'text'
      return v:false
    endif
    if has_key(a:node.history, self.changenr)
      let a:node.value = a:node.history[self.changenr]
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)
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
  function! l:fn.traverse(range, node, parent) abort
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
  call self.traverse(self, self.children, l:fn.traverse, 0)

  if len(l:fn.candidates) == 0
    return v:false
  endif

  let l:target = v:null
  for l:candidate in l:fn.candidates
    if l:candidate.range[0] ==# a:diff.range[0] && a:diff.range[1] ==# l:candidate.range[1]
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
  else
    let l:start = a:diff.range[0] - l:target.range[0] - 1
    let l:end = a:diff.range[1] - l:target.range[0]
    let l:value = ''
    let l:value .= l:start >= 0 ? l:target.node.value[0: l:start] : ''
    let l:value .= a:diff.text
    let l:value .= l:target.node.value[l:end : -1]
    let l:target.node.value = l:value
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
  function! l:fn1.traverse(range, node, parent) abort
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
  call self.traverse(self, self.children, l:fn1.traverse, 0)

  " sync placeholder.
  let l:fn2 = {}
  let l:fn2.self = self
  let l:fn2.group = {}
  function! l:fn2.traverse(range, node, parent) abort
    if a:node.type ==# 'placeholder'
      " append text node when placeholder has no children.
      if len(a:node.children) == 0
        let a:node.children = [vsnip#session#snippet#node#create_text('')]
      endif

      " detect first occurrence of same tabstop placeholdes.
      if !has_key(self.group, a:node.id)
        let self.group[a:node.id] = a:node
      else
        let a:node.children = deepcopy(self.group[a:node.id].children)
      endif

      " fix 0-tabstop to max tabstop.
      if a:node.id == 0
        let a:node.id = s:max_tabstop
      endif

    elseif a:node.type ==# 'variable'
      let l:index = index(a:parent.children, a:node)
      call remove(a:parent.children, l:index)
      call insert(a:parent.children, vsnip#session#snippet#node#create_text(a:node.text()), l:index)
    endif
  endfunction
  call self.traverse(self, self.children, l:fn2.traverse, 0)

  return l:fn1.edits
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
  let l:fn = {}
  let l:fn.current_tabstop = a:current_tabstop
  let l:fn.self = self
  function! l:fn.traverse(range, node, parent) abort
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
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)

  " can't detect next jump point.
  if !has_key(l:fn, 'jump_point')
    return {}
  endif

  return l:fn.jump_point
endfunction

"
" traverse.
"
function! s:Snippet.traverse(parent, children, callback, pos) abort
  let l:pos = a:pos
  let l:skip = v:false
  let l:children = copy(a:children)
  for l:i in range(0, len(l:children) - 1)
    let l:node = l:children[l:i]
    let l:length = strlen(l:node.text())

    " child.
    let l:skip = a:callback([l:pos, l:pos + l:length], l:node, a:parent)
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

