function! vsnip#session#new(snippet)
  return s:Session.new(a:snippet)
endfunction

let s:Session = {}

"
" Create session instance.
"
function! s:Session.new(snippet)
  return extend(deepcopy(s:Session), {
        \   'snippet': a:snippet,
        \   'state': vsnip#state#create(a:snippet)
        \ })
endfunction

"
" Expand snippet body.
"
function! s:Session.expand()
  " expand snippet.
  call vsnip#utils#edit#replace_buffer({
        \   'start': self['state']['start_position'],
        \   'end': self['state']['start_position']
        \ }, self['state']['lines'])

  " update state.
  let self['state']['running'] = v:true
  let self['state']['buffer'] = getline('^', '$')
endfunction

"
" Check jump marker enabled.
"
function! s:Session.jumpable()
  if !vsnip#utils#get(self, ['state', 'running'], v:false)
    return v:false
  endif

  let [l:idx, l:next] = s:find_next_placeholder(self['state']['current_idx'], self['state']['placeholders'])
  return !empty(l:next)
endfunction

"
" Jump to next pos.
"
function! s:Session.jump()
  " get placeholder.
  if !vsnip#utils#get(self, ['state', 'running'], v:false)
    return v:false
  endif

  let [l:idx, l:next] = s:find_next_placeholder(self['state']['current_idx'], self['state']['placeholders'])
  if empty(l:next)
    return
  endif

  let self['state']['current_idx'] = l:idx

  " move & select.
  call vsnip#utils#edit#select_or_insert(l:next['range'])
endfunction

"
"  Handle text changed.
"  TODO: implement
"
function! s:Session.on_text_changed()
  if vsnip#utils#get(self, ['state', 'running'], v:false)
    let l:old = self['state']['buffer']
    let l:new = getline('^', '$')
    let l:diff = vsnip#utils#diff#compute(l:old, l:new)
    let self['state'] = vsnip#state#sync(self['state'], l:diff)
    let self['state']['buffer'] = l:new
  endif
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

