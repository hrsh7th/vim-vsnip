# spec

https://code.visualstudio.com/docs/editor/userdefinedsnippets

## snippet

- [x] prefix
- [x] body
- [x] prefix abbr
- [x] description
- [x] label
- [ ] scope
- [ ] multiple filetypes

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
- [x] sync
  - [x] sync placeholder(one-line change)
  - [x] sync snippet-range(one-line change)
- [ ] session stack
- [ ] multibytes


# additional features

- [ ] dot repeatable
- [ ] easy snippet creation
- [x] handle visual selected

# performance

- [ ] if available, use `listener_add` instead of `TextChanged*`


# other
- [ ] write tests

