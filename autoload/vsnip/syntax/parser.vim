let s:selected_text = ''

function! s:text(stop, ...) abort
  let l:fn = {}
  let l:fn.raw = get(a:000, 0, v:false)
  let l:fn.name = 'text'
  let l:fn.stop = a:stop
  function! l:fn.parse(text, pos) abort
    let l:pos = a:pos
    let l:len = strchars(a:text)
    let l:value = ''
    while l:pos < l:len
      let l:char = s:getchar(a:text, l:pos)

      " escaped.
      if l:char ==# '\'
        let l:pos += 1
        let l:char = s:getchar(a:text, l:pos)
        if index(self.stop, l:char) == -1
          return [v:false, v:null, l:pos]
        endif
        let l:value .= l:char
        continue
      endif

      " found stop char.
      if index(self.stop, l:char) >= 0
        if a:pos != l:pos
          return [v:true, self.raw ? strcharpart(a:text, a:pos, l:pos - a:pos) : l:value, l:pos]
        else
          return [v:false, v:null, l:pos]
        endif
      endif

      let l:value .= l:char
      let l:pos += 1
    endwhile
    return [v:true, self.raw ? strcharpart(a:text, a:pos, l:pos - a:pos) : l:value, l:len]
  endfunction
  return l:fn
endfunction

function! s:token(token) abort
  let l:fn = {}
  let l:fn.name = 'token'
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

function! s:many(parser) abort
  let l:fn = {}
  let l:fn.name = 'many'
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

function! s:or(...) abort
  let l:fn = {}
  let l:fn.name = 'or'
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

function! s:seq(...) abort
  let l:fn = {}
  let l:fn.name = 'seq'
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

function! s:lazy(callback) abort
  let l:fn = {}
  let l:fn.callback = a:callback
  function! l:fn.parse(text, pos)
    if !has_key(self, 'parser')
      let self.parser = self.callback()
    endif
    return self.parser.parse(a:text, a:pos)
  endfunction
  return l:fn
endfunction

function! s:pattern(pattern) abort
  let l:fn = {}
  let l:fn.name = 'pattern'
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

function! s:map(parser, callback) abort
  let l:fn = {}
  let l:fn.name = 'map'
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

function! s:getchar(text, pos) abort
  let l:nr = strgetchar(a:text, a:pos)
  if l:nr != -1
    return nr2char(l:nr)
  endif
  return ''
endfunction

function! s:resolve_variable(name) abort
  if a:name ==# 'TM_SELECTED_TEXT'
    return s:selected_text

  elseif a:name ==# 'TM_CURRENT_LINE'
    return getline('.')

  elseif a:name ==# 'TM_CURRENT_WORD'
    return ''

  elseif a:name ==# 'TM_LINE_INDEX'
    return line('.') - 1

  elseif a:name ==# 'TM_LINE_NUMBER'
    return line('.')

  elseif a:name ==# 'TM_FILENAME'
    return expand('%:p:t')

  elseif a:name ==# 'TM_FILENAME_BASE'
    return substitute(expand('%:p:t'), '\..*$', '', 'g')

  elseif a:name ==# 'TM_DIRECTORY'
    return expand('%:p:h:t')

  elseif a:name ==# 'TM_FILEPATH'
    return expand('%:p')

  elseif a:name ==# 'CLIPBOARD'
    return getreg(v:register)

  elseif a:name ==# 'WORKSPACE_NAME'
    return ''

  elseif a:name ==# 'CURRENT_YEAR'
    return strftime('%Y')

  elseif a:name ==# 'CURRENT_YEAR_SHORT'
    return strftime('%y')

  elseif a:name ==# 'CURRENT_MONTH'
    return strftime('%m')

  elseif a:name ==# 'CURRENT_MONTH_NAME'
    return strftime('%B')

  elseif a:name ==# 'CURRENT_MONTH_NAME_SHORT'
    return strftime('%b')

  elseif a:name ==# 'CURRENT_DATE'
    return strftime('%d')

  elseif a:name ==# 'CURRENT_DAY_NAME'
    return strftime('%A')

  elseif a:name ==# 'CURRENT_DAY_NAME_SHORT'
    return strftime('%a')

  elseif a:name ==# 'CURRENT_HOUR'
    return strftime('%H')

  elseif a:name ==# 'CURRENT_MINUTE'
    return strftime('%M')

  elseif a:name ==# 'CURRENT_SECOND'
    return strftime('%S')

  elseif a:name ==# 'BLOCK_COMMENT_START'
    return '/**' " TODO

  elseif a:name ==# 'BLOCK_COMMENT_END'
    return '*/' " TODO

  elseif a:name ==# 'LINE_COMMENT'
    return '//' " TODO
  endif

  return ''
endfunction

function! s:flat(arr) abort
  let l:values = []
  for l:item in a:arr
    if type(l:item) == type([])
      let l:values += l:item
    else
      call add(l:values, l:item)
    endif
  endfor
  return l:values
endfunction

"
" primitives.
"
let s:dollar = s:token('$')
let s:open = s:token('{')
let s:close = s:token('}')
let s:colon = s:token(':')
let s:slash = s:token('/')
let s:comma = s:token(',')
let s:pipe = s:token('|')
let s:varname = s:pattern('[_[:alpha:]]\w*')
let s:int = s:map(s:pattern('\d\+'), { value -> str2nr(value[0]) })

