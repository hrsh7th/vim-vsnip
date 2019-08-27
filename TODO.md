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
  - [x] simple case(one-line change, insert-char-pre only)
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
  - [x] simple case(one-line change, insert-char-pre only)
- [ ] session stack


# priority

1. sync placeholder position
- [x] support one-line changes
- [ ] support multi-line changes

2. sync same placeholder
- [x] support one-line changes
- [ ] support multi-line changes

3. skip same tabstop
- [x] done

4. refactor
