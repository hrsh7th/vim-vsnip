function! vsnip#parser#combinator#import() abort
  return {
  \   'skip': function('s:skip'),
  \   'token': function('s:token'),
  \   'many': function('s:many'),
  \   'or': function('s:or'),
  \   'seq': function('s:seq'),
  \   'pattern': function('s:pattern'),
  \   'lazy': function('s:lazy'),
  \   'option': function('s:option'),
  \   'map': function('s:map')
  \ }
endfunction

"
" string.
"
function! s:skip(stop, escape) abort
  let l:fn = {}
  let l:fn.stop = a:stop
  let l:fn.escape = a:escape
  function! l:fn.parse(text, pos) abort
    let l:pos = a:pos
    let l:value = ''

    let l:len = strchars(a:text)
    while l:pos < l:len
      let l:char = s:getchar(a:text, l:pos)

      " check escaped stop chars.
      if l:char ==# '\'
        let l:pos += 1
        let l:char = s:getchar(a:text, l:pos)
        if index(self.stop + self.escape + ['\'], l:char) == -1
          let l:value .= '\'
          continue " ignore invalid escape char.
        endif
        let l:pos += 1
        let l:value .= l:char
        continue
      endif

      " check stop char.
      if index(self.stop, l:char) >= 0
        if a:pos != l:pos
          return [v:true, [strcharpart(a:text, a:pos, l:pos - a:pos), l:value], l:pos]
        else
          return [v:false, v:null, l:pos]
        endif
      endif

      let l:value .= l:char
      let l:pos += 1
    endwhile

    " everything was string.
    return [v:true, [strcharpart(a:text, a:pos), l:value], l:len]
  endfunction
  return l:fn
endfunction

"
" token.
"
function! s:token(token) abort
  let l:fn = {}
  let l:fn.token = a:token
  function! l:fn.parse(text, pos) abort
    let l:token_len = strchars(self.token)
    let l:value = strcharpart(a:text, a:pos, l:token_len)
    if l:value ==# self.token
      return [v:true, self.token, a:pos + l:token_len]
    endif
    return [v:false, v:null, a:pos]
  endfunction
  return l:fn
endfunction

"
" many.
"
function! s:many(parser) abort
  let l:fn = {}
  let l:fn.parser = a:parser
  function! l:fn.parse(text, pos) abort
    let l:pos = a:pos
    let l:values = []

    let l:len = strchars(a:text)
    while l:pos < l:len
      let l:parsed = self.parser.parse(a:text, l:pos)
      if l:parsed[0]
        call add(l:values, l:parsed[1])
        let l:pos = l:parsed[2]
      else
        break
      endif
    endwhile
    if len(l:values) > 0
      return [v:true, l:values, l:pos]
    else
      return [v:false, v:null, l:pos]
    endif
  endfunction
  return l:fn
endfunction

"
" or.
"
function! s:or(...) abort
  let l:fn = {}
  let l:fn.parsers = a:000
  function! l:fn.parse(text, pos) abort
    for l:parser in self.parsers
      let l:parsed = l:parser.parse(a:text, a:pos)
      if l:parsed[0]
        return l:parsed
      endif
    endfor
    return [v:false, v:null, a:pos]
  endfunction
  return l:fn
endfunction

"
" seq.
"
function! s:seq(...) abort
  let l:fn = {}
  let l:fn.parsers = a:000
  function! l:fn.parse(text, pos) abort
    let l:pos = a:pos
    let l:values = []
    for l:parser in self.parsers
      let l:parsed = l:parser.parse(a:text, l:pos)
      if !l:parsed[0]
        return [v:false, v:null, a:pos]
      endif
      call add(l:values, l:parsed[1])
      let l:pos = l:parsed[2]
    endfor
    return [v:true, l:values, l:pos]
  endfunction
  return l:fn
endfunction

"
" lazy.
"
function! s:lazy(callback) abort
  let l:fn = {}
  let l:fn.callback = a:callback
  function! l:fn.parse(text, pos) abort
    if !has_key(self, 'parser')
      let self.parser = self.callback()
    endif
    return self.parser.parse(a:text, a:pos)
  endfunction
  return l:fn
endfunction

"
" pattern.
"
function! s:pattern(pattern) abort
  let l:fn = {}
  let l:fn.pattern = a:pattern[0] ==# '^' ? a:pattern : '^' . a:pattern
  function! l:fn.parse(text, pos) abort
    let l:text = strcharpart(a:text, a:pos)
    let l:matches = matchstrpos(l:text, self.pattern, 0, 1)
    if l:matches[0] !=# ''
      return [v:true, l:matches[0], a:pos + l:matches[2]]
    endif
    return [v:false, v:null, a:pos]
  endfunction
  return l:fn
endfunction

"
" map.
"
function! s:map(parser, callback) abort
  let l:fn = {}
  let l:fn.callback = a:callback
  let l:fn.parser = a:parser
  function! l:fn.parse(text, pos) abort
    let l:parsed = self.parser.parse(a:text, a:pos)
    if l:parsed[0]
      return [v:true, self.callback(l:parsed[1]), l:parsed[2]]
    endif
    return l:parsed
  endfunction
  return l:fn
endfunction

"
" option.
"
function! s:option(parser) abort
  let l:fn = {}
  let l:fn.parser = a:parser
  function! l:fn.parse(text, pos) abort
    let l:parsed = self.parser.parse(a:text, a:pos)
    if l:parsed[0]
      return l:parsed
    endif
    return [v:true, v:null, a:pos]
  endfunction
  return l:fn
endfunction

"
" getchar.
"
function! s:getchar(text, pos) abort
  let l:nr = strgetchar(a:text, a:pos)
  if l:nr != -1
    return nr2char(l:nr)
  endif
  return ''
endfunction
