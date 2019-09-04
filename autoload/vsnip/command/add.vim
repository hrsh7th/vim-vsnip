function! vsnip#command#add#call(filetype, cmd_range) abort
  if a:cmd_range != 2
    echomsg 'Please specify lines.'
    return
  endif

  let l:body = s:body()
  if empty(l:body)
    echomsg 'Canceld.'
    return
  endif

  let l:filepath = vsnip#command#prepare_for_edit(a:filetype)
  if empty(l:filepath)
    return
  endif

  let l:prefix = input('Prefix: ')
  if empty(l:prefix)
    return
  endif

  let l:label = input('Label: ')
  if empty(l:label)
    return
  endif

  let l:json = vsnip#utils#json#read(l:filepath)
  let l:json[l:label] = {
        \  'prefix': split(l:prefix, ' '),
        \  'body': l:body
        \ }

  if s:preview(l:json[l:label])
    call vsnip#utils#json#write(l:filepath, l:json)
    call vsnip#snippet#invalidate(l:filepath)
  endif
endfunction

function! s:body() abort
  let l:lines = getline("'<", "'>")

  let l:indent = vsnip#utils#get_indent()
  let l:indent_level = vsnip#utils#get_indent_level(get(l:lines, 0, ''), l:indent)
  let l:i = 0
  while l:i < len(l:lines)
    let l:line = l:lines[l:i]
    let l:line = substitute(l:line, '^' . repeat(l:indent, l:indent_level), '', 'g')
    let l:line = substitute(l:line, l:indent, '\t', 'g')
    let l:lines[l:i] = l:line
    let l:i += 1
  endwhile

  return l:lines
endfunction

function! s:preview(snippet) abort
  let l:lines = vsnip#utils#json#format(json_encode(a:snippet))
  echomsg ' '
  for l:line in l:lines
    echomsg l:line
  endfor
  let l:yesno = input('yes/no: ')
  return index(['y', 'ye', 'yes'], l:yesno) >= 0
endfunction

