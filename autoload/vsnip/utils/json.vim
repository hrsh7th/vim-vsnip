function! vsnip#utils#json#read(filepath)
  let l:lines = vsnip#utils#to_list(readfile(a:filepath))
  let l:lines = vsnip#utils#to_list(vsnip#utils#json#format(l:lines))
  try
    return json_decode(join(l:lines, "\n"))
  catch /.*/
  endtry
  return {}
endfunction

function! vsnip#utils#json#format(lines)
  if executable('python')
    return s:python(a:lines)
  endif
  return a:lines
endfunction

function! s:python(lines)
  let l:output = system('python -m json.tool', a:lines)
  if type(l:output) == v:t_string
    return split(l:output, "\n")
  endif
  return l:output
endfunction

