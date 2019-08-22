function! snips#utils#get_indent()
  if !&expandtab
    return "\t"
  endif
  if &shiftwidth
    return repeat(' ', &shiftwidth)
  endif
  return repeat(' ', &tabstop)
endfunction

function! snips#utils#compute_pos(offset, pos_in_text, text)
  let l:lines = split(strpart(a:text, 0, a:pos_in_text), "\n")

  let l:lnum_in_text= len(l:lines) - 1
  let l:col_in_text = strlen(l:lines[-1])

  let l:lnum = a:offset['lnum'] + l:lnum_in_text
  let l:col = (l:lnum_in_text == 0 ? a:offset['col'] : 1) + l:col_in_text

  return [l:lnum, l:col]
endfunction

