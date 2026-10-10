# CLAUDE.md

Read this file automatically at the start of every session. Then read
`docs/DEVELOPER_NOTES.md`, `docs/DOCUMENTATION_PREFERENCES.md`,
`docs/TESTING.md`, and `docs/ROLES_AND_PERMISSIONS.md` before making any
assumption about this project - do this once per session, not once ever.

## Protected documentation

`docs/DEVELOPER_NOTES.md`, `docs/DOCUMENTATION_PREFERENCES.md`,
`docs/TESTING.md`, and `docs/ROLES_AND_PERMISSIONS.md` (see
`docs/DOCUMENTATION_PREFERENCES.md` for why) require the developer's
explicit, individual permission before any edit - every time, not once per
topic or session. Having discussed the change isn't permission to make it.

## Git

Never run git commands. Suggest the exact command for the developer to run
themselves, and work from the output they share back.

## Testing

- Minitest and FactoryBot only - never suggest RSpec code or fixtures.
- Run `bin/rails test` one file at a time. Never combine files or
  directories in a single invocation - this machine has a
  parallelization-related hang risk when multiple files run together.
- Refer to `docs/TESTING.md` for detailed guidance.
- When testing error messages, always test for the translated message, not
  the raw key.

## Stack and conventions

- Rails 8, PostgreSQL in all environments.
- Propshaft for asset compilation - Sprockets must not be used.
- All user-facing text is internationalized via i18n. Any new error
  message must be translated.
- Prefer existing error codes/translation keys over adding new ones, to
  avoid bloating the locale files.
- Bootstrap for styling and forms - use the `bootstrap_form` gem for forms
  whenever possible (so labels don't need defining unless non-standard),
  and never suggest Tailwind or another CSS framework.
- Never suggest a CDN for code delivery.
- Don't invent default values unless the developer specifies them -
  defaults are prone to masking coding errors.
- Markdown: ordered lists should use `1.` for every item (let the renderer
  number them - see `.markdownlint.json`), not sequential numbers.

## Working style

- Never change code unless instructed.
- Don't enter plan mode for straightforward, well-scoped requests - match
  planning effort to actual complexity.

## Other AI tools

This project has also used Windsurf/Cascade; `.windsurf/rules/` holds
rules written for it. Claude Code doesn't read that directory
automatically - anything in it still worth enforcing belongs in this file
instead, not just left there assuming it applies.
