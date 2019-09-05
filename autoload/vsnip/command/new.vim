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

function! vsnip#command#new#call(filetype, cmd_range) abort
  let l:shiftwidth = &shiftwidth
  let l:expandatab = &expandtab
  let l:tabstop = &tabstop
  let l:softtabstop = &softtabstop
  let l:lines = s:get_visual_lines(a:cmd_range)

  let l:bufnr = bufadd('[vsnip-new]')
  execute printf('vnew | %dbuffer', l:bufnr)
  setlocal buftype=acwrite
  setlocal bufhidden=hide
  let &shiftwidth = l:shiftwidth
  let &expandtab = l:expandatab
  let &tabstop = l:tabstop
  let &softtabstop = l:softtabstop

  %delete _

  call vsnip#utils#edit#replace_buffer({
        \   'start': [1, 1],
        \   'end': [1, 2]
        \ }, s:template)

  if a:cmd_range == 2
    call vsnip#utils#edit#replace_buffer({
          \   'start': [6, 1],
          \   'end': [6, 1]
          \ }, l:lines + [''])
  endif

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
    return
  endif

  let l:filepath = vsnip#command#prepare_for_edit(b:vsnip_command_new_filetype)
  let l:json = vsnip#utils#json#read(l:filepath)
  let l:json[l:key] = l:snippet
  call vsnip#utils#json#write(l:filepath, l:json)
  call vsnip#snippet#invalidate(l:filepath)
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

function! s:get_visual_lines(cmd_range) abort
  if a:cmd_range != 2
    return []
  endif

  let l:lines = getline("'<", "'>")
  if len(l:lines) <= 0
    return []
  endif

  let l:space = matchstr(l:lines[0], '^\s*')
  return map(l:lines, { i, v -> substitute(v, '^' . l:space, '', 'g') })
endfunction

function! s:preview(snippet) abort
  for l:line in vsnip#utils#json#format(json_encode(a:snippet))
    echomsg l:line
  endfor
  return vsnip#utils#yesno('Are you ok?')
endfunction

