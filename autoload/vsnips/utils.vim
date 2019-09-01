function! vsnips#utils#get_indent()
  if !&expandtab
    return "\t"
  endif
  if &shiftwidth
    return repeat(' ', &shiftwidth)
  endif
  return repeat(' ', &tabstop)
endfunction

function! vsnips#utils#text_index2buffer_pos(text_start_pos, index_in_text, text)
  let l:lines = split(strpart(a:text, 0, a:index_in_text), "\n", v:true)

  let l:lnum_in_text = len(l:lines) - 1
  let l:col_in_text = strlen(l:lines[-1])

  let l:lnum = a:text_start_pos[0] + l:lnum_in_text
  let l:col = l:col_in_text + (l:lnum_in_text == 0 ? a:text_start_pos[1] : 1)

  return [l:lnum, l:col]
endfunction

function! vsnips#utils#curpos()
  let l:pos = getcurpos()
  return [l:pos[1], l:pos[2]]
endfunction

function! vsnips#utils#get(dict, keys, def)
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

