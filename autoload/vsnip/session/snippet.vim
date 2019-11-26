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
" follow.
"
function! s:Snippet.follow(diff) abort
  let a:diff.range = [
        \   self.position_to_offset(a:diff.range.start),
        \   self.position_to_offset(a:diff.range.end),
        \ ]

  let l:fn = {}
  let l:fn.diff = a:diff
  function! l:fn.traverse(range, node, next, parent) abort
    if a:node.type !=# 'text'
      return v:false
    endif

    let l:is_before = a:range[1] < self.diff.range[0]
    let l:is_after = self.diff.range[1] < a:range[0]

    " Skip before range.
    " diff:               s------e
    " text:   s-----e s-----e  s-----e s-----e
    " expect:    ↑
    if l:is_before && !l:is_after
      return v:false
    endif

    " Skip after range.
    " diff:               s------e
    " text:   s-----e s-----e  s-----e s-----e
    " expect:                             ↑
    if !l:is_before && l:is_after
      return v:false
    endif

    " If diff is empty and position is just gap, use after node.
    " diff:                 r
    " text:   s-----e s-----r-----e s-----e
    " expect:                  ↑
    if a:range[1] == self.diff.range[0] && !empty(a:next)
      return v:false
    endif

    " Process included range.
    " diff:     s-------e
    " text:   s------------e
    " expect:       ↑
    if a:range[0] <= self.diff.range[0] && self.diff.range[1] <= a:range[1]
      let l:start = self.diff.range[0] - a:range[0] - 1
      let l:end = self.diff.range[1] - a:range[0]
      let l:value = ''
      let l:value .= l:start >= 0 ? a:node.value[0: l:start] : ''
      let l:value .= self.diff.text
      let l:value .= a:node.value[l:end : -1]
      let a:node.value = l:value
      return v:true
    endif

    return v:false
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)
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
  let l:fn.self = self
  let l:fn.tabstop = {}
  let l:fn.edits = []
  function! l:fn.traverse(range, node, next, parent) abort
    " placeholders.
    if a:node.type ==# 'placeholder'
      " placeholder first occurrence.
      if !has_key(self.tabstop, a:node.id)
        let self.tabstop[a:node.id] = a:node.text(self.self)

      " sync placeholder text.
      else
        call add(self.edits, {
              \   'range': {
              \     'start': self.self.offset_to_position(a:range[0]),
              \     'end': self.self.offset_to_position(a:range[1])
              \   },
              \   'newText': self.tabstop[a:node.id]
              \ })
        let a:node.children = vsnip#session#snippet#node#create_from_ast([{
              \   'type': 'text',
              \   'raw': self.tabstop[a:node.id],
              \   'escaped': self.tabstop[a:node.id],
              \ }])
      endif
    endif

    " variables.
    if a:node.type ==# 'variable'
      let l:index = index(a:parent.children, a:node)
      call remove(a:parent.children, l:index)
      call insert(a:parent.children, vsnip#session#snippet#node#create_from_ast({
            \   'type': 'text',
            \   'raw': a:node.text(self.self),
            \   'escaped': a:node.text(self.self)
            \ }), l:index)
    endif
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)

  return l:fn.edits
endfunction

"
" text.
"
function! s:Snippet.text() abort
  return join(map(copy(self.children), { k, v -> v.text(self) }), '')
endfunction

"
" get_placeholder_with_range.
"
function! s:Snippet.get_placeholder_with_range(id) abort
  let l:fn = {}
  let l:fn.id = a:id
  let l:fn.self = self
  let l:fn.result = { 'range': v:null, 'placeholder': v:null }
  function! l:fn.traverse(range, node, next, parent) abort
    if a:node.type ==# 'placeholder' && a:node.id == self.id
      let self.result.range = {
            \   'start': self.self.offset_to_position(a:range[0]),
            \   'end': self.self.offset_to_position(a:range[1]),
            \ }
      let self.result.placeholder = a:node
      return v:true
    endif
    return v:false
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)
  return l:fn.result
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
    let l:len = strlen(l:node.text(self))

    " child.
    let l:skip = a:callback([l:pos, l:pos + l:len], l:node, l:next, a:parent)
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

    let l:pos += l:len
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
  while l:i <= a:position.line
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
