function! snips#utils#get_indent()
  if !&expandtab
    return "\t"
  endif
  if &shiftwidth
    return repeat(' ', &shiftwidth)
  endif
  return repeat(' ', &tabstop)
endfunction

function! snips#utils#textpos2bufferpos(offsetpos, pos_in_text, text)
  let l:lines = split(strpart(a:text, 0, a:pos_in_text), "\n")

  let l:lnum_in_text = len(l:lines) - 1
  let l:col_in_text = strlen(l:lines[-1])

  let l:lnum = a:offsetpos[0] + l:lnum_in_text
  let l:col = (l:lnum_in_text == 0 ? a:offsetpos[1] : 1) + l:col_in_text

  return [l:lnum, l:col]
endfunction

function! snips#utils#curpos()
  let l:pos = getcurpos()
  return [l:pos[1], l:pos[2]]
endfunction

function! snips#utils#get(dict, keys, def)
  let l:target = a:dict
  for l:key in a:keys
    if index([v:t_dict, v:t_list], type(l:target)) == -1 | return a:def | endif
    let _ = get(l:target, l:key, v:null)
    unlet! l:target
    let l:target = _
    if l:target is v:null | return a:def | endif
  endfor
  return l:target
endfunction

function! snips#utils#resolve_prefixes(prefixes)
  let l:prefixes = []
  for l:prefix in a:prefixes
    call add(l:prefixes, l:prefix)
    if l:prefix =~# '^\a\w\+\%(-\w\+\)\+$'
      call add(l:prefixes, join(map(split(l:prefix, '-'), { i, v -> v[0] }), ''))
    endif
  endfor
  return l:prefixes
endfunction

function! snips#utils#merge_range(range1, range2)
  return [a:range1[0] + a:range2[0], a:range1[1] + a:range2[1]]
endfunction

"
" Compute text diff.
"
" - The `start` is inclusive.
" - The `end` is exclusive.
"
function! snips#utils#diff(old, new)
  let l:old = a:old
  let l:old_len = len(l:old)
  let l:new = a:new
  let l:new_len = len(l:new)

  " first different position in old.
  let l:first_diff_pos = [min([l:old_len, l:new_len]) - 1, strchars(l:old[l:old_len - 1]) - 1]
  let l:i = 0
  while l:i < l:old_len
    if l:new_len <= l:i
      break
    endif
    if l:old[l:i] != l:new[l:i]
      let l:first_diff_pos[0] = l:i
      let l:j = 0
      while l:j < strchars(l:old[l:i])
        if strgetchar(l:old[l:i], l:j) != strgetchar(l:new[l:i], l:j)
          let l:first_diff_pos[1] = l:j
          break
        endif
        let l:j = l:j + 1
      endwhile
      break
    endif
    let l:i = l:i + 1
  endwhile

  " last different position in old.
  let l:last_diff_off = [-1, 0]
  let l:i = -1
  while l:i < -l:old_len
    if l:old[l:i] != l:new[l:i]
      let l:last_diff_off[0] = l:i
      let l:j = -1
      while l:j > -strchars(l:old[l:i])
        let l:old_line_len = strchars(l:old[l:old_len + l:i])
        let l:new_line_len = strchars(l:new[l:new_len + l:i])
        if strgetchar(l:old[l:old_len + l:i], l:old_line_len + l:j) != strgetchar(l:new[l:new_len + l:i], l:new_line_len + l:j)
          let l:last_diff_off[1] = l:j
          break
        endif
        let l:j = l:j - 1
      endwhile
      break
    endif
    let l:i = l:i - 1
  endwhile

  " extract new text to replacement.
  let l:text = ''
  if l:old_len <= l:new_len
    let l:new_last_diff_pos = [
          \ l:new_len + l:last_diff_off[0],
          \ strchars(l:new[l:new_len - 1]) + l:last_diff_off[1]]
    if l:first_diff_pos[0] != l:new_last_diff_pos[0]
      let l:text .= strcharpart(l:new[l:first_diff_pos[0]], l:first_diff_pos[1]) . "\n"
      for l:line in l:new[l:first_diff_pos[0] + 1 : l:new_last_diff_pos[0] - 1]
        let l:text .= l:line . "\n"
      endfor
      let l:text .= strcharpart(l:new[l:new_last_diff_pos[0]], 0, l:new_last_diff_pos[1])
    else
      let l:text .= strcharpart(l:new[l:first_diff_pos[0]], l:first_diff_pos[1], l:new_last_diff_pos[1])
    endif
  endif

  let l:old_last_diff_pos = [
        \ l:old_len + l:last_diff_off[0],
        \ strchars(l:old[l:old_len - 1]) + l:last_diff_off[1]]
  return {
        \   'range': {
        \     'start': l:first_diff_pos,
        \     'end': l:old_last_diff_pos
        \   },
        \   'text': l:text
        \ }
endfunction
" echomsg string([['a', 'b', 'c'], ['a', 'b'], snips#utils#get_diff(['a', 'b', 'c'], ['a', 'b'])])
" echomsg string([['a', 'b'], ['a', 'b', 'c'], snips#utils#get_diff(['a', 'b'], ['a', 'b', 'c'])])
" echomsg string([['a', 'b', 'c'], ['a', 'c', 'b'], snips#utils#get_diff(['a', 'b', 'c'], ['a', 'c', 'b'])])
" echomsg string([['foobar'], ['foobarbaz'], snips#utils#get_diff(['foobar'], ['foobarbaz'])])
" echomsg string([['foobarbaz'], ['foobar'], snips#utils#get_diff(['foobarbaz'], ['foobar'])])
" echomsg string([['foobazbar'], ['foobarbaz'], snips#utils#get_diff(['foobazbar'], ['foobarbaz'])])


