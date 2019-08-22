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

  " replace variables.
  let l:match_start = 0
  while 1
    let [l:variable, l:start, l:end] = matchstrpos(l:state.text, g:snips#utils#variable_regexp, l:match_start, 1)
    if empty(l:variable)
      break
    endif
    let l:before = strpart(l:state.text, 0, l:start)
    let l:after = strpart(l:state.text, l:end, strlen(l:state.text))
    let l:resolved_variable = snips#utils#resolve_variable(l:variable)
    let l:state.text = l:before . l:resolved_variable . l:after
    let l:match_start = strlen(l:before . l:resolved_variable)
  endwhile

  " initialize placeholders.
  let l:match_start = 0
  while 1
    let [l:placeholder, l:start, l:end] = matchstrpos(l:state.text, g:snips#utils#placeholder_regexp, l:match_start, 1)
    if empty(l:placeholder)
      break
    endif

    let l:before = strpart(l:state.text, 0, l:start)
    let l:after = strpart(l:state.text, l:end, strlen(l:state.text))
    let l:resolved_placeholder = snips#utils#resolve_placeholder(l:placeholder)
    let l:state.text = l:before . l:resolved_placeholder['default'] . l:after
    call add(l:state.placeholders, {
          \   'order': l:resolved_placeholder['order'],
          \   'start': l:start,
          \   'end': strlen(l:resolved_placeholder['default'])
          \ })
    let l:match_start = strlen(l:before . l:resolved_placeholder['default'])
  endwhile
  let l:state.placeholders = snips#utils#sort_placeholders(l:state.placeholders)
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

