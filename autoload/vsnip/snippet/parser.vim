let s:Combinator = vsnip#parser#combinator#import()

"
" vsnip#snippet#parser#parse.
" @see https://github.com/Microsoft/language-server-protocol/blob/master/snippetSyntax.md
"
function! vsnip#snippet#parser#parse(text) abort
  if strlen(a:text) == 0
    return []
  endif

  let l:parsed = s:parser.parse(a:text, 0)
  if !l:parsed[0]
    throw json_encode({ 'text': a:text, 'result': l:parsed })
  endif
  return l:parsed[1]
endfunction

let s:skip = s:Combinator.skip
let s:token = s:Combinator.token
let s:many = s:Combinator.many
let s:or = s:Combinator.or
let s:seq = s:Combinator.seq
let s:lazy = s:Combinator.lazy
let s:option = s:Combinator.option
let s:pattern = s:Combinator.pattern
let s:map = s:Combinator.map

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
let s:int = s:map(s:pattern('\d\+'), { value -> str2nr(value) })
let s:text = { stop, escape -> s:map(
\   s:skip(stop, escape),
\   { value -> {
\     'type': 'text',
\     'raw': value[0],
\     'escaped': value[1]
\   }
\ }) }
let s:regex = s:map(s:text(['/'], []), { value -> {
\   'type': 'regex',
\   'pattern': value.raw
\ } })

"
" any (without text).
"
let s:any = s:or(
\   s:lazy({ -> s:choice }),
\   s:lazy({ -> s:variable }),
\   s:lazy({ -> s:tabstop }),
\   s:lazy({ -> s:placeholder }),
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
\     s:token('/camelcase'),
\     s:token('/pascalcase'),
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
" transform
"
let s:transform = s:map(s:seq(
\   s:slash,
\   s:regex,
\   s:slash,
\   s:many(s:or(s:format, s:text(['/', '$'], []))),
\   s:slash,
\   s:option(s:many(s:or(s:token('i'), s:token('g'))))
\ ), { value -> {
\   'type': 'transform',
\   'regex': value[1],
\   'format': value[3],
\   'option': value[5]
\ } })

"
" variable
"
let s:variable1 = s:map(s:seq(s:dollar, s:varname), { value -> {
\   'type': 'variable',
\   'name': value[1],
\   'children': [],
\ } })
let s:variable2 = s:map(s:seq(s:dollar, s:open, s:varname, s:close), { value -> {
\   'type': 'variable',
\   'name': value[2],
\   'children': [],
\ } })
let s:variable3 = s:map(s:seq(
\   s:dollar,
\   s:open,
\   s:varname,
\   s:colon,
\   s:many(s:or(s:any, s:text(['$', '}'], []))),
\   s:close
\ ), { value -> {
\   'type': 'variable',
\   'name': value[2],
\   'children': value[4]
\ } })
let s:variable4 = s:map(s:seq(s:dollar, s:open, s:varname, s:transform, s:close), { value -> {
\   'type': 'variable',
\   'name': value[2],
\   'transform': value[3],
\   'children': [],
\ } })

let s:variable = s:or(s:variable1, s:variable2, s:variable3, s:variable4)

"
" placeholder.
"
let s:placeholder = s:map(s:seq(
\   s:dollar,
\   s:open,
\   s:int,
\   s:colon,
\   s:many(s:or(s:any, s:text(['$', '}'], []))),
\   s:close
\ ), { value -> {
\   'type': 'placeholder',
\   'id': value[2],
\   'children': value[4]
\ } })

"
" tabstop
"
let s:tabstop1 = s:map(s:seq(s:dollar, s:int), { value -> {
\   'type': 'placeholder',
\   'id': value[1],
\   'children': [],
\ } })
let s:tabstop2 = s:map(s:seq(s:dollar, s:open, s:int, s:option(s:colon), s:close), { value -> {
\   'type': 'placeholder',
\   'id': value[2],
\   'children': [],
\ } })
let s:tabstop3 = s:map(s:seq(s:dollar, s:open, s:int, s:transform, s:close), { value -> {
\   'type': 'placeholder',
\   'id': value[2],
\   'children': [],
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
\   s:many(
\     s:map(s:seq(s:text([',', '|'], []), s:option(s:comma)), { value -> value[0] }),
\   ),
\   s:pipe,
\   s:close
\ ), { value -> {
\   'type': 'placeholder',
\   'id': value[2],
\   'choice': value[4],
\   'children': [copy(value[4][0])],
\ } })

"
" parser.
"
let s:parser = s:many(s:or(s:any, s:text(['$'], ['}'])))
