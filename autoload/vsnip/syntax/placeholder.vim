let s:regex = '\%(\$\(\d\+\)\|\${\(\d\+\)\%(:\([^}]\+\)\?\||\([^|]\+\)|\)\?}\)'

"
" resolve all placeholders.
"
function! vsnip#syntax#placeholder#resolve(start_position, text)
  let l:text = a:text
  let l:placeholders = []

  let l:pos_start = 0
  let l:order = 0
  while 1
    let [l:symbol, l:start, l:end] = matchstrpos(l:text, s:regex, l:pos_start, 1)
    if empty(l:symbol)
      break
    endif


    let l:placeholder  = s:resolve(l:symbol, l:placeholders)
    let l:before = strpart(l:text, 0, l:start)
    let l:after = strpart(l:text, l:end, strlen(l:text))
    let l:text = l:before . l:placeholder['text'] . l:after
    call add(l:placeholders, {
          \   'order': l:order,
          \   'tabstop': l:placeholder['tabstop'],
          \   'text': l:placeholder['text'],
          \   'choices': l:placeholder['choices'],
          \   'range': {
          \     'start': vsnip#utils#text_index2buffer_pos(a:start_position, l:start, l:text),
          \     'end': vsnip#utils#text_index2buffer_pos(a:start_position, l:start + strlen(l:placeholder['text']), l:text)
          \   }
          \ })
    let l:pos_start = strlen(l:before . l:placeholder['text'])
    let l:order = l:order + 1
  endwhile

  return [l:text, vsnip#syntax#placeholder#by_tabstop(l:placeholders)]
endfunction

"
" sort by order.
"
function! vsnip#syntax#placeholder#by_order(placeholders)
  function! s:compare(i1, i2)
    return a:i1['order'] - a:i2['order']
  endfunction
  return sort(copy(a:placeholders), function('s:compare'))
endfunction

"
" sort by tabstop index.
"
function! vsnip#syntax#placeholder#by_tabstop(placeholders)
  function! s:compare(i1, i2)
    if a:i1['tabstop'] != 0 && a:i2['tabstop'] == 0
      return -1
    endif
    if a:i1['tabstop'] == 0 && a:i2['tabstop'] != 0
      return 1
    endif
    if a:i1['tabstop'] == a:i2['tabstop']
      return a:i1['order'] - a:i2['order']
    endif
    return a:i1['tabstop'] - a:i2['tabstop']
  endfunction
  return sort(copy(a:placeholders), function('s:compare'))
endfunction

"
" resolve placeholder.
"
function! s:resolve(symbol, placeholders)
  let l:matches = matchlist(a:symbol, s:regex)
  if empty(l:matches)
    return {}
  endif

  " tabstop only
  if l:matches[1] != ''
    let l:tabstop = str2nr(l:matches[1])
    return {
          \   'tabstop': l:tabstop,
          \   'choices': [],
          \   'text': ''
          \ }

  " default
  elseif l:matches[3] != ''
    let l:tabstop = str2nr(l:matches[2])
    return {
          \   'tabstop': l:tabstop,
          \   'choices': [],
          \   'text': s:text(l:tabstop, a:placeholders, l:matches[3])
          \ }

  " choice
  elseif l:matches[4] != ''
    let l:tabstop = str2nr(l:matches[2])
    let l:choices = s:choices(l:tabstop, a:placeholders, split(l:matches[4], ","))
    return {
          \   'tabstop': l:tabstop,
          \   'choices': l:choices,
          \   'text': l:choices[0],
          \ }
  endif
endfunction

"
" get text
"
function! s:text(tabstop, placeholders, text)
  for l:p in a:placeholders
    if l:p['tabstop'] == a:tabstop
      return l:p['text']
    endif
  endfor
  return a:text
endfunction

"
" get choices
"
function! s:choices(tabstop, placeholders, choices)
  for l:p in a:placeholders
    if l:p['tabstop'] == a:tabstop
      return l:p['choices']
    endif
  endfor
  return a:choices
endfunction

