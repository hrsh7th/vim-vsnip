let s:template = [
      \ '[key]',
      \ '',
      \ '[prefix]',
      \ '',
      \ '[body]',
      \ '',
      \ '[description]',
      \ ''
      \ ]

function! vsnip#command#edit#complete(...) abort
  let l:input = get(a:000, 0, '.')
  return filter(vsnip#snippet#get_prefixes(&filetype), { i, v -> v =~# '^' . l:input })
endfunction

function! vsnip#command#edit#call(filetype, prefix) abort
  let l:shiftwidth = &shiftwidth
  let l:expandatab = &expandtab
  let l:tabstop = &tabstop
  let l:softtabstop = &softtabstop

  let l:bufnr = bufadd('[vsnip-edit]')
  execute printf('vnew | %dbuffer', l:bufnr)
  let &shiftwidth = l:shiftwidth
  let &expandtab = l:expandatab
  let &tabstop = l:tabstop
  let &softtabstop = l:softtabstop

  let [l:key, l:prefix, l:body, l:description] = s:get_defaults(a:filetype, a:prefix)

  %delete _

  let l:template = deepcopy(s:template)
  for [l:index, l:default] in [
        \ [7, l:description],
        \ [5, l:body],
        \ [3, l:prefix],
        \ [1, l:key]]
    if !empty(l:default)
      for l:line in reverse(vsnip#utils#to_list(l:default))
        call insert(l:template, l:line, l:index)
      endfor
    endif
  endfor

  call vsnip#utils#edit#replace_buffer({
        \   'start': [1, 1],
        \   'end': [1, 2]
        \ }, l:template)

  setlocal buftype=acwrite
  setlocal bufhidden=wipe

  let b:vsnip_command_new_filetype = a:filetype
  augroup vsnip-new
    autocmd!
    autocmd! vsnip-new BufWriteCmd <buffer> call s:on_buf_write_cmd()
  augroup END
endfunction

function! s:on_buf_write_cmd() abort
  let l:state = {
        \   '$type': v:null,
        \   'key': '',
        \   'prefix': '',
        \   'body': '',
        \   'description': ''
        \ }

  for l:line in getline('^', '$')
    if l:line ==# '[key]'
      let l:state['$type'] = 'key'
    elseif l:line ==# '[prefix]'
      let l:state['$type'] = 'prefix'
    elseif l:line ==# '[body]'
      let l:state['$type'] = 'body'
    elseif l:line ==# '[description]'
      let l:state['$type'] = 'description'
    else
      if l:state['$type'] ==# 'key'
        let l:state['key'] .= l:line . "\n"
      elseif l:state['$type'] ==# 'prefix'
        let l:state['prefix'] .= l:line . "\n"
      elseif l:state['$type'] ==# 'body'
        let l:state['body'] .= l:line . "\n"
      elseif l:state['$type'] ==# 'description'
        let l:state['description'] .= l:line . "\n"
      endif
    endif
  endfor

  let l:key = s:format_key(l:state['key'])
  let l:prefix = s:format_prefix(l:state['prefix'])
  let l:body = s:format_body(l:state['body'])
  let l:description = s:format_description(l:state['description'])

  if empty(l:key)
    echomsg 'Please input `key` section.'
    return
  endif

  if empty(l:prefix)
    echomsg 'Please input `prefix` section.'
    return
  endif

  if empty(l:body)
    echomsg 'Please input `body` section.'
    return
  endif

  let l:snippet = {
        \   'prefix': l:prefix,
        \   'body': l:body,
        \   'description': l:description
        \ }

  if !s:preview(extend({ 'key': l:key }, l:snippet))
    echomsg 'Canceled.'
  else
    let l:filepath = vsnip#command#prepare_for_edit(b:vsnip_command_new_filetype)
    let l:json = vsnip#utils#json#read(l:filepath)
    let l:json[l:key] = l:snippet
    call vsnip#utils#json#write(l:filepath, l:json)
    call vsnip#snippet#invalidate(l:filepath)
  endif

  setlocal buftype=nofile
  quit
endfunction

function! s:format_key(text) abort
  return substitute(a:text, '\n', '', 'g')
endfunction

function! s:format_prefix(text) abort
  return filter(split(a:text, "[[:blank:],\n]"), { i, v -> !empty(v) })
endfunction

function! s:format_body(text) abort
  let l:lines = split(a:text, "\n")
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

  " remove last empty line once.
  if l:lines[-1] ==# ''
    call remove(l:lines, -1)
  endif

  return l:lines
endfunction

function! s:format_description(text) abort
  return substitute(a:text, '\n', '', 'g')
endfunction

function! s:get_defaults(filetype, prefix) abort
  let l:indent = vsnip#utils#get_indent()
    for l:snippet in vsnip#snippet#get_snippets(a:filetype)
      if index(l:snippet['prefixes'], a:prefix) >= 0
        return [
              \ l:snippet['key'],
              \ l:snippet['prefix'],
              \ map(copy(l:snippet['body']), { i, v -> substitute(v, '\t', l:indent, 'g') }),
              \ l:snippet['description']
              \ ]
      endif
  endfor
  return ['', '', '', '']
endfunction

function! s:preview(snippet) abort
  for l:line in vsnip#utils#json#format(json_encode(a:snippet))
    echomsg l:line
  endfor
  return vsnip#utils#yesno('Are you ok?')
endfunction

