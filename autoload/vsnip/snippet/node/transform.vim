function! vsnip#snippet#node#transform#import() abort
  return s:Transform
endfunction

let s:Transform = {}

"
" new.
"
function! s:Transform.new(ast) abort
  let l:transform = empty(a:ast) ? {} : a:ast

  let l:node = extend(deepcopy(s:Transform), {
  \   'type': 'transform',
  \   'regex': get(l:transform, 'regex', v:null),
  \   'replacements': get(l:transform, 'format', []),
  \   'options': get(l:transform, 'option', []),
  \ })

  let l:node.is_noop = l:node.regex is v:null

  return l:node
endfunction

"
" text.
"
function! s:Transform.text(input_text) abort
  if empty(a:input_text) || self.is_noop
    return a:input_text
  endif

  if self.regex.pattern !=# '(.*)'
    " TODO: fully support regex
    return a:input_text
  endif

  let l:text = ''
 
  for l:replacement in self.replacements
    if l:replacement.modifier ==# '/capitalize'
      let l:text = toupper(strpart(a:input_text, 0, 1)) . strpart(a:input_text, 1)
    elseif l:replacement.modifier ==# '/downcase'
      let l:text = tolower(a:input_text)
    elseif l:replacement.modifier ==# '/upcase'
      let l:text = toupper(a:input_text)
    endif
  endfor

  return l:text
endfunction

"
" to_string
"
function! s:Transform.to_string() abort
  if self.is_noop
    return
  end

  return printf('%s(regex=%s, total_replacements=%s, options=%s)',
  \   self.type,
  \   get(self.regex, 'pattern', ''),
  \   len(self.replacements),
  \   join(self.options, ''),
  \ )
endfunction
