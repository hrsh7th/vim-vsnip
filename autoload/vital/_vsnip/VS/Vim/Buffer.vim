" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_vsnip#VS#Vim#Buffer#import() abort', printf("return map({'add': '', 'do': '', 'create': '', 'get_line_count': '', 'pseudo': '', 'ensure': '', 'load': ''}, \"vital#_vsnip#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
let s:Do = { -> {} }

let g:___VS_Vim_Buffer_id = get(g:, '___VS_Vim_Buffer_id', 0)

"
" get_line_count
"
if exists('*nvim_buf_line_count')
  function! s:get_line_count(bufnr) abort
    return nvim_buf_line_count(a:bufnr)
  endfunction
elseif has('patch-8.2.0019')
  function! s:get_line_count(bufnr) abort
    return getbufinfo(a:bufnr)[0].linecount
  endfunction
else
  function! s:get_line_count(bufnr) abort
    if bufnr('%') == bufnr(a:bufnr)
      return line('$')
    endif
    return len(getbufline(a:bufnr, '^', '$'))
  endfunction
endif

"
" create
"
function! s:create(...) abort
  let g:___VS_Vim_Buffer_id += 1
  let l:bufname = printf('VS.Vim.Buffer: %s: %s',
  \   g:___VS_Vim_Buffer_id,
  \   get(a:000, 0, 'VS.Vim.Buffer.Default')
  \ )
  return s:load(l:bufname)
endfunction

"
" ensure
"
function! s:ensure(expr) abort
  if !bufexists(a:expr)
    if type(a:expr) == type(0)
      throw printf('VS.Vim.Buffer: `%s` is not valid expr.', a:expr)
    endif
    call s:add(a:expr)
  endif
  return bufnr(a:expr)
endfunction

"
" add
"
if exists('*bufadd')
  function! s:add(name) abort
    let l:bufnr = bufadd(a:name)
    call setbufvar(l:bufnr, '&buflisted', 1)
  endfunction
else
  function! s:add(name) abort
    badd `=a:name`
  endfunction
endif

"
" load
"
if exists('*bufload')
  function! s:load(expr) abort
    let l:bufnr = s:ensure(a:expr)
    if !bufloaded(l:bufnr)
      call bufload(l:bufnr)
    endif
    return l:bufnr
  endfunction
else
  function! s:load(expr) abort
    let l:curr_bufnr = bufnr('%')
    try
      let l:bufnr = s:ensure(a:expr)
      execute printf('keepalt keepjumps silent %sbuffer', l:bufnr)
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    finally
      execute printf('noautocmd keepalt keepjumps silent %sbuffer', l:curr_bufnr)
    endtry
    return l:bufnr
  endfunction
endif

"
" do
"
function! s:do(bufnr, func) abort
  let l:curr_bufnr = bufnr('%')
  if l:curr_bufnr == a:bufnr
    call a:func()
    return
  endif

  try
    execute printf('noautocmd keepalt keepjumps silent %sbuffer', a:bufnr)
    call a:func()
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  finally
    execute printf('noautocmd keepalt keepjumps silent %sbuffer', l:curr_bufnr)
  endtry
endfunction

"
" pseudo
"
function! s:pseudo(filepath) abort
  if !filereadable(a:filepath)
    throw printf('VS.Vim.Buffer: `%s` is not valid filepath.', a:filepath)
  endif

  " create pseudo buffer
  let l:bufname = printf('VSVimBufferPseudo://%s', a:filepath)
  if bufexists(l:bufname)
    return s:ensure(l:bufname)
  endif

  let l:bufnr = s:ensure(l:bufname)
  let l:group = printf('VS_Vim_Buffer_pseudo:%s', l:bufnr)
  execute printf('augroup %s', l:group)
    execute printf('autocmd BufReadCmd <buffer=%s> call setline(1, readfile(bufname("%")[20 : -1])) | try | filetype detect | catch /.*/ | endtry | augroup %s | autocmd! | augroup END', l:bufnr, l:group)
  augroup END
  return l:bufnr
endfunction
