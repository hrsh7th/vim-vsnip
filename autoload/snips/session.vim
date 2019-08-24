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
  execute printf('noautocmd normal! i%s', self['state']['text'])
  call cursor(self['state']['startpos'])
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
  let l:pos = snips#utils#textpos2bufferpos(self['state']['startpos'], l:placeholder['start'], self['state']['text'])
  call cursor(l:pos)
  if l:placeholder['end'] > 0
    execute printf('noautocmd normal! %sgh', repeat('l', l:placeholder['end'] - 1))
    call cursor(l:pos)
  else
    startinsert
  endif

  let &virtualedit = l:save_vedit
endfunction

"
"  Handle text changed.
"
function! s:Session.on_text_changed()
  if snips#utils#get(self, ['state', 'running'], v:false)
    let self.state = s:sync_state(self.state, getline('^', '$'))
  endif
endfunction

"
" Create state.
"
function! s:create_state(snippet)
  let l:state = {
        \ 'running': v:false,
        \ 'buffer': [],
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
  let l:state['text'] = l:text

  " resolve variables.
  let l:state['text'] = snips#syntax#variable#resolve(l:state['text'])

  " resolve placeholders.
  let [l:text, l:placeholders] = snips#syntax#placeholder#resolve(l:state['text'])
  let l:state['text'] = l:text
  let l:state['placeholders'] = l:placeholders

  return l:state
endfunction

"
" Sync state.
"
function! s:sync_state(state, new_buffer)
  let l:state = a:state
  let l:old = l:state['buffer']
  let l:old_text = join(l:old, "\n")
  let l:new = a:new_buffer
  let l:new_text = join(l:new, "\n")
  let l:parts = split(l:new_text, l:state['text'])

  let l:is_changed_in_range = len(l:parts) == 1
  if l:is_changed_in_range
    let l:state = s:sync_diff_state(l:state, snips#utils#diff(l:old, l:new))
  else
    let l:state['running'] = v:false
  endif

  " update buffer.
  let l:state['buffer'] = a:new_buffer

  return l:state
endfunction

"
" 1. placeholder の範囲が壊れる修正の場合は deactivate して終了
" 2. 変更された placeholder を特定して、再配置する
" 3. placeholders を `order` 順でループして、同一 placeholder であれば編集する、全て再配置する
"
function! s:sync_diff_state(state, diff)
  return a:state
endfunction

