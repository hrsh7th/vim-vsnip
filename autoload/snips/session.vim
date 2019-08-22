function! snips#session#activate(prefix, snippet)
  let l:session = s:Session.new(a:prefix, a:snippet)
  call l:session.activate()
  return l:session
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
  execute printf('noautocmd normal! %dh', strlen(self.prefix))
  execute printf('noautocmd normal! %dx', strlen(self.prefix))
  let self.state = s:new_state(self.snippet)
endfunction

function! s:Session.jumpable()
  return !empty(get(self.state.placeholders, self.state.current_idx + 1, {}))
endfunction

function! s:Session.jump()
  let self.state.current_idx = self.state.current_idx + 1
  let l:placeholder = get(self.state.placeholders, self.state.current_idx, {})
  if empty(l:placeholder)
    return
  endif

  let l:pos = snips#utils#compute_pos(self.state.start, l:placeholder['start'], self.state.text)
  call cursor(l:pos)

  if l:placeholder['end'] > 0
    execute printf('noautocmd normal! %dlgh', l:placeholder['end'] - 1)
    call cursor(l:pos)
  endif
endfunction

function! s:Session.expand()
  let l:save_paste = &paste
  let l:save_pos = getcurpos()

  set paste
  call setpos('.', self.state.start)
  execute printf('noautocmd normal! i%s', self.state.text)

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

