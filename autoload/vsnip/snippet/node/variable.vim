" @see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_variables
" TODO: BLOCK_COMMENT_START, BLOCK_COMMENT_END, LINE_COMMENT
let s:known_variables = {
\   'TM_SELECTED_TEXT': { -> vsnip#selected_text()},
\   'TM_CURRENT_LINE': { -> getline('.')},
\   'TM_CURRENT_WORD': { -> ''},
\   'TM_LINE_INDEX': { -> line('.') - 1},
\   'TM_LINE_NUMBER': { -> line('.')},
\   'TM_FILENAME': { -> expand('%:p:t')},
\   'TM_FILENAME_BASE': { -> substitute(expand('%:p:t'), '^\@<!\..*$', '', '')},
\   'TM_DIRECTORY': { -> expand('%:p:h:t')},
\   'TM_FILEPATH': { -> expand('%:p')},
\   'CLIPBOARD': { -> getreg(v:register)},
\   'WORKSPACE_NAME': { -> ''},
\   'CURRENT_YEAR': { -> strftime('%Y')},
\   'CURRENT_YEAR_SHORT': { -> strftime('%y')},
\   'CURRENT_MONTH': { -> strftime('%m')},
\   'CURRENT_MONTH_NAME': { -> strftime('%B')},
\   'CURRENT_MONTH_NAME_SHORT': { -> strftime('%b')},
\   'CURRENT_DATE': { -> strftime('%d')},
\   'CURRENT_DAY_NAME': { -> strftime('%A')},
\   'CURRENT_DAY_NAME_SHORT': { -> strftime('%a')},
\   'CURRENT_HOUR': { -> strftime('%H')},
\   'CURRENT_MINUTE': { -> strftime('%M')},
\   'CURRENT_SECOND': { -> strftime('%S')},
\   'CURRENT_SECONDS_UNIX': { -> localtime()},
\   'BLOCK_COMMENT_START': { -> '/**'},
\   'BLOCK_COMMENT_END': { -> '*/'},
\   'LINE_COMMENT': { -> '//'},
\ }


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
  \   'name': a:ast.name,
  \   'unknown': !has_key(s:known_variables, a:ast.name),
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })
endfunction

"
" text.
"
function! s:Variable.text() abort
  return self.resolve()
endfunction

"
" resolve.
"
function! s:Variable.resolve() abort
  if has_key(s:known_variables, self.name)
    let l:resolved = s:known_variables[self.name]()
    if !empty(l:resolved)
      return l:resolved
    endif
  endif

  return join(map(copy(self.children), { k, v -> v.text() }), '')
endfunction

"
" to_string
"
function! s:Variable.to_string() abort
  return printf('%s(name=%s, unknown=%s, resolved=%s)',
  \   self.type,
  \   self.unknown ? 'true' : 'false',
  \   self.resolve()
  \ )
endfunction

