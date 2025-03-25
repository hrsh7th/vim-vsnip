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
    if l:replacement.type ==# 'format'
      if l:replacement.modifier ==# '/capitalize'
        let l:text .= s:capitalize(a:input_text)
      elseif l:replacement.modifier ==# '/downcase'
        let l:text .= s:downcase(a:input_text)
      elseif l:replacement.modifier ==# '/upcase'
        let l:text .= s:upcase(a:input_text)
      elseif l:replacement.modifier ==# '/camelcase'
        let l:text .= s:camelcase(a:input_text)
      elseif l:replacement.modifier ==# '/pascalcase'
        let l:text .= s:capitalize(s:camelcase(a:input_text))
      endif
    elseif l:replacement.type ==# 'text'
      let l:text .= l:replacement.escaped
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

"
" upcase
"
function! s:upcase(word) abort
  let word = toupper(a:word)
  return word
endfunction

"
" downcase
"
function! s:downcase(word) abort
  let word = tolower(a:word)
  return word
endfunction

"
" capitalize
"
function! s:capitalize(word) abort
  let word = s:upcase(strpart(a:word, 0, 1)) . strpart(a:word, 1)
  return word
endfunction

"
" camelcase
" @see https://github.com/tpope/vim-abolish/blob/3f0c8faa/plugin/abolish.vim#L111-L118
"
function! s:camelcase(word) abort
  let word = substitute(a:word, '-', '_', 'g')
  if word !~# '_' && word =~# '\l'
    return substitute(word,'^.','\l&','')
  else
    return substitute(word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfunction
