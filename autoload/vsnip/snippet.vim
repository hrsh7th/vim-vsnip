function! vsnip#snippet#import() abort
  return s:Snippet
endfunction

let s:Snippet = {}

"
" new.
"
function! s:Snippet.new(text) abort
  return extend(deepcopy(s:Snippet), {
        \   'children': vsnip#snippet#node#create_from_ast(vsnip#snippet#parser#parse(a:text))
        \ })
endfunction

"
" text.
"
function! s:Snippet.text() abort
  return join(map(copy(self.children), { k, v -> v.text(self) }), '')
endfunction

"
" get placeholader range.
"
function! s:Snippet.get_placeholder_range(id) abort
  let l:fn = {}
  let l:fn.id = a:id
  let l:fn.result = [-1, -1]
  function! l:fn.traverse(range, node) abort
    if a:node.type ==# 'placeholder' && a:node.id == self.id
      let self.result = a:range
      return v:true
    endif
    return v:false
  endfunction
  call self.traverse(self.children, l:fn.traverse, 0)
  return l:fn.result
endfunction

"
" traverse.
"
function! s:Snippet.traverse(children, callback, ...) abort
  let l:pos = get(a:000, 0, 0)

  let l:skip = v:false
  for l:child in a:children
    let l:len = strlen(l:child.text(self))

    " child.
    let l:skip = a:callback([l:pos, l:pos + l:len], l:child)
    if l:skip
      return l:skip
    endif

    " child.children.
    if has_key(l:child, 'children') && len(l:child.children)
      let l:skip = self.traverse(l:child.children, a:callback, l:pos)
      if l:skip
        return l:skip
      endif
    endif

    let l:pos += l:len
  endfor
  return l:skip
endfunction

