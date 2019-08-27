function! snips#utils#edit#insert(pos, lines)
  let l:line = getline(a:pos[0])
  let l:before = l:line[0 : a:pos[1] - 2]
  let l:after = l:line[a:pos[1] - 1: -1]

  let l:lines_len = len(a:lines)
  let l:i = 0
  while l:i < l:lines_len
    if l:i == 0
      if l:lines_len == 1
        call setline(a:pos[0] + l:i, l:before . a:lines[l:i] . l:after)
      else
        call setline(a:pos[0] + l:i, l:before . a:lines[l:i])
      endif
    elseif l:i == l:lines_len - 1
      call append(a:pos[0] + l:i - 1, a:lines[l:i] . l:after)
    else
      call append(a:pos[0] + l:i - 1, a:lines[l:i])
    endif
    let l:i += 1
  endwhile
endfunction

