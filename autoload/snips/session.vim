let s:session = {}

function! snips#session#activate(prefix, snippet)
  let s:session = s:Session.new(a:prefix, a:snippet)
  call s:session.activate()
endfunction

function! snips#session#jumpable()
  if empty(s:session)
    return
  endif
  return s:session.jumpable()
endfunction

function! snips#session#jump()
  if empty(s:session)
    return
  endif
  call s:session.jump()
endfunction

function! snips#session#expand()
  if empty(s:session)
    return
  endif
  call s:session.expand()
  call s:session.jump()
endfunction

let s:Session = {}

function! s:Session.new(prefix, snippet)
  return extend(deepcopy(s:Session), {
        \   'prefix': a:prefix,
        \   'snippet': a:snippet,
        \   'state': {
        \     'start': { 'lnum': 0, 'col': 0 },
        \     'buffer': [],
        \     'text': '',
        \     'current_idx': -1,
        \     'placeholders': [],
        \   }
        \ })
endfunction

function! s:Session.activate()
  " remove prefix
  execute printf('noautocmd normal! %dh', strlen(self.prefix))
  execute printf('noautocmd normal! %dx', strlen(self.prefix))

  " initialize state.
  let self.state = s:new_state(self.snippet)
endfunction

function! s:Session.jumpable()
  let l:placeholder = get(self.state.placeholders, self.state.current_idx + 1, {})
  return !empty(l:placeholder)
endfunction

function! s:Session.jump()
  let self.state.current_idx = self.state.current_idx + 1
  let l:placeholder = get(self.state.placeholders, self.state.current_idx, {})
  if empty(l:placeholder)
    return
  endif

  let [l:lnum, l:col] = s:getpos(self.state, l:placeholder['start'])
  call cursor([l:lnum, l:col])

  if l:placeholder['end'] > 0
    execute printf('normal! %dlgh', l:placeholder['end'] - 1)
    call cursor([l:lnum, l:col])
  endif
endfunction

function! s:Session.expand()
  " store state.
  let l:save_paste = &paste
  let l:save_pos = getcurpos()

  set paste
  call setpos('.', self.state.start)
  execute printf('noautocmd normal! i%s', self.state.text)

  " restore state.
  call setpos('.', l:save_pos)
  let &paste = l:save_paste
endfunction

function! s:new_state(snippet)
  let l:state = {
        \ 'buffer': getbufline('^', '$'),
        \ 'start': { 'lnum': line('.'), 'col': col('.') },
        \ 'text': '',
        \ 'current_idx': -1,
        \ 'placeholders': [],
        \ }

  " create texts
  let l:indent = snips#utils#get_indent()
  let l:level = strchars(substitute(matchstr(getline('.'), '^\s*'), l:indent, '_', 'g'))
  let l:text = join(a:snippet['body'], "\n")
  let l:text = substitute(l:text, "\t", l:indent, 'g')
  let l:text = substitute(l:text, "\n", "\n" . repeat(l:indent, l:level), 'g')
  let l:text = substitute(l:text, "\n\\s\\+\\ze\n", "\n", 'g')
  let l:state.text = l:text

  " resolve variables.
  let l:state.text = snips#syntax#variable#resolve(l:state.text)

  " resolve placeholders.
  let [l:text, l:placeholders] = snips#syntax#placeholder#resolve(l:state.text)
  let l:state.text = l:text
  let l:state.placeholders = l:placeholders

  return l:state
endfunction

function! s:sync_state(state)
  let l:diffs = lsp#utils#diffs(a:state.buffer, getline('^', '$'))
endfunction

function! s:getpos(state, start)
  let l:lines = split(strpart(a:state.text, 0, a:start), "\n")
  let l:offset_lnum = len(l:lines) - 1
  let l:offset_col = strlen(l:lines[-1])
  let l:lnum = a:state.start.lnum + l:offset_lnum
  let l:col = (l:offset_lnum == 0 ? a:state.start.col : 1) + l:offset_col
  return [lnum, l:col]
endfunction

