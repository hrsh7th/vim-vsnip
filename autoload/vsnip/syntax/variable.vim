let s:regex = '\%(\$\(\a\w*\)\|\${\(\a\w*\)\%(:\([^}]\+\)\?\)\?}\)'

let g:vsnip#syntax#variable#selected_text = get(g:, 'vsnip#syntax#variable#selected_text', '')

function! vsnip#syntax#variable#resolve(text) abort
  let l:text = a:text

  let l:pos_start = 0
  while 1
    let [l:symbol, l:start, l:end] = matchstrpos(l:text, s:regex, l:pos_start, 1)
    if empty(l:symbol)
      break
    endif
    let l:variable = s:resolve(l:symbol)
    let l:before = strpart(l:text, 0, l:start)
    let l:after = strpart(l:text, l:end, strlen(l:text))
    let l:text = l:before . l:variable . l:after
    let l:pos_start = strlen(l:before . l:variable)
  endwhile

  return l:text
endfunction

function! s:resolve(symbol) abort
  let l:matches = matchlist(a:symbol, s:regex)
  if empty(l:matches)
    return ''
  endif

  " normalize default value.
  if !empty(l:matches[1])
    let l:variable = { 'name': l:matches[1], 'default': '' }
  else
    let l:variable = { 'name': l:matches[2], 'default': l:matches[3] }
  endif

  " @see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_variables
  if l:variable['name'] ==# 'TM_SELECTED_TEXT'
    return g:vsnip#syntax#variable#selected_text

  elseif l:variable['name'] ==# 'TM_CURRENT_LINE'
    return getline('.')

  elseif l:variable['name'] ==# 'TM_CURRENT_WORD'
    if g:vsnip_verbose
      echoerr '$TM_CURRENT_WORD is not supported.'
    endif
    return ''

  elseif l:variable['name'] ==# 'TM_LINE_INDEX'
    return line('.') - 1

  elseif l:variable['name'] ==# 'TM_LINE_NUMBER'
    return line('.')

  elseif l:variable['name'] ==# 'TM_FILENAME'
    return expand('%:p:t')

  elseif l:variable['name'] ==# 'TM_FILENAME_BASE'
    return substitute(expand('%:p:t'), '\..*$', '', 'g')

  elseif l:variable['name'] ==# 'TM_DIRECTORY'
    return expand('%:p:h:t')

  elseif l:variable['name'] ==# 'TM_FILEPATH'
    return expand('%:p')

  elseif l:variable['name'] ==# 'CLIPBOARD'
    return getreg(v:register)

  elseif l:variable['name'] ==# 'WORKSPACE_NAME'
    return ''

  elseif l:variable['name'] ==# 'CURRENT_YEAR'
    return strftime('%Y')

  elseif l:variable['name'] ==# 'CURRENT_YEAR_SHORT'
    return strftime('%y')

  elseif l:variable['name'] ==# 'CURRENT_MONTH'
    return strftime('%m')

  elseif l:variable['name'] ==# 'CURRENT_MONTH_NAME'
    return strftime('%B')

  elseif l:variable['name'] ==# 'CURRENT_MONTH_NAME_SHORT'
    return strftime('%b')

  elseif l:variable['name'] ==# 'CURRENT_DATE'
    return strftime('%d')

  elseif l:variable['name'] ==# 'CURRENT_DAY_NAME'
    return strftime('%A')

  elseif l:variable['name'] ==# 'CURRENT_DAY_NAME_SHORT'
    return strftime('%a')

  elseif l:variable['name'] ==# 'CURRENT_HOUR'
    return strftime('%H')

  elseif l:variable['name'] ==# 'CURRENT_MINUTE'
    return strftime('%M')

  elseif l:variable['name'] ==# 'CURRENT_SECOND'
    return strftime('%S')

  elseif l:variable['name'] ==# 'BLOCK_COMMENT_START'
    return '/**' " TODO

  elseif l:variable['name'] ==# 'BLOCK_COMMENT_END'
    return '*/' " TODO

  elseif l:variable['name'] ==# 'LINE_COMMENT'
    return '//' " TODO
  endif

  return l:variable['default']
endfunction

