let s:Session = vsnip#session#import()

let s:session = v:null

"
" vsnip#anonymous
"
function! vsnip#anonymous(text) abort
  let s:session = s:Session.new(
        \   bufnr('%'),
        \   lamp#protocol#position#get(),
        \   a:text
        \ )
  call s:session.insert()
endfunction

"
" vsnip#get_session
"
function! vsnip#get_session() abort
  return s:session
endfunction

"
" vsnip#deactivate
"
function! vsnip#deactivate() abort
  call lamp#view#notice#add({ 'lines': ['`Snippet`: session deactivated.'] })
  let s:session = {}
endfunction

