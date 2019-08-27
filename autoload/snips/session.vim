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
        \   'state': {
        \     'running': v:false
        \   }
        \ })
endfunction

"
" Expand snippet body.
"
function! s:Session.expand()
  let l:saved_vedit = &virtualedit
  set virtualedit=all

  " remove prefix.
  execute printf('noautocmd normal! %s%s', repeat('h', strlen(self['prefix']) - 1), repeat('x', strlen(self['prefix'])))
  let self['state'] = s:create_state(self['snippet'])

  " expand snippet.
  let l:saved_paste = &paste
  set paste
  execute printf('noautocmd normal! i%s', join(self['state']['lines'], "\n"))
  call cursor(self['state']['start_position'])
  let &paste = l:saved_paste

  " update state.
  let self['state']['running'] = v:true
  let self['state']['buffer'] = getline('^', '$')

  let &virtualedit = l:saved_vedit
endfunction

"
" Check jump marker enabled.
"
function! s:Session.jumpable()
  let l:running = snips#utils#get(self, ['state', 'running'], v:false)
  let l:has_next = !empty(snips#utils#get(self, ['state', 'placeholders', self['state']['current_idx'] + 1], {}))
  return l:running && l:has_next
endfunction


"
" Jump to next pos.
"
function! s:Session.jump()
  let l:save_vedit = &virtualedit
  set virtualedit=all

  " get placeholder.
  let self['state']['current_idx'] = self['state']['current_idx'] + 1
  let l:placeholder = get(self['state']['placeholders'], self['state']['current_idx'], {})
  if empty(l:placeholder)
    return
  endif

  " move & select.
  let l:length = l:placeholder['range']['end'][1] - l:placeholder['range']['start'][1]
  call cursor(l:placeholder['range']['start'])
  if l:length > 0
    execute printf('noautocmd normal! %sgh', repeat('l', l:length - 1))
    call cursor(l:placeholder['range']['start'])
  else
    startinsert
  endif

  let &virtualedit = l:save_vedit
endfunction

"
"  Handle text changed.
"
function! s:Session.on_insert_char_pre(char)
  if snips#utils#get(self, ['state', 'running'], v:false)
    let self.state = s:sync_state(self.state, {
          \   'range': {
          \     'start': [line('.'), col('.')],
          \     'end': [line('.'), col('.')]
          \   },
          \   'text': a:char
          \ })
  endif
endfunction

"
" Create state.
"
function! s:create_state(snippet)
  let l:state = {
        \ 'running': v:false,
        \ 'buffer': [],
        \ 'start_position': snips#utils#curpos(),
        \ 'lines': [],
        \ 'current_idx': -1,
        \ 'placeholders': [],
        \ }

  " create body
  let l:indent = snips#utils#get_indent()
  let l:level = strchars(substitute(matchstr(getline('.'), '^\s*'), l:indent, '_', 'g'))
  let l:body = join(a:snippet['body'], "\n")
  let l:body = substitute(l:body, "\t", l:indent, 'g')
  let l:body = substitute(l:body, "\n", "\n" . repeat(l:indent, l:level), 'g')
  let l:body = substitute(l:body, "\n\\s\\+\\ze\n", "\n", 'g')

  " resolve variables.
  let l:body = snips#syntax#variable#resolve(l:body)

  " resolve placeholders.
  let [l:body, l:placeholders] = snips#syntax#placeholder#resolve(l:state['start_position'], l:body)
  let l:state['placeholders'] = l:placeholders
  let l:state['lines'] = split(l:body, "\n", v:true)

  return l:state
endfunction

"
" Sync state.
"
function! s:sync_state(state, diff)
  let l:placeholders = snips#syntax#placeholder#by_order(a:state['placeholders'])

  " reallocate target with same line.
  let l:target = {}
  let l:old_length = 0
  let l:new_length = 0

  let l:i = 0
  while l:i < len(l:placeholders)
    let l:p = l:placeholders[l:i]

    " relocate target placeholder.
    if snips#utils#range#in(l:p['range'], a:diff['range'])
      let l:old_length = l:p['range']['end'][1] - l:p['range']['start'][1]
      let l:p['text'] = l:p['text'] . a:diff['text']
      let l:p['range']['end'] = [l:p['range']['start'][0], l:p['range']['start'][1] + strlen(l:p['text'])]
      let l:new_length = l:p['range']['end'][1] - l:p['range']['start'][1]
      let l:target = l:p

    " relocate placeholder after target.
    elseif !empty(l:target)
      if l:p['range']['start'][0] == l:target['range']['start'][0]
        let l:p['range']['start'][1] += (l:new_length - l:old_length)
        let l:p['range']['end'][1] += (l:new_length - l:old_length)
      endif
    endif

    let l:i += 1
  endwhile

  return a:state
endfunction

