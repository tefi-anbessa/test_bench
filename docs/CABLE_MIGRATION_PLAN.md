# Cable Architecture Migration Plan

Working plan for the `cables-architecture` branch. Tracks the move of `Cable`
out of the Electrical module to a bare/core model with a polymorphic
`cable_type`, and the addition of `Instrument::CableType` as the second
concrete type that proves the design.

Background and the reasoning behind each decision live in the chat history
for this branch, not repeated here - this file is the checklist, not the
discussion. Key decisions it assumes:

- `CableType` does **not** move or unify. `Electrical::CableType` stays
  exactly as it is. Each discipline that needs cable types gets its own
  concrete class (e.g. the new `Instrument::CableType`), because different
  disciplines genuinely need different attributes, not just different
  values.
- `Cable` goes bare (no module), with `belongs_to :cable_type,
  polymorphic: true` pointing at whichever concrete `CableType` class the
  discipline owns.
- A cable's discipline still comes entirely through its `Tag` (unchanged -
  this is what keeps the generic tagable abstraction intact). The
  discipline then *constrains* which `cable_type` is a valid choice, via
  `Discipline#cable_type_class` and a model validation - it does not
  determine the discipline.
- "Which disciplines can have cables" is a data question (does this
  discipline's module have a `CableType` class), not a hardcoded module
  list anywhere.

Mark items done as `[x]` while the branch progresses. Commit at the end of
each phase (same git-checkpoint habit as a generator trial, see
[GENERATORS](GENERATORS.md)), and run the affected test file(s) one at a
time after each phase, not only at the end.

## Known risk points (confirmed, not hypothetical)

- [x] `test/helpers/test_setup_helpers.rb#setup_disciplines` resolves a
      test's discipline via `resource_class.module_parent_name`. A bare
      `Cable` has no parent module, so every one of Cable's own existing
      tests needs an explicit `setup_disciplines(name: "Electrical")` once
      Cable goes bare, or they'll raise `ArgumentError`. Confirmed, and the
      same pattern turned up in three *more* independent places
      (`tagable_model_tests.rb`, `tagable_controller_tests.rb`'s own
      internal default, and the `:cable` factory itself) - each given its
      own overridable hook rather than one shared fix, since they're
      genuinely separate implementations.
- [x] The polymorphic `cable_type_id`/`cable_type_type` pair needs existing
      data backfilled (`cable_type_type = 'Electrical::CableType'`) as part
      of the migration, not left to a model default. Done in the migration
      itself via `UPDATE`.
- [x] `Discipline#accepts_tagable_type?`'s fallback hook (Phase 0) needs to
      actually exist before Cable goes bare, not just be commented as a
      future extension point. Built in Phase 0, used by `Cable.discipline_available?`.

## Phase 0 - shared groundwork (no behavior change yet)

- [x] `Discipline#accepts_tagable_type?`: add the fallback to a class-level
      hook (`klass.discipline_available?(self)` when the type class
      defines it, else the existing module-match check).
- [x] `Discipline#cable_type_class`: `"#{module_name}::CableType"
      .safe_constantize` - the one place that resolves "this discipline's
      own CableType class."
- [x] Run `discipline_test.rb` + `tag_test.rb` to confirm no behavior
      change for existing (module-matching) tagable types. Both green
      (47/47, 43/43) before adding new coverage; 7 new tests added to
      `discipline_test.rb` for the hook and `cable_type_class` (50/50).

## Phase 1 - Cable becomes bare/core

- [x] Migration: `rename_table :electrical_cables, :cables`; add
      `cable_type_id`/`cable_type_type`; backfill both from the existing
      `electrical_cable_type_id`; drop `electrical_cable_type_id` and its
      index/FK. `db/migrate/20261011120000_move_cable_to_core.rb`, run on
      dev and test.
- [x] `app/models/cable.rb` (moved from `electrical/cable.rb`, module
      removed): `belongs_to :cable_type, polymorphic: true`;
      `Cable.discipline_available?(discipline)`; the
      discipline/cable_type-consistency validation. Needed a
      `creation_discipline` transient attribute - see note below, this
      wasn't as simple as planned.
- [x] `app/controllers/cable_extension.rb` (moved, module removed):
      `tagable_params` permits `:cable_type_id, :cable_type_type` and
      merges in `creation_discipline: @discipline`; form setup scopes
      `@cable_types` via `@discipline.cable_type_class`.
- [x] Views: move `app/views/electrical/cables/*` → `app/views/cables/*`,
      updating `cable_type` field references. Also dropped the
      `cable_type` sort_link/search field - a polymorphic association
      can't be ransack-sorted/searched through to a fixed class, same as
      `from`/`to` in this same view never could; the header column is now
      a plain label like those two, not a new gap.
- [x] `config/constants/tagable.yml`: `Electrical::Cable` → `Cable`, moved
      out from under the `# Electrical` comment.
- [x] Other model/controller references: `electrical/circuit.rb:23`,
      `electrical/demand.rb:23-24` (`class_name: 'Electrical::Cable'` →
      `'Cable'`), `electrical/circuits_controller.rb` (4 call sites).
- [x] Locales: moved the `electrical/cable:` model/attribute/help blocks
      and the `cables:` views block out of each locale's
      `electrical.models.yml`/`electrical.views.yml` into the core
      `models.yml`/`views.yml`, re-keyed as bare `cable:`/`cables:`, for
      all four locales (en/km/th/cn). Added the new
      `cable_type.discipline_mismatch` error key to all four.

### Found during Phase 1: the create-time validation timing problem

`Cable#discipline` (via `has_one :discipline, through: :tag`, from the
Tagable concern) cannot resolve during a brand new Cable's own creation.
Tag holds the `tagable_id`/`tagable_type` FK pointing *at* Cable, and
`belongs_to`-autosave saves the new Cable first (to get its id) before Tag
writes that FK - so at the moment Cable is being validated/inserted,
there is no Tag row pointing back at it yet, in memory or in the
database. This is structural, not a bug to fix - it's inherent to the FK
direction, and it's exactly why the dropdown-filtering fix two sessions
ago for `tagable_type` lived on `Tag` (which already has `discipline`
directly) rather than needing this workaround.

Fix used: `Cable#creation_discipline` is a transient (`attr_accessor`, not
a DB column) that `CableExtension#tagable_params` sets from the
controller's already-known `@discipline` before the record is ever built.
The validation reads `creation_discipline || discipline` - the transient
value on create, the normal through-association on update (where it
already resolves correctly, since the Tag row exists by then). No change
to the generic `TagablesController` was needed - `tagable_params` is
already a per-model hook.

## Phase 1 (continued)

### Found during Phase 1: `electrical_cable_type` factory's own default discipline was never real

`test/factories/electrical/cable_types.rb` defaulted `discipline { association
:discipline }` - the *bare* `:discipline` factory, which generates a
random, non-registry code (`D01`, `D02`, ...) with no module. Harmless
before (nothing checked CableType's own discipline against anything), but
once Cable's discipline/cable_type consistency check existed, every
cable factory call started failing, because `Cable.discipline_available?`
correctly requires a real, module-backed discipline, and the default
cable_type never had one. Fixed by defaulting it to a real Electrical
discipline (`create(:project).disciplines.find_by(code: "E")`) instead.
Not a cable bug - a latent factory-default gap the new validation
correctly caught.

Also found, unrelated to Cable, not fixed (out of scope, flagged in chat
separately): `test/factories_test.rb`'s `test_project_with_tags_is_valid`
calls `create(:discipline, label: 'M')` - `label` has never been a real
column or factory attribute on `Discipline` (`#label` is a derived
method, `code`), so this errors with `NoMethodError: undefined method
'label='`. Pre-existing, not touched here.

A second factory bug, self-inflicted, caught by the controller tests:
the `:cable` factory derived its discipline from whichever cable_type it
auto-built, even when an explicit `tag:` was also given - so
`create(:cable, tag: @tag)` (exactly what `setup_tagable_resources`'s
shared helper does for every tagable test) silently built a cable whose
`cable_type` belonged to a *different*, unrelated discipline than its
own tag. Create didn't catch it (both sides agreed with each other, just
not with the real tag), but a later update - setting
`creation_discipline` from the real controller discipline - correctly
rejected the mismatch, surfacing as a silent "update didn't actually
change anything" test failure. Fixed by resolving the discipline from a
*given* tag first, before deciding what discipline to build an
auto-generated cable_type under.

Found via the system test, pre-existing, not fixed (separate, unplanned
scope): `CableExtension#setup_additional_form_data`'s `@id_options`
builder calls `tagable_scope(model_class)` for each of
`Constants.electrical.connect_options` (`Electrical::Circuit`,
`Electrical::Demand`) to populate the `from`/`to` select options. Neither
Circuit nor Demand is ever a `Tag`'s own `tagable_type` (both are reached
*through* Switchboard/a tagable, not tagged themselves), so
`tagable_scope` - which filters by `Tag.tagable_type` - always returns
empty for both, regardless of how many circuits/demands actually exist.
Confirmed this predates the move (the exact call was already there in
the original file, read earlier in this session, unchanged by me). The
"accredited user assign from and to" system test fails on this - it was
very likely already failing before Cable moved anywhere. Likely fix
(not applied): use `policy_scope(model_class)` for these two, not
`tagable_scope` - but that's a real behavior decision, not mine to make
unilaterally while moving Cable.

