# next
- [x] improve new snippet creation
- [ ] support some edge case of sync placeholders
  - [ ] multi-line changes
  - [ ] same range placeholder
- [ ] parse placeholders more strictly

# spec

https://code.visualstudio.com/docs/editor/userdefinedsnippets


## snippet

- [x] prefix
- [x] body
- [x] prefix abbr
- [x] description
- [x] key
- [ ] scope
- [x] multiple filetypes


## variables

- [x] parse
- [x] pre-defined variables
- [ ] regexp
- [ ] doc comment
- [ ] inline comment


## placeholder

- [x] parse
- [x] choice
- [ ] nested


## behavior

- [x] expand
- [x] jump
  - [x] skip same tabstop
- [x] snippet session deactivation
    - [x] deactivate when above changes
    - [x] deactivate when below changes
- [ ] placeholder deactivation
- [x] sync
  - [x] sync placeholder
  - [x] sync snippet-range
- [ ] session stack
- [ ] multibytes


# additional features

- [ ] dot repeatable
- [x] auto select
- [x] easy snippet creation
- [x] handle visual selected


# performance

- [ ] If available, use `listener_add` instead of `TextChanged*`


# other
- [ ] write tests

