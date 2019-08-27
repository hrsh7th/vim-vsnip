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
  call snips#utils#edit#select_or_insert(l:placeholder['range'])
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
" - 複数行の変更に対応していない
" - InsertCharPre にしか対応していない
" - range の inclusive/exclusive が怪しい
"
function! s:sync_state(state, vimdiff)
  let l:snippet_text = join(a:state['lines'], "\n")
  let l:snippet_range = {
        \   'start': a:state['start_position'],
        \   'end': snips#utils#text_index2buffer_pos(a:state['start_position'], strlen(l:snippet_text), l:snippet_text)
        \ }
  if !snips#utils#range#in(l:snippet_range, a:vimdiff['range'])
    let a:state['running'] = v:false
    return a:state
  endif

  let l:placeholders = snips#syntax#placeholder#by_order(a:state['placeholders'])

  " 変更されたプレースホルダと、それと同じ行に存在するプレースホルダの再配置（複数行には対応していない）
  let l:target = {}
  let l:old_length = 0
  let l:new_length = 0

  let l:i = 0
  while l:i < len(l:placeholders)
    let l:p = l:placeholders[l:i]

    " relocate target placeholder.
    if snips#utils#range#in(l:p['range'], a:vimdiff['range'])
      let l:old_length = l:p['range']['end'][1] - l:p['range']['start'][1]
      echomsg string([char2nr(v:char)])
      let l:p['text'] = char2nr(a:vimdiff['text']) == 29 ? l:p['text'][0 : -2] : l:p['text'] . a:vimdiff['text']
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

  " プレースホルダの変更を、同じ tabstop のものに同期する
  if !empty(l:target)
    let l:in_sync = {}
    let l:edits = []
    let l:i = 0
    while l:i < len(l:placeholders)
      let l:p = l:placeholders[l:i]

      " ignore reallocated placeholder.
      if l:p['order'] == l:target['order']
        let l:i += 1
        continue
      endif

      " relocate same tabstop.
      if l:p['tabstop'] == l:target['tabstop']
        let l:in_sync = l:p
        call add(l:edits, {
              \   'range': deepcopy(l:p['range']),
              \   'lines': split(l:target['text'], "\n", v:true)
              \ })
        let l:p['range']['end'][1] += (l:new_length - l:old_length)
        let l:p['text'] = l:target['text']
        let l:i += 1
        continue

      " relocate after in_sync.
      elseif !empty(l:in_sync)
        if l:p['range']['start'][0] == l:in_sync['range']['start'][0]
          let l:p['range']['start'][1] += (l:new_length - l:old_length)
          let l:p['range']['end'][1] += (l:new_length - l:old_length)
        endif
      endif

      let l:i += 1
    endwhile

    " can't modify buffer in `InsertCharPre`.
    function! s:apply_edits(edits, timer_id)
      for l:edit in a:edits
        call snips#utils#edit#replace_buffer(l:edit['range'], l:edit['lines'])
      endfor
    endfunction
    call timer_start(0, function('s:apply_edits', [l:edits]), { 'repeat': 1 })
  endif

  return a:state
endfunction

