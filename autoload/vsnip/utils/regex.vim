let s:plugin_dir = expand('<sfile>:p:h:h:h:h')

let g:_vsnip_external_context = {}
let g:_vsnip_external_results = v:null

function! vsnip#utils#regex#substitute(expr, ptrn, repl, flag) abort
  if executable('node')
    return s:node(a:expr, a:ptrn, a:repl, a:flag)
  endif
  if has('python3')
    return s:python3(a:expr, a:ptrn, a:repl, a:flag)
  endif
  return a:expr
endfunction

function! s:node(expr, ptrn, repl, flag) abort
  let l:stdin = {}
  let l:stdin['expr'] = a:expr
  let l:stdin['ptrn'] = a:ptrn
  let l:stdin['repl'] = a:repl
  let l:stdin['flag'] = a:flag
  return system(printf('node %s', s:plugin_dir . '/bin/regex.js'), vsnip#utils#to_list(json_encode(l:stdin)))
endfunction

function! s:python3(expr, ptrn, repl, flag) abort
  let g:_vsnip_external_context = {}
  let g:_vsnip_external_context['expr'] = a:expr
  let g:_vsnip_external_context['ptrn'] = a:ptrn
  let g:_vsnip_external_context['repl'] = a:repl
  let g:_vsnip_external_context['flag'] = a:flag

python3 << EOF
import vim
import re

expr = vim.vars['_vsnip_python_context']['expr']
ptrn = vim.vars['_vsnip_python_context']['ptrn']
repl = vim.vars['_vsnip_python_context']['repl']
flag = vim.vars['_vsnip_python_context']['flag']

count = 1
if flag.find('g') > -1:
  py_count = 0

flags = 0
if flag.find('i') > -1:
  flags = flags | re.I
if flag.find('m') > -1:
  flags = flags | re.M
if flag.find('S') > -1:
  flags = flags | re.S

vim.vars['_vsnip_external_results'] = re.sub(re.compile(ptrn, flags), repl, expr)
EOF

  return g:_vsnip_external_results
endfunction

