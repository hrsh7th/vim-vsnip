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
  let l:curpos = snips#utils#curpos()
  call snips#utils#edit#replace_buffer({
        \   'start': [l:curpos[0], l:curpos[1] - strlen(self.prefix) + 1],
        \   'end': [l:curpos[0], l:curpos[1] + 1]
        \ }, [''])
  let self['state'] = s:create_state(self['snippet'])

  " expand snippet.
  call snips#utils#edit#replace_buffer({
        \   'start': self['state']['start_position'],
        \   'end': self['state']['start_position']
        \ }, self['state']['lines'])

  " update state.
  let self['state']['running'] = v:true
  let self['state']['buffer'] = getline('^', '$')

  let &virtualedit = l:saved_vedit
endfunction

"
" Check jump marker enabled.
"
function! s:Session.jumpable()
  if !snips#utils#get(self, ['state', 'running'], v:false)
    return v:false
  endif

  let [l:idx, l:next] = s:find_next_placeholder(self['state']['current_idx'], self['state']['placeholders'])
  return !empty(l:next)
endfunction

"
" Jump to next pos.
"
function! s:Session.jump()
  let l:save_vedit = &virtualedit
  set virtualedit=all

  " get placeholder.
  if !snips#utils#get(self, ['state', 'running'], v:false)
    return v:false
  endif

  let [l:idx, l:next] = s:find_next_placeholder(self['state']['current_idx'], self['state']['placeholders'])
  if empty(l:next)
    return
  endif

  let self['state']['current_idx'] = l:idx

  " move & select.
  call snips#utils#edit#select_or_insert(l:next['range'])
  let &virtualedit = l:save_vedit
endfunction

"
"  Handle text changed.
"  TODO: implement
"
" function! s:Session.on_text_changed_i()
"   if snips#utils#get(self, ['state', 'running'], v:false)
"     let l:is_backspace = char2nr(a:char) == 29
"     let self['state'] = s:sync_state(self['state'], {
"           \   'range': {
"           \     'start': [line('.'), col('.') - (l:is_backspace ? 1 : 0)],
"           \     'end': [line('.'), col('.')]
"           \   },
"           \   'lines': [l:is_backspace ? '' : a:char]
"           \ })
"     let self['state']['buffer'] = getline('^', '$')
"   endif
" endfunction

"
"  Handle text changed.
"
function! s:Session.on_insert_char_pre(char)
  if snips#utils#get(self, ['state', 'running'], v:false)
    let l:is_backspace = char2nr(a:char) == 29
    let self['state'] = s:sync_state(self['state'], {
          \   'range': {
          \     'start': [line('.'), col('.') - (l:is_backspace ? 1 : 0)],
          \     'end': [line('.'), col('.')]
          \   },
          \   'lines': [l:is_backspace ? '' : a:char]
          \ })
    let self['state']['buffer'] = getline('^', '$')
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
" - 複数行の変更に対応していない
"
function! s:sync_state(state, vimdiff)
  let l:placeholders = snips#syntax#placeholder#by_order(a:state['placeholders'])

  " fix placeholder ranges after already modified placeholder.
  let l:target = {}
  let l:i = 0
  let l:j = len(l:placeholders)
  while l:i < len(l:placeholders)
    let l:p = l:placeholders[l:i]

    " relocate same lines.
    if !empty(l:target)
      if l:p['range']['start'][0] == l:target['range']['start'][0]
        let l:p['range']['start'][1] += l:shiftwidth
        let l:p['range']['end'][1] += l:shiftwidth
      else
        break
      endif
    endif

    " modified placeholder.
    if snips#utils#range#in(l:p['range'], a:vimdiff['range'])
      let l:new_lines = snips#utils#edit#replace_text(
            \   split(l:p['text'], "\n", v:true),
            \   snips#utils#range#truncate(l:p['range']['start'], a:vimdiff['range']),
            \   a:vimdiff['lines']
            \ )
      let l:new_text = join(l:new_lines, "\n")

      " TODO: support multi-line.
      let l:old_length = l:p['range']['end'][1] - l:p['range']['start'][1]
      let l:new_length = strlen(l:new_text)
      let l:shiftwidth = l:new_length - l:old_length
      let l:p['text'] = l:new_text
      let l:p['range']['end'][1] += l:shiftwidth
      let l:target = l:p
      let l:j = l:i + 1
    endif

    let l:i += 1
  endwhile

  " sync same tabstop placeholder.
  let l:in_sync = {}
  let l:same_lines = 0
  let l:edits = []
  while l:j < len(l:placeholders)
    let l:p = l:placeholders[l:j]

    let l:is_same_line_in_sync = !empty(l:in_sync) && l:p['range']['start'][0] == l:in_sync['range']['start'][0]

    if l:p['tabstop'] == l:target['tabstop']
      call add(l:edits, {
            \   'range': deepcopy(l:p['range']),
            \   'lines': l:new_lines
            \ })
      let l:p['text'] = l:target['text']
      let l:p['range']['end'][1] += l:shiftwidth
      let l:in_sync = l:p
    endif

    if l:is_same_line_in_sync
      let l:same_lines += 1
      let l:p['range']['start'][1] += l:shiftwidth * l:same_lines
      let l:p['range']['end'][1] += l:shiftwidth * l:same_lines
    else
      let l:same_lines = 0
    endif

    let l:j += 1
  endwhile

  function! s:apply_edits(edits, timer_id)
    for l:edit in reverse(a:edits)
      call snips#utils#edit#replace_buffer(l:edit['range'], l:edit['lines'])
    endfor
  endfunction
  call timer_start(0, function('s:apply_edits', [l:edits]), { 'repeat': 1 })

  return a:state
endfunction

"
" find next placeholder.
"
function! s:find_next_placeholder(current_idx, placeholders)
  if len(a:placeholders) == 0
    return [-1, {}]
  endif
  if a:current_idx == -1
    return [0, a:placeholders[0]]
  endif

  let l:current = a:placeholders[a:current_idx]
  let l:i = a:current_idx + 1
  while l:i < len(a:placeholders)
    let l:p = a:placeholders[l:i]
    if l:current['tabstop'] != l:p['tabstop']
      return [l:i, l:p]
    endif
    let l:i += 1
  endwhile
  return [-1, {}]
endfunction