"
" any.
"
let s:any = s:or(
      \   s:lazy({ -> s:choice }),
      \   s:lazy({ -> s:variable }),
      \   s:lazy({ -> s:tabstop }),
      \   s:lazy({ -> s:placeholder }),
      \ )

let s:all = s:or(
      \   s:any,
      \   s:text(['$']),
      \ )

"
" format.
"
let s:format1 = s:map(s:seq(s:dollar, s:int), { value -> {
      \   'type': 'format',
      \   'id': value[1]
      \ } })
let s:format2 = s:map(s:seq(s:dollar, s:open, s:int, s:close), { value -> {
      \   'type': 'format',
      \   'id': value[2]
      \ } })
let s:format3 = s:map(
      \ s:seq(
      \   s:dollar,
      \   s:open,
      \   s:int,
      \   s:colon,
      \   s:or(
      \     s:token('/upcase'),
      \     s:token('/downcase'),
      \     s:token('/capitalize'),
      \     s:token('+if'),
      \     s:token('?if:else'),
      \     s:token('-else'),
      \     s:token('else')
      \   ),
      \   s:close
      \ ), { value -> {
      \   'type': 'format',
      \   'id': value[2],
      \   'modifier': value[4]
      \ } })
let s:format = s:or(s:format1, s:format2, s:format3)

"
" regex.
"
let s:regex = s:text(['/'], v:true)

"
" transform
"
let s:transform1 = s:map(s:seq(
      \   s:slash,
      \   s:regex,
      \   s:slash,
      \   s:format,
      \   s:slash,
      \   s:or(s:token('i'))
      \ ), { value -> {
      \   'type': 'transform',
      \   'regex': value[1],
      \   'format': value[3],
      \   'option': value[5]
      \ } })
let s:transform2 = s:map(s:seq(
      \   s:slash,
      \   s:regex,
      \   s:slash,
      \   s:text(['/'], v:true),
      \   s:slash,
      \   s:or(s:token('i'))
      \ ), { value -> {
      \   'type': 'transform',
      \   'regex': value[1],
      \   'replace': value[3],
      \   'option': value[5]
      \ } })
let s:transform = s:or(s:transform1, s:transform2)

"
" tabstop
"
let s:tabstop1 = s:map(s:seq(s:dollar, s:int), { value -> {
      \   'type': 'placeholder',
      \   'id': value[1],
      \   'label': '',
      \ } })
let s:tabstop2 = s:map(s:seq(s:dollar, s:open, s:int, s:close), { value -> {
      \   'type': 'placeholder',
      \   'id': value[2],
      \   'label': '',
      \ } })
let s:tabstop3 = s:map(s:seq(s:dollar, s:open, s:int, s:transform, s:close), { value -> {
      \   'type': 'placeholder',
      \   'id': value[2],
      \   'label': '',
      \   'transform': value[3]
      \ } })
let s:tabstop = s:or(s:tabstop1, s:tabstop2, s:tabstop3)

"
" choice
"
let s:choice = s:map(s:seq(
      \   s:dollar,
      \   s:open,
      \   s:int,
      \   s:pipe,
      \   s:map(
      \     s:seq(
      \       s:many(s:map(s:seq(s:text([',']), s:comma), { value -> value[0] })),
      \       s:text(['|']),
      \     ),
      \     { value -> s:flat(value) }
      \   ),
      \   s:pipe,
      \   s:close
      \ ), { value -> {
      \   'type': 'placeholder',
      \   'id': value[2],
      \   'label': value[4][0],
      \   'items': value[4]
      \ } })

"
" variable
"
let s:variable1 = s:map(s:seq(s:dollar, s:varname), { value -> {
      \   'type': 'variable',
      \   'name': value[1]
      \ } })
let s:variable2 = s:map(s:seq(s:dollar, s:open, s:varname, s:close), { value -> {
      \   'type': 'variable',
      \   'name': value[2]
      \ } })
let s:variable3 = s:map(s:seq(s:dollar, s:open, s:varname, s:colon, s:any, s:close), { value -> {
      \   'type': 'variable',
      \   'name': value[2],
      \   'nest': value[4]
      \ } })
let s:variable4 = s:map(s:seq(s:dollar, s:open, s:varname, s:transform, s:close), { value -> {
      \   'type': 'variable',
      \   'name': value[2],
      \   'transform': value[3]
      \ } })

let s:variable = s:map(s:or(s:variable1, s:variable2, s:variable3, s:variable4), { value ->
      \   extend(value, {
      \     'resolved': s:resolve_variable(value.name)
      \   })
      \ })

"
" placeholder.
"
let s:placeholder = s:map(s:seq(
      \   s:dollar,
      \   s:open,
      \   s:int,
      \   s:colon,
      \   s:many(s:or(s:any, s:text(['$', '}']))),
      \   s:close
      \ ), { value -> {
      \   'type': 'placeholder',
      \   'id': value[2],
      \   'children': value[4]
      \ } })

"
" parser.
"
let s:parser = s:many(s:all)

function! vsnip#syntax#parser#parse(text) abort
  let l:parsed = s:parser.parse(a:text, 0)
  if l:parsed[0]
    let l:result = []
    for l:item in l:parsed[1]
      let l:result += [l:item]
    endfor
    return l:result
  else
    throw json_encode({ 'text': a:text, 'result': l:parsed })
  endif
endfunction

