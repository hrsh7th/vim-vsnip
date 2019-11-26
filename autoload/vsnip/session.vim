let s:Snippet = vsnip#session#snippet#import()

"
" import.
"
function! vsnip#session#import() abort
  return s:Session
endfunction

let s:Session = {}

"
" new.
"
function! s:Session.new(bufnr, position, text) abort
  return extend(deepcopy(s:Session), {
        \   'bufnr': a:bufnr,
        \   'buffer': getbufline(a:bufnr, '^', '$'),
        \   'snippet': s:Snippet.new(a:position, a:text),
        \   'active': v:true
        \ })
endfunction

"
" insert.
"
function! s:Session.insert() abort
  call lamp#view#edit#apply(self.bufnr, [{
        \   'range': {
        \     'start': self.snippet.position,
        \     'end': self.snippet.position
        \   },
        \   'newText': self.snippet.text()
        \ }])
endfunction

"
" on_text_changed.
"
function! s:Session.on_text_changed()
  if !self.active
    return
  endif

  " compute diff.
  let l:buffer = getbufline(self.bufnr, '^', '$')
  let l:diff = lamp#server#document#diff#compute(self.buffer, l:buffer)
  if l:diff.rangeLength == 0 && l:diff.text ==# ''
    return
  endif
  let self.buffer = l:buffer

  " follow and sync.
  call self.snippet.follow(l:diff)
  let l:range = self.snippet.range()
  call self.snippet.sync()
  call timer_start(0, { ->
        \   lamp#view#edit#apply(self.bufnr, [{
        \     'range': l:range,
        \     'newText': split(self.snippet.text(), "\n", v:true)
          \ }])
        \ }, { 'repeat': 1 })
endfunction

"
" deactivate.
"
function! s:Session.deactivate() abort
  let self.active = v:false
endfunction

