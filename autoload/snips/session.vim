let s:session = {}

function! snips#session#activate(prefix, snippet)
  let s:session = s:Session.new(a:prefix, a:snippet)
  call s:session.activate()
endfunction

let s:Session = {}

function! s:Session.new(prefix, snippet)
  return extend(deepcopy(s:Session), {
        \   'prefix': a:prefix,
        \   'snippet': a:snippet,
        \   'state': {
        \     'start': { 'lnum': 0, 'col': 0 },
        \     'text': '',
        \     'placeholders': [],
        \     'tabstops': [],
        \   }
        \ })
endfunction

function! s:Session.activate()
  " remove prefix
  execute printf('noautocmd normal! %dh', strlen(self.prefix))
  execute printf('noautocmd normal! %dx', strlen(self.prefix))

  " initialize state.
  let self.state = s:create_state(self.snippet)

  " apply state.
  call self.apply()
endfunction

function! s:Session.apply()
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

function! s:create_state(snippet)
  let l:state = {
        \ 'start': { 'lnum': line('.'), 'col': col('.') },
        \ 'text': '',
        \ 'placeholders': [],
        \ 'tabstops': []
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

  return l:state
endfunction

