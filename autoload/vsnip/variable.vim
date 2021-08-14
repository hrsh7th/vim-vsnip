let s:variables = {}

"
" vsnip#variable#register
"
function! vsnip#variable#register(name, func, ...) abort
  let l:option = get(a:000, 0, {})
  let s:variables[a:name] = {
  \   'func': a:func,
  \   'once': get(l:option, 'once', v:false)
  \ }
endfunction

"
" vsnip#variable#get
"
function! vsnip#variable#get(name) abort
  return get(s:variables, a:name, v:null)
endfunction

"
" Register built-in variables.
"
" @see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_variables
"

function! s:TM_SELECTED_TEXT(context) abort
  let l:selected_text = vsnip#selected_text()
  if empty(l:selected_text)
    return v:null
  endif
  return vsnip#indent#trim_base_indent(l:selected_text)
endfunction
call vsnip#variable#register('TM_SELECTED_TEXT', function('s:TM_SELECTED_TEXT'))

function! s:TM_CURRENT_LINE(context) abort
  return getline('.')
endfunction
call vsnip#variable#register('TM_CURRENT_LINE', function('s:TM_CURRENT_LINE'))

function! s:TM_CURRENT_WORD(context) abort
  return v:null
endfunction
call vsnip#variable#register('TM_CURRENT_WORD', function('s:TM_CURRENT_WORD'))

function! s:TM_LINE_INDEX(context) abort
  return line('.') - 1
endfunction
call vsnip#variable#register('TM_LINE_INDEX', function('s:TM_LINE_INDEX'))

function! s:TM_LINE_NUMBER(context) abort
  return line('.')
endfunction
call vsnip#variable#register('TM_LINE_NUMBER', function('s:TM_LINE_NUMBER'))

function! s:TM_FILENAME(context) abort
  return expand('%:p:t')
endfunction
call vsnip#variable#register('TM_FILENAME', function('s:TM_FILENAME'))

function! s:TM_FILENAME_BASE(context) abort
  return substitute(expand('%:p:t'), '^\@<!\..*$', '', '')
endfunction
call vsnip#variable#register('TM_FILENAME_BASE', function('s:TM_FILENAME_BASE'))

function! s:TM_DIRECTORY(context) abort
  return expand('%:p:h:t')
endfunction
call vsnip#variable#register('TM_DIRECTORY', function('s:TM_DIRECTORY'))

function! s:TM_FILEPATH(context) abort
  return expand('%:p')
endfunction
call vsnip#variable#register('TM_FILEPATH', function('s:TM_FILEPATH'))

function! s:CLIPBOARD(context) abort
  let l:clipboard = getreg(v:register)
  if empty(l:clipboard)
    return v:null
  endif
  return vsnip#indent#trim_base_indent(l:clipboard)
endfunction
call vsnip#variable#register('CLIPBOARD', function('s:CLIPBOARD'))

function! s:WORKSPACE_NAME(context) abort
  return v:null
endfunction
call vsnip#variable#register('WORKSPACE_NAME', function('s:WORKSPACE_NAME'))

function! s:CURRENT_YEAR(context) abort
  return strftime('%Y')
endfunction
call vsnip#variable#register('CURRENT_YEAR', function('s:CURRENT_YEAR'))

function! s:CURRENT_YEAR_SHORT(context) abort
  return strftime('%y')
endfunction
call vsnip#variable#register('CURRENT_YEAR_SHORT', function('s:CURRENT_YEAR_SHORT'))

function! s:CURRENT_MONTH(context) abort
  return strftime('%m')
endfunction
call vsnip#variable#register('CURRENT_MONTH', function('s:CURRENT_MONTH'))

function! s:CURRENT_MONTH_NAME(context) abort
  return strftime('%B')
endfunction
call vsnip#variable#register('CURRENT_MONTH_NAME', function('s:CURRENT_MONTH_NAME'))

function! s:CURRENT_MONTH_NAME_SHORT(context) abort
  return strftime('%b')
endfunction
call vsnip#variable#register('CURRENT_MONTH_NAME_SHORT', function('s:CURRENT_MONTH_NAME_SHORT'))

function! s:CURRENT_DATE(context) abort
  return strftime('%d')
endfunction
call vsnip#variable#register('CURRENT_DATE', function('s:CURRENT_DATE'))

function! s:CURRENT_DAY_NAME(context) abort
  return strftime('%A')
endfunction
call vsnip#variable#register('CURRENT_DAY_NAME', function('s:CURRENT_DAY_NAME'))

function! s:CURRENT_DAY_NAME_SHORT(context) abort
  return strftime('%a')
endfunction
call vsnip#variable#register('CURRENT_DAY_NAME_SHORT', function('s:CURRENT_DAY_NAME_SHORT'))

function! s:CURRENT_HOUR(context) abort
  return strftime('%H')
endfunction
call vsnip#variable#register('CURRENT_HOUR', function('s:CURRENT_HOUR'))

function! s:CURRENT_MINUTE(context) abort
  return strftime('%M')
endfunction
call vsnip#variable#register('CURRENT_MINUTE', function('s:CURRENT_MINUTE'))

function! s:CURRENT_SECOND(context) abort
  return strftime('%S')
endfunction
call vsnip#variable#register('CURRENT_SECOND', function('s:CURRENT_SECOND'))

function! s:CURRENT_SECONDS_UNIX(context) abort
  return localtime()
endfunction
call vsnip#variable#register('CURRENT_SECONDS_UNIX', function('s:CURRENT_SECONDS_UNIX'))

function! s:BLOCK_COMMENT_START(context) abort
  return split(&commentstring, '%s')[0]
endfunction
call vsnip#variable#register('BLOCK_COMMENT_START', function('s:BLOCK_COMMENT_START'))

function! s:BLOCK_COMMENT_END(context) abort
  let l:chars = split(&commentstring, '%s')
  let l:comment = len(l:chars) > 1 ? l:chars[1] : l:chars[0]
  return trim(l:comment)
endfunction
call vsnip#variable#register('BLOCK_COMMENT_END', function('s:BLOCK_COMMENT_END'))

function! s:LINE_COMMENT(context) abort
  let l:chars = split(&commentstring, '%s')
  let l:comment = &commentstring =~# '^/\*' ? '//' : substitute(&commentstring, '%s', '', 'g')
  return trim(l:comment)
endfunction
call vsnip#variable#register('LINE_COMMENT', function('s:LINE_COMMENT'))

function! s:VIM(context) abort
  let l:script = join(map(copy(a:context.node.children), 'v:val.text()'), '')
  try
    return eval(l:script)
  catch /.*/
  endtry
  return v:null
endfunction
call vsnip#variable#register('VIM', function('s:VIM'))

function! s:VSNIP_CAMELCASE_FILENAME(context) abort
  let l:basename = substitute(expand('%:p:t'), '^\@<!\..*$', '', '')
  return substitute(l:basename, '\(\%(\<\l\+\)\%(_\)\@=\)\|_\(\l\)', '\u\1\2', 'g')
endfunction
call vsnip#variable#register('VSNIP_CAMELCASE_FILENAME', function('s:VSNIP_CAMELCASE_FILENAME'))

