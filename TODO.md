# spec

https://code.visualstudio.com/docs/editor/userdefinedsnippets

## snippet

- [x] prefix simple case
- [x] body
- [x] prefix abbr
- [ ] description
- [ ] label
- [ ] scope
- [ ] multiple filetype

## variables

- [x] parse simple case
- [ ] regexp
- [ ] doc comment
- [ ] inline comment

## placeholder

- [x] parse simple case
- [ ] sync same placeholder
  - [x] simple case(one-line change only)
- [ ] choise
- [ ] nested

## behavior

- [x] expand
- [x] jump
  - [x] skip same tabstop
- [x] snippet session deactivation
    - [x] deactivate when above changes
    - [x] deactivate when bellow changes
- [ ] sync placeholder position
  - [x] simple case(one-line change)
- [x] sync snippet range
- [ ] session stack
- [ ] support multibyte

# refactor

- [x] `relocate placeholder` cut into function
- [ ] if available, use `listener_add` instead of `TextChanged*`

