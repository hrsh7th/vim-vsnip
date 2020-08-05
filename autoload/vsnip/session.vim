let s:Snippet = vsnip#snippet#import()
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
  \   'changedtick': getbufvar(a:bufnr, 'changedtick', 0),
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
" merge.
"
function! s:Session.merge(session) abort
  call a:session.insert()

  " increase new snippet's tabstop by current snippet's current tabstop
  let l:offset = 1
  let l:tabstop_map = {}
  for l:node in a:session.snippet.get_placeholder_nodes()
    if !has_key(l:tabstop_map, l:node.id)
      let l:tabstop_map[l:node.id] = self.tabstop + l:offset
    endif
    let l:node.id = l:tabstop_map[l:node.id]
    let l:offset += 1
  endfor
  let l:tail = l:node

  " re-assign current snippet's tabstop by new snippet's final tabstop
  let l:offset = 1
  let l:tabstop_map = {}
  for l:node in self.snippet.get_placeholder_nodes()
    if l:node.id > self.tabstop
      if !has_key(l:tabstop_map, l:node.id)
        let l:tabstop_map[l:node.id] = l:tail.id + l:offset
      endif
      let l:node.id = l:tabstop_map[l:node.id]
      let l:offset += 1
    endif
  endfor

  call self.snippet.insert_node(deepcopy(a:session.snippet.position), a:session.snippet.children)

  call s:TextEdit.apply(self.bufnr, self.snippet.sync())
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
  return l:jumpable
endfunction

"
" jump.
"
function! s:Session.jump(direction) abort
  call self.flush_changes()

  if a:direction == 1
    let l:jump_point = self.snippet.get_next_jump_point(self.tabstop)
  else
    let l:jump_point = self.snippet.get_prev_jump_point(self.tabstop)
  endif

  if empty(l:jump_point)
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
  call self.move(a:jump_point)

  let l:fn = {}
  let l:fn.jump_point = a:jump_point
  function! l:fn.next_tick() abort
    if mode()[0] ==# 'i'
      let l:pos = s:Position.lsp_to_vim('%', self.jump_point.range.start)
      call complete(l:pos[1], map(copy(self.jump_point.placeholder.choice), { k, v -> {
      \   'word': v.escaped,
      \   'abbr': v.escaped,
      \   'menu': '[vsnip]',
      \   'kind': 'Choice'
      \ } }))
    endif
  endfunction
  call timer_start(g:vsnip_choice_delay, { -> l:fn.next_tick() })
endfunction

"
" select.
"
" @NOTE: Must work even if virtualedit=all/onmore or not.
"
function! s:Session.select(jump_point) abort
  let l:pos = s:Position.lsp_to_vim('%', a:jump_point.range.end)
  call cursor([l:pos[0], l:pos[1] - 1]) " Use `a:jump_point.range.end as inclusive position

  let l:select_length = strlen(a:jump_point.placeholder.text()) - 1
  let l:cmd = ''
  let l:cmd .= mode()[0] ==# 'i' ? "\<Esc>l" : ''
  let l:cmd .= printf('v%sh', l:select_length)
  let l:cmd .= "o\<C-g>"
  if get(g:, 'vsnip_test_mode', v:false)
    execute printf('normal! %s', l:cmd)
  else
    call feedkeys(l:cmd, 'nt')
  endif
endfunction

"
" move.
"
" @NOTE: Must work even if virtualedit=all/onmore or not.
"
function! s:Session.move(jump_point) abort
  let l:pos = s:Position.lsp_to_vim('%', a:jump_point.range.end)

  call cursor(l:pos)

  if l:pos[1] > strlen(getline(l:pos[0]))
    startinsert!
  else
    startinsert
  endif
endfunction

"
" refresh
"
function! s:Session.refresh() abort
  let self.buffer = getbufline(self.bufnr, '^', '$')
  let self.changedtick = getbufvar(self.bufnr, 'changedtick', 0)
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

  if g:vsnip_sync_delay == 0
    call self.flush_changes()
  else
    call timer_stop(self.timer_id)
    let self.timer_id = timer_start(g:vsnip_sync_delay, { -> self.flush_changes() }, { 'repeat': 1 })
  endif
endfunction

"
" flush_changes
"
function! s:Session.flush_changes() abort
  let l:changedtick = getbufvar(self.bufnr, 'changedtick', 0)
  if self.changedtick == l:changedtick
    return
  endif
  let self.changedtick = l:changedtick

  " compute diff.
  let l:buffer = getbufline(self.bufnr, '^', '$')
  let l:diff = s:Diff.compute(self.buffer, l:buffer)
  let self.buffer = l:buffer
  if l:diff.rangeLength == 0 && l:diff.text ==# ''
    return
  endif

  " if follow succeeded, sync placeholders and write back to the buffer.
  if self.snippet.follow(self.tabstop, l:diff)
    try
      let l:text_edits = self.snippet.sync()
      if len(l:text_edits) > 0
        undojoin | call s:TextEdit.apply(self.bufnr, l:text_edits)
      endif
      call self.refresh()
    catch /.*/
      " TODO: More strict changenrs mangement.
      call vsnip#deactivate()
    endtry
  else
    call vsnip#deactivate()
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

