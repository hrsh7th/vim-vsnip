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
        \   'timer_id': -1,
        \   'snippet': s:Snippet.new(a:position, self.indent(a:text)),
        \   'tabstop': -1,
        \   'changenr': changenr(),
        \   'changenrs': {},
        \ })
endfunction

"
" insert.
"
function! s:Session.insert() abort
  " insert snippet.
  call vsnip#edits#text_edit#apply(self.bufnr, [{
        \   'range': {
        \     'start': self.snippet.position,
        \     'end': self.snippet.position
        \   },
        \   'newText': self.snippet.text()
        \ }])
  call self.store(changenr())

  " move to end of snippet after snippet insertion.
  let l:range = self.snippet.range()
  call cursor(l:range.end.line + 1, l:range.end.character + 1)
endfunction

"
" jumpable.
"
function! s:Session.jumpable() abort
  let l:jumpable = !empty(self.snippet.get_next_jump_point(self.tabstop))
  if !l:jumpable
    call vsnip#deactivate()
  endif
  return l:jumpable
endfunction

"
" jump.
"
function! s:Session.jump() abort
  let l:jump_point = self.snippet.get_next_jump_point(self.tabstop)
  if empty(l:jump_point)
    call vsnip#deactivate()
    return
  endif

  let self.tabstop = l:jump_point.placeholder.id

  " move to end position.
  call cursor(l:jump_point.range.end.line + 1, l:jump_point.range.end.character + 1)

  " if jump_point has range, select range.
  if l:jump_point.range.start.character != l:jump_point.range.end.character
    let l:cmd = ''
    if mode()[0] ==# 'i'
      let l:cmd .= "\<Esc>"
    else
      let l:cmd .= 'h'
    endif
    let l:cmd .= printf('v%sh', strlen(l:jump_point.placeholder.text()) - 1)
    let l:cmd .= "\<C-g>"
    call feedkeys(l:cmd, 'n')
  else
    startinsert
  endif
endfunction

"
" on_text_changed.
"
function! s:Session.on_text_changed() abort
  let l:changenr = changenr()

  " save state.
  if self.changenr != l:changenr
    call self.store(self.changenr)
    let self.changenr = l:changenr
    if has_key(self.changenrs, l:changenr)
      let self.tabstop = self.changenrs[l:changenr].tabstop
      let self.snippet = self.changenrs[l:changenr].snippet
      let self.changenr = l:changenr
      let self.buffer = getbufline(self.bufnr, '^', '$')
      return
    endif
  endif

  let l:fn = {}
  function! l:fn.debounce(timer_id) abort
    " compute diff.
    let l:buffer = getbufline(self.bufnr, '^', '$')
    let l:diff = vsnip#edits#diff#compute(self.buffer, l:buffer)
    let self.buffer = l:buffer
    if l:diff.rangeLength == 0 && l:diff.text ==# ''
      return
    endif

    " text edit is out of range.
    let l:range = self.snippet.range()
    if l:diff.range.end.line < l:range.start.line || l:range.end.line < l:diff.range.start.line
      call vsnip#deactivate()
      return
    endif
    if l:diff.range.end.line == l:range.start.line && l:diff.range.end.character < l:range.start.character
      call vsnip#deactivate()
      return
    endif
    if l:diff.range.start.line == l:range.end.line && l:range.end.character < l:diff.range.start.character
      call vsnip#deactivate()
      return
    endif

    " snippet text is not changed.
    if !self.is_dirty(l:buffer)
      return
    endif

    " if follow succeeded, sync placeholders and write back to the buffer.
    if self.snippet.follow(self.tabstop, l:diff)
      undojoin | call vsnip#edits#text_edit#apply(self.bufnr, self.snippet.sync())
      let self.buffer = getbufline(self.bufnr, '^', '$')
    else
      call vsnip#deactivate()
    endif
  endfunction

  " if delay is not zero, should debounce.
  if g:vsnip_sync_delay == 0
    call call(l:fn.debounce, [0], self)
  else
    call timer_stop(self.timer_id)
    let self.timer_id = timer_start(g:vsnip_sync_delay, function(l:fn.debounce, [], self), { 'repeat': 1 })
  endif
endfunction

"
" save.
"
function! s:Session.store(changenr) abort
  let self.changenrs[a:changenr] = {
        \   'tabstop': self.tabstop,
        \   'snippet': deepcopy(self.snippet)
        \ }
endfunction

"
" is_dirty.
"
function! s:Session.is_dirty(buffer) abort
  return self.snippet.text() !=# self.text_from_buffer(a:buffer)
endfunction

"
" text_from_buffer.
"
function! s:Session.text_from_buffer(buffer) abort
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

  return l:text
endfunction

"
" indent.
"
function! s:Session.indent(text) abort
  let l:indent = !&expandtab ? "\t" : repeat(' ', &shiftwidth ? &shiftwidth : &tabstop)
  let l:level = matchstr(getline('.'), '^\s*')
  let l:text = a:text
  let l:text = substitute(l:text, "\t", l:indent, 'g')
  let l:text = substitute(l:text, "\n\\zs", l:level, 'g')
  let l:text = substitute(l:text, "\n\\s*\\ze\n", "\n", 'g')
  return l:text
endfunction

