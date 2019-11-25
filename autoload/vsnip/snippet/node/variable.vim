function! vsnip#snippet#node#variable#import() abort
  return s:Variable
endfunction

let s:Variable = {}

"
" new.
"
function! s:Variable.new(ast) abort
  return extend(deepcopy(s:Variable), {
        \   'type': 'variable',
        \   'ast': a:ast,
        \   'name': a:ast.name,
        \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', []))
        \ })
endfunction

"
" text.
"
function! s:Variable.text(snippet) abort
  return self.resolve(a:snippet)
endfunction


"
" resolve.
"
function! s:Variable.resolve(snippet) abort
  " @see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_variables
  if self.name ==# 'TM_SELECTED_TEXT'
    return g:vsnip#selected_text

  elseif self.name ==# 'TM_CURRENT_LINE'
    return getline('.')

  elseif self.name ==# 'TM_CURRENT_WORD'
    return ''

  elseif self.name ==# 'TM_LINE_INDEX'
    return line('.') - 1

  elseif self.name ==# 'TM_LINE_NUMBER'
    return line('.')

  elseif self.name ==# 'TM_FILENAME'
    return expand('%:p:t')

  elseif self.name ==# 'TM_FILENAME_BASE'
    return substitute(expand('%:p:t'), '\..*$', '', 'g')

  elseif self.name ==# 'TM_DIRECTORY'
    return expand('%:p:h:t')

  elseif self.name ==# 'TM_FILEPATH'
    return expand('%:p')

  elseif self.name ==# 'CLIPBOARD'
    return getreg(v:register)

  elseif self.name ==# 'WORKSPACE_NAME'
    return ''

  elseif self.name ==# 'CURRENT_YEAR'
    return strftime('%Y')

  elseif self.name ==# 'CURRENT_YEAR_SHORT'
    return strftime('%y')

  elseif self.name ==# 'CURRENT_MONTH'
    return strftime('%m')

  elseif self.name ==# 'CURRENT_MONTH_NAME'
    return strftime('%B')

  elseif self.name ==# 'CURRENT_MONTH_NAME_SHORT'
    return strftime('%b')

  elseif self.name ==# 'CURRENT_DATE'
    return strftime('%d')

  elseif self.name ==# 'CURRENT_DAY_NAME'
    return strftime('%A')

  elseif self.name ==# 'CURRENT_DAY_NAME_SHORT'
    return strftime('%a')

  elseif self.name ==# 'CURRENT_HOUR'
    return strftime('%H')

  elseif self.name ==# 'CURRENT_MINUTE'
    return strftime('%M')

  elseif self.name ==# 'CURRENT_SECOND'
    return strftime('%S')

  elseif self.name ==# 'BLOCK_COMMENT_START'
    return '/**' " TODO

  elseif self.name ==# 'BLOCK_COMMENT_END'
    return '*/' " TODO

  elseif self.name ==# 'LINE_COMMENT'
    return '//' " TODO
  endif

  return join(map(copy(self.children), { k, v -> v.text(a:snippet) }), '')
endfunction

