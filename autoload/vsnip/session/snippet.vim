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
  return extend(deepcopy(s:Snippet), {
        \   'position': a:position,
        \   'children': vsnip#session#snippet#node#create_from_ast(
        \     vsnip#session#snippet#parser#parse(a:text)
        \   )
        \ })
endfunction

"
" range.
"
function! s:Snippet.range() abort
  let l:lines = split(self.text(), "\n", v:true)
  return {
        \   'start': {
        \     'line': self.position.line,
        \     'character': self.position.character,
        \   },
        \   'end': {
        \     'line': self.position.line + len(l:lines),
        \     'character': strlen(l:lines[-1])
        \   }
        \ }
endfunction

"
" follow.
"
function! s:Snippet.follow(diff) abort
  let a:diff.range = self.convert_range(a:diff.range)

  " remove corrupted placeholders.
  let l:fn = {}
  let l:fn.diff = a:diff
  function! l:fn.traverse(range, node, parent) abort
    " remove if node range is covered by edit range.
    if self.diff.range[0] < a:range[0] && a:range[1] < self.diff.range[1]
      call remove(a:parent.children, index(a:parent.children, a:node))
      return v:false
    endif

    if a:node.type !=# 'text'
      return v:false
    endif

    " overlap left -> collapse text.
    if self.diff.range[0] < a:range[0] && self.diff.range[1] <= a:range[1] && a:range[0] < self.diff.range[1]
      let l:offset = self.diff.range[1] - a:range[0]
      let a:node.value = a:node.value[l:offset : -1]

    " overlap right -> expand text.
    elseif a:range[0] < self.diff.range[0] && a:range[1] <= self.diff.range[1] && self.diff.range[0] < a:range[1]
      let l:offset = self.diff.range[0] - a:range[0] - 1
      let l:value = ''
      let l:value .= a:node.value[0 : l:offset]
      let l:value .= self.diff.newText
      let a:node.value = l:value

    " include -> replace text.
    elseif a:range[0] <= self.diff.range[0] && self.diff.range[1] <= a:range[1]
      let l:start_offset = self.diff.range[0] - a:range[0] - 1
      let l:end_offset = self.diff.range[1] - a:range[0]
      let l:value = ''
      let l:value .= a:node.value[0 : l:start_offset]
      let l:value .= self.diff.newText
      let l:value .= a:node.value[l:end_offset : - 1]
      let a:node.value = l:value
    endif

    return v:false
  endfunction
  call self.traverse(self, self.children, l:fn.traverse, 0)
endfunction

"
" sync.
"
function! s:Snippet.sync() abort
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
  let l:fn.result = { 'range': v:null, 'placeholder': v:null }
  function! l:fn.traverse(range, node, parent) abort
    if a:node.type ==# 'placeholder' && a:node.id == self.id
      let self.result.range = a:range
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
  for l:child in copy(a:children)
    let l:len = strlen(l:child.text(self))

    " child.
    let l:skip = a:callback([l:pos, l:pos + l:len], l:child, a:parent)
    if l:skip
      return l:skip
    endif

    " child.children.
    if has_key(l:child, 'children') && len(l:child.children)
      let l:skip = self.traverse(l:child, l:child.children, a:callback, l:pos)
      if l:skip
        return l:skip
      endif
    endif

    let l:pos += l:len
  endfor
  return l:skip
endfunction

"
" convert_range.
"
" line-based range to offset-based range.
"
function! s:Snippet.convert_range(range) abort
  let l:lines = split(self.text(), "\n", v:true)

  let l:start = 0
  let l:end = 0

  let l:i = 0
  while l:i < len(l:lines)
    if l:i != a:range.start.line
      let l:start += strlen(l:lines[l:i])
    elseif l:i == a:range.start.line
      let l:start += strlen(l:lines[l:i][0 : a:range.start.character])
    endif

    if l:i != a:range.end.line
      let l:end += strlen(l:lines[l:i])
    elseif l:i == a:range.end.line
      let l:end += strlen(l:lines[l:i][0 : a:range.end.character])
      break
    endif

    let l:i += 1
  endwhile

  return [l:start, l:end]
endfunction