Found via the broader regression sweep, a real fallout from an *earlier*
phase (the `Tag#discipline_id` `attr_readonly` added two turns before this
one), not Cable's own architecture: `electrical/circuits_controller_test.rb`
had one test that simulated an "out of scope" demand by doing
`@motor_tag.update(discipline: @other_discipline)` on the shared fixture
tag - exactly the operation `attr_readonly` now forbids. Fixed by having
that one test build its own, separately-scoped tag/motor/demand under
`@other_discipline` from creation, rather than relocating the shared
fixture. Swept the rest of the suite for the same pattern
(`.update(discipline:` and bare `.discipline =` assignment) - the only
other hits were the two legitimate "assert this raises" tests (`tag_test.rb`,
`document_test.rb`) and the tag factory's own pre-save assignment (fine,
`attr_readonly` only blocks post-persistence updates).

Found via the regression sweep, pre-existing from *earlier in this
session* (not this phase, not Cable): `demands_system_test.rb` fails 11/14
with `undefined method 'bg' for nil` in `container_styles(@swatch)`.
Traced to `Electrical::DemandsController#set_swatch` calling
`Electrical::Demand.swatch` directly (no `@discipline.swatch` fallback,
unlike `TagablesController#set_swatch`'s own chain) - and
`Electrical::Base.swatch` was changed earlier this session to look up
`"Discipline E"`, but `test_setup_helpers.rb#setup_projects_and_users`
still creates its test swatch named after `resource_class.module_parent_name`
("Electrical") - the two no longer agree, so the lookup returns nil. This
is a real, live bug, but it belongs to the earlier swatch-naming-convention
change, not to moving Cable - flagging it, not fixing it here.

A second miss from the same cause as the views (filename-based exclusion
in my initial grep hid `cable_type.rb` because the filename itself
contains "cable_type"): `Electrical::CableType` still had
`has_many :electrical_cables, class_name: 'Electrical::Cable', foreign_key:
'electrical_cable_type_id'` - both the class and the FK column it named no
longer exist. Fixed to `has_many :cables, as: :cable_type, dependent:
:destroy` (the correct inverse of a polymorphic `belongs_to`, not a
`foreign_key:` string). Also fixed its `ransackable_associations`, the
`cable_types/_header.html.erb`/`_row.html.erb`/`show.html.erb` views, and
`Electrical::CableTypesController#index`'s `.includes`, all of which
referenced the old association name. Caught by `discipline_system_test.rb`
hitting a live "Translation missing" error navigating to the cable types
index - not by any Cable-specific test, since none of them exercise
CableType's own views.

Also missed on the first pass through the views (not caught until the
controller tests ran): `new.html.erb` and `edit.html.erb` were never
copied over at all - I'd only looked at `_card`/`_form`/`_header`/`_row`/
`index`/`show` and missed that two more files existed in the original
directory. Both recreated, matching the pattern every sibling tagable
(e.g. `electrical/heaters/new.html.erb`) already uses, including passing
through `cable_type_options` as an explicit local (missed on the first
attempt at these two files as well).

- [x] Tests: factory and model/controller/system tests moved out of
      `electrical/`, each gaining the explicit
      `setup_disciplines(name: "Electrical")` noted above. Also touched
      `circuit_test.rb`, `switchboard_test.rb`,
      `demands_controller_test.rb`, `circuits_controller_test.rb`,
      `downstream_load_analysis_test.rb`, `discipline_test.rb`,
      `tag_test.rb`, plus `circuits_system_test.rb`,
      `demands_system_test.rb`, `switchboards_system_test.rb`
      (found via a broader grep that the first pass missed - all three
      build their own cable fixtures directly, not through the moved
      test files).
- [x] Full regression pass on the affected files, one at a time - all
      green except the two pre-existing, unrelated bugs noted above
      (`factories_test.rb`'s `label:` typo, `demands_system_test.rb`'s
      swatch-naming mismatch).

One more found via the sweep, from the *same* earlier-session validation
(not Cable, not this phase): `test/integration/error_handling_test.rb`'s
shared setup built `@discipline = create(:discipline, project: @project)`,
a generic, non-Electrical discipline, then attached a real
`Electrical::Switchboard` tagable to it. That's exactly the mismatch
`Tag#validate_tagable_matches_discipline_module` (built two turns before
Cable's own work started) now correctly rejects, so all 5 tests in that
file errored at setup. Fixed by reusing the project's own real Electrical
discipline (`@project.disciplines.find_by(code: "E")`) instead of a
throwaway one. After that fix, 3/5 pass; the other 2 are unrelated to
anything from this session - a project-delete-authorization test
expecting 403 but getting 409 (looks like a real policy-ordering
question, not something to fix blind), and a `Rails.stub` call needing a
mocking library this test file apparently assumes is available. Both
left alone - flagged in chat, not in this plan, since neither has
anything to do with Cable.

## Phase 1 status: done

Cable is bare/core, polymorphic `cable_type`, validated against its
discipline, dropdown-filtered, dashboard-linked. Every test file this
touched is green. Two pre-existing bugs found and left alone (not
Cable's to fix): the `factories_test.rb` typo, and the
`demands_system_test.rb` swatch-naming mismatch from the earlier
discipline/swatch work this session.

## Phase 2 - prove it: `Instrument::CableType`

- [ ] Decide its actual attributes with the developer first - not
      invented here (shielding? pair/core count? signal type? voltage/
      current rating equivalent?).
- [ ] Build it the normal way: `project_assistant:scaffold
      Instrument::CableType --nesting=discipline` plus the usual
      follow-up checklist (model, policy, controller, views, routes under
      `namespace :instrument`, locales, factory, tests).
- [ ] Confirm `Discipline#cable_type_class` resolves it correctly for the
      Instrument discipline, and that the Cable form offers
      `Instrument::CableType` records (and rejects `Electrical::CableType`
      ones) when the cable's discipline is Instrument - both at the
      dropdown-filter level and via the model validation.
- [ ] New system test: create a Cable under the Instrument discipline with
      an `Instrument::CableType`; confirm an `Electrical::CableType` is
      rejected there.
