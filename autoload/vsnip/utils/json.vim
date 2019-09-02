function! vsnip#utils#json#read(filepath)
  let l:lines = vsnip#utils#to_list(readfile(a:filepath))
  let l:lines = vsnip#utils#to_list(vsnip#utils#json#format(l:lines))
  return json_decode(join(l:lines, "\n"))
endfunction

function! vsnip#utils#json#format(lines)
  if executable('python')
    return s:python(a:lines)
  endif
  return a:lines
endfunction

function! s:python(lines)
  return system('python -m json.tool', a:lines)
endfunction

