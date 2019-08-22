let g:snips#utils#variable_regexp = '\%(\$\(\a\w*\)\|\${\(\a\w*\)\%(:\([^}]\+\)\)\?}\)'

function! snips#utils#get_indent()
  if !&expandtab
    return "\t"
  endif
  if &shiftwidth
    return repeat(' ', &shiftwidth)
  endif
  return repeat(' ', &tabstop)
endfunction

function! snips#utils#resolve_variable(var)
  let l:matches = matchlist(a:var, g:snips#utils#variable_regexp)
  if empty(l:matches)
    return ''
  endif

  " normalize default value.
  if !empty(l:matches[1])
    let l:var = { 'name': l:matches[1], 'default': '' }
  else
    let l:var = { 'name': l:matches[2], 'default': l:matches[3] }
  endif

  " resolve pre-defined variables.
  if l:var['name'] == 'TM_FILENAME_BASE'
    return substitute(expand('%:p:t'), '\..*$', '', 'g')
  elseif l:var['name'] == 'TM_DIRECTORY'
    return expand('%:p:h:t')
  elseif l:var['name'] == 'TM_FILEPATH'
    return expand('%:p')
  endif

  return l:var['default']
endfunction

