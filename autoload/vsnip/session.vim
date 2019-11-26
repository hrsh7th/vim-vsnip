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
function! s:Session.new(bufnr, position, text) abort
  return extend(deepcopy(s:Session), {
        \   'bufnr': a:bufnr,
        \   'buffer': getbufline(a:bufnr, '^', '$'),
        \   'snippet': s:Snippet.new(a:position, a:text),
        \   'active': v:true,
        \   'timer_id': -1
        \ })
endfunction

"
" insert.
"
function! s:Session.insert() abort
  call lamp#view#edit#apply(self.bufnr, [{
        \   'range': {
        \     'start': self.snippet.position,
        \     'end': self.snippet.position
        \   },
        \   'newText': self.snippet.text()
        \ }])
endfunction

"
" on_text_changed.
"
function! s:Session.on_text_changed() abort
  call self.on_text_changed_after()
endfunction

"
" on_text_changed.
"
function! s:Session.on_text_changed_after() abort
  if !self.active
    return
  endif

  let l:buffer = getbufline(self.bufnr, '^', '$')

  " snippet text is not changed.
  if !self.is_dirty(l:buffer)
    let self.buffer = l:buffer
    return
  endif

  " compute diff.
  let l:diff = lamp#server#document#diff#compute(self.buffer, l:buffer)
  let self.buffer = l:buffer
  if l:diff.rangeLength == 0 && l:diff.text ==# ''
    return
  endif

  let l:range = self.snippet.range()

  " out of range (line).
  if l:diff.range.start.line > l:range.start.line || l:range.end.line < l:diff.range.end.line
    let self.active = v:false
    return
  endif

  " out of range (start char).
  if l:diff.range.start.line == l:range.start.line &&
        \ l:diff.range.start.character < l:range.start.character
    let self.active = v:false
    return
  endif

  " out of range (end char).
  if l:range.end.line == l:diff.range.end.line &&
        \ l:range.end.character < l:diff.range.end.character
    let self.active = v:false
    return
  endif

  " follow and sync.
  call self.snippet.follow(l:diff)
  try
    undojoin | call call({ -> lamp#view#edit#apply(self.bufnr, self.snippet.sync()) }, [])
  catch /.*/
    " undojoin causes error when undo. this is expected exception.
  endtry
  let self.buffer = getbufline(self.bufnr, '^', '$')
endfunction

"
" is_dirty.
"
function! s:Session.is_dirty(buffer)
  let l:range = self.snippet.range()

  let l:text = ''
  for l:i in range(l:range.start.line, l:range.end.line)
    " same line.
    if l:i == l:range.start.line && l:i == l:range.end.line
      let l:text = a:buffer[l:i][l:range.start.character : l:range.end.character - 1]
      break

    " multi start.
    elseif l:i == l:range.start.line
      let l:text .= a:buffer[l:i][l:range.start.character : -1] . "\n"

    " multi middle.
    elseif l:i != l:range.end.line
      let l:text .= a:buffer[l:i] . "\n"

    " multi end.
    elseif l:i == l:range.end.line
      let l:text .= a:buffer[l:i][0 : l:range.end.character - 1]
    endif
  endfor

  return self.snippet.text() !=# l:text
endfunction

"
" deactivate.
"
function! s:Session.deactivate() abort
  let self.active = v:false
endfunction

