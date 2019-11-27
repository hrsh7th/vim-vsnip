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
        \   'changenr': changenr()
        \ })
endfunction

"
" insert.
"
function! s:Session.insert() abort
  call lamp#view#notice#add({ 'lines': ['`Snippet`: session activated.'] })
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
  " compute diff.
  let l:buffer = getbufline(self.bufnr, '^', '$')
  let l:diff = lamp#server#document#diff#compute(self.buffer, l:buffer)
  let self.buffer = l:buffer
  if l:diff.rangeLength == 0 && l:diff.text ==# ''
    return
  endif

  let l:range = self.snippet.range()

  " diff includes out of range changes (line)
  if l:diff.range.start.line < l:range.start.line || l:range.end.line < l:diff.range.start.line
    call vsnip#deactivate()
    return
  endif

  " diff includes out of range changes (start char)
  if l:diff.range.start.line == l:range.start.line
        \ && l:diff.range.start.character < l:range.start.character
    call vsnip#deactivate()
    return
  endif

  " diff includes out of range changes (start char)
  if l:range.end.line == l:diff.range.end.line &&
        \ l:range.end.character < l:diff.range.end.character
    call vsnip#deactivate()
    return
  endif

  " snippet text is not changed.
  if !self.is_dirty(l:buffer)
    return
  endif

  let l:changenr = changenr()
  if self.changenr <= l:changenr
    if self.snippet.follow(l:changenr, l:diff)
      call lamp#view#edit#apply(self.bufnr, self.snippet.sync())
    else
      call vsnip#deactivate()
    endif
  else
    call self.snippet.restore(l:changenr)
  endif
  let self.changenr = l:changenr
  let self.buffer = getbufline(self.bufnr, '^', '$')
endfunction

"
" is_dirty.
"
function! s:Session.is_dirty(buffer)
  let l:range = self.snippet.range()

  let l:text = ''
  for l:i in range(l:range.start.line, l:range.end.line)
    if len(a:buffer) <= l:i
      return v:true
    endif

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

