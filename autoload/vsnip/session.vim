let s:Snippet = vsnip#session#snippet#import()

"
" import.
"
function! vsnip#session#import() abort
  return s:Session
endfunction

let s:Session = {}

"
" new.
"
function! s:Session.new(bufnr, position, lines) abort
  return extend(deepcopy(s:Session), {
        \   'bufnr': a:bufnr,
        \   'buffer': getbufline(a:bufnr, '^', '$'),
        \   'snippet': s:Snippet.new(a:position, join(a:lines, "\n"))
        \ })
endfunction

"
" on_text_changed
"
function! s:Session.on_text_changed()
  let l:buffer = getbufline(self.bufnr, '^', '$')
  let l:diff = vsnip#utils#diff#compute(self.buffer, l:buffer)
  if l:diff.rangeLength == 0 && l:diff.newText ==# ''
    return
  endif
  let self.buffer = l:buffer
  call self.snippet.follow(l:diff)
  let l:range = self.snippet.range()
endfunction

