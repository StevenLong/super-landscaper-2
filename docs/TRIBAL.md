# Tribal knowledge

Traps and "we tried X, it failed because Y". Current rules live in CLAUDE.md.

- GDScript warnings never show headless (not in the parse check, not in tests). Only the
  dev's editor console sees them, so ask for pasted warnings after a feature lands.
- `Vector2i / int` still raises INTEGER_DIVISION, same as `int / int`. Where dropping the
  remainder is intended, put `@warning_ignore("integer_division")` on the line above.
- A local named like a member, a method, or an Object method (`tr`, `panel`, `name`, `size`)
  raises SHADOWED_VARIABLE. Pick another name.
