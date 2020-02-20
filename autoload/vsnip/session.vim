let s:Snippet = vsnip#session#snippet#import()
let s:TextEdit = vital#vsnip#import('VS.LSP.TextEdit')
let s:Position = vital#vsnip#import('VS.LSP.Position')
let s:Diff = vital#vsnip#import('VS.Text.Diff')

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
  call s:TextEdit.apply(self.bufnr, [{
        \   'range': {
        \     'start': self.snippet.position,
        \     'end': self.snippet.position
        \   },
        \   'newText': self.snippet.text()
        \ }])
  call self.store(changenr())
endfunction

"
" jumpable.
"
function! s:Session.jumpable(direction) abort
  if a:direction == 1
    let l:jumpable = !empty(self.snippet.get_next_jump_point(self.tabstop))
  else
    let l:jumpable = !empty(self.snippet.get_prev_jump_point(self.tabstop))
  endif
  if !l:jumpable
    call vsnip#deactivate()
  endif
  return l:jumpable
endfunction

"
" jump.
"
function! s:Session.jump(direction) abort
  if a:direction == 1
    let l:jump_point = self.snippet.get_next_jump_point(self.tabstop)
  else
    let l:jump_point = self.snippet.get_prev_jump_point(self.tabstop)
  endif

  if empty(l:jump_point)
    call vsnip#deactivate()
    return
  endif

  let self.tabstop = l:jump_point.placeholder.id

  " choice.
  if len(l:jump_point.placeholder.choice) > 0
    call self.choice(l:jump_point)

  " select.
  elseif l:jump_point.range.start.character != l:jump_point.range.end.character
    call self.select(l:jump_point)

  " move.
  else
    call self.move(l:jump_point)
  endif
endfunction

"
" choice.
"
function! s:Session.choice(jump_point) abort
  call cursor(s:Position.lsp_to_vim('%', a:jump_point.range.end))
  startinsert

  let l:fn = {}
  let l:fn.jump_point = a:jump_point
  function! l:fn.next_tick() abort
    let l:pos = s:Position.lsp_to_vim('%', self.jump_point.range.start)
    call complete(l:pos[1], map(copy(self.jump_point.placeholder.choice), { k, v -> {
          \   'word': v.escaped,
          \   'abbr': v.escaped,
          \   'menu': '[vsnip]',
          \   'kind': 'Choice'
          \ } }))
  endfunction
  call timer_start(g:vsnip_choice_delay, { -> l:fn.next_tick() })
endfunction

"
" select.
"
function! s:Session.select(jump_point) abort
  " `virtualedit=onemore` is restored by `plugin/vsnip.vim` before invoke `feedkeys` contents. (feedkeys is not synchronous.)
  " So using `range.end.character` as inclusive position in here.
  " Do not worry to first position of line, `select` has always have text.
  let l:pos = s:Position.lsp_to_vim('%', a:jump_point.range.end)
  call cursor([l:pos[0], l:pos[1] - 1])
  let l:select_length = strchars(a:jump_point.placeholder.text()) - 1
  let l:cmd = mode()[0] ==# 'i' ? "\<Esc>l" : ''
  if l:select_length > 0
    let l:cmd .= printf('v%sh', l:select_length)
  else
    let l:cmd .= 'v'
  endif
  let l:cmd .= "\<C-g>"
  call feedkeys(l:cmd, 'nt')
endfunction

"
" move.
"
function! s:Session.move(jump_point) abort
  call cursor(s:Position.lsp_to_vim('%', a:jump_point.range.end))
  startinsert
endfunction

"
" on_text_changed.
"
function! s:Session.on_text_changed() abort
  if self.bufnr != bufnr('%')
    return vsnip#deactivate()
  endif

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
    let l:diff = s:Diff.compute(self.buffer, l:buffer)
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
    if !self.is_dirty(l:buffer, l:diff)
      return
    endif

    " if follow succeeded, sync placeholders and write back to the buffer.
    if self.snippet.follow(self.tabstop, l:diff)
      try
        undojoin | call s:TextEdit.apply(self.bufnr, self.snippet.sync())
        let self.buffer = getbufline(self.bufnr, '^', '$')
      catch /.*/
        " TODO: More strict changenrs mangement.
        call vsnip#deactivate()
      endtry
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
function! s:Session.is_dirty(buffer, diff) abort
  return self.snippet.text() !=# self.text_from_buffer(a:buffer, a:diff)
endfunction

"
" text_from_buffer.
"
function! s:Session.text_from_buffer(buffer, diff) abort
  let l:range = self.snippet.range()

  if a:diff.range.end.line == l:range.end.line
    let l:range.end.character = max([l:range.end.character, a:diff.range.end.character + strchars(a:diff.text) + 1])
  endif

  let l:text = ''
  for l:i in range(l:range.start.line, l:range.end.line)
    if len(a:buffer) <= l:i
      return v:true
    endif

    " same line.
    if l:i == l:range.start.line && l:i == l:range.end.line
      let l:text = strcharpart(a:buffer[l:i], l:range.start.character, l:range.end.character - l:range.start.character)
      break

    " multi start.
    elseif l:i == l:range.start.line
      let l:text .= strcharpart(a:buffer[l:i], l:range.start.character, strchars(a:buffer[l:i]) - l:range.start.character) . "\n"

    " multi middle.
    elseif l:i != l:range.end.line
      let l:text .= a:buffer[l:i] . "\n"

    " multi end.
    elseif l:i == l:range.end.line
      let l:text .= strcharpart(a:buffer[l:i], 0, l:range.end.character)
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
  let l:text = substitute(l:text, "\n\\s*\\ze\\(\n\\|$\\)", "\n", 'g')
  return l:text
endfunction

