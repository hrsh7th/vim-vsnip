let s:regex = '\%(\$\(\d\+\)\|\${\(\d\+\)\%(:\([^}]\+\)\)\?}\)'

function! snips#syntax#placeholder#resolve(text)
  let l:text = a:text
  let l:placeholders = []

  let l:pos_start = 0
  let l:order = 0
  while 1
    let [l:symbol, l:start, l:end] = matchstrpos(l:text, s:regex, l:pos_start, 1)
    if empty(l:symbol)
      break
    endif

    let l:placeholder  = s:resolve(l:symbol)
    let l:before = strpart(l:text, 0, l:start)
    let l:after = strpart(l:text, l:end, strlen(l:text))
    let l:text = l:before . l:placeholder['default'] . l:after
    call add(l:placeholders, extend(l:placeholder, {
          \   'order': l:order,
          \   'start': l:start,
          \   'end': strlen(l:placeholder['default'])
          \ }))
    let l:pos_start = strlen(l:before . l:placeholder['default'])
    let l:order = l:order + 1
  endwhile

  return [l:text, s:sort(l:placeholders)]
endfunction

function! s:resolve(symbol)
  let l:matches = matchlist(a:symbol, s:regex)
  if empty(l:matches)
    return {}
  endif

  " normalize default value.
  if l:matches[1] != ''
    return {
          \ 'id': str2nr(l:matches[1]),
          \ 'default': '' }
  else
    return {
          \ 'id': str2nr(l:matches[2]),
          \ 'default': l:matches[3] }
  endif
endfunction

function! s:sort(placeholders)
  function! s:compare(i1, i2)
    if a:i1['id'] != 0 && a:i2['id'] == 0
      return -1
    endif
    if a:i1['id'] == 0 && a:i2['id'] != 0
      return 1
    endif
    if a:i1['id'] == a:i2['id']
      return a:i1['order'] - a:i2['order']
    endif
    return a:i1['id'] - a:i2['id']
  endfunction
  return sort(copy(a:placeholders), function('s:compare'))
endfunction

