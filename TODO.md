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
- [ ] regexp
- [ ] doc comment
- [ ] inline comment

## placeholder

- [x] parse
- [ ] choice
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
- [ ] support multibytes


# additional features

- [ ] one-time snippet
- [ ] dot repeatable
- [ ] easy snippet creation

# performance

- [ ] if available, use `listener_add` instead of `TextChanged*`

