function! vsnip#utils#json#read(filepath)
  let l:lines = vsnip#utils#to_list(readfile(a:filepath))
  try
    return json_decode(join(l:lines, "\n"))
  catch /.*/
  endtry
  return {}
endfunction

function! vsnip#utils#json#write(filepath, object)
  let l:lines = vsnip#utils#to_list(json_encode(a:object))
  let l:lines = vsnip#utils#json#format(l:lines)
  call writefile(l:lines, a:filepath)
endfunction

function! vsnip#utils#json#format(lines)
  let l:lines = vsnip#utils#to_list(a:lines)
  if executable('python')
    return s:python(l:lines)
  endif
  return l:lines
endfunction

function! s:python(lines)
  let l:output = system('python -m json.tool', a:lines)
  if type(l:output) == v:t_string
    return split(l:output, "\n")
  endif
  return l:output
endfunction

