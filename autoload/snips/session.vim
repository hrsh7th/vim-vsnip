function! snips#session#new(prefix, snippet)
  return s:Session.new(a:prefix, a:snippet)
endfunction

let s:Session = {}

"
" Create session instance.
"
function! s:Session.new(prefix, snippet)
  return extend(deepcopy(s:Session), {
        \   'prefix': a:prefix,
        \   'snippet': a:snippet,
        \   'state': {}
        \ })
endfunction

"
" Expand snippet body.
"
function! s:Session.expand()
  let l:saved_vedit = &virtualedit
  set virtualedit=all

  execute printf('noautocmd normal! %dh%dx', strlen(self.prefix) - 1, strlen(self.prefix))
  let self.state = s:create_state(self.snippet)

  let l:saved_paste = &paste
  set paste
  execute printf('noautocmd normal! i%s', self.state.text)
  call cursor(self.state.startpos)

  let &paste = l:saved_paste
  let &virtualedit = l:saved_vedit
endfunction

"
" Check jump marker enabled.
"
function! s:Session.jumpable()
  let self.state = s:sync_state(self.state, getline('^', '$'))
  return !empty(get(self.state.placeholders, self.state.current_idx + 1, {}))
endfunction

"
" Jump to next pos.
"
function! s:Session.jump()
  let l:save_vedit = &virtualedit
  set virtualedit=all

  " sync state.
  let self.state = s:sync_state(self.state, getline('^', '$'))

  " get placeholder.
  let self.state.current_idx = self.state.current_idx + 1
  let l:placeholder = get(self.state.placeholders, self.state.current_idx, {})
  if empty(l:placeholder)
    return
  endif

  " move & select.
  let l:pos = snips#utils#compute_pos(self.state.startpos, l:placeholder['start'], self.state.text)
  call cursor(l:pos)
  if l:placeholder['end'] > 0
    execute printf('noautocmd normal! %dlgh', l:placeholder['end'] - 1)
    call cursor(l:pos)
  else
    startinsert
  endif

  let &virtualedit = l:save_vedit
endfunction

"
" Create state.
"
function! s:create_state(snippet)
  let l:state = {
        \ 'buffer': getbufline('^', '$'),
        \ 'startpos': snips#utils#curpos(),
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

"
" Sync state.
"
function! s:sync_state(state, buffer)
  return a:state
endfunction

