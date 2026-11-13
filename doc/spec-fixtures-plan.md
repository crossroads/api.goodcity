# Speeding up the api.goodcity spec suite with fixtures

## Context

`bundle exec rspec` takes **18m48s for 3,491 examples** (local, 2026-10-30). Profiling
FactoryBot during that run (the same accounting as test-prof's FactoryProf) showed
**90% of wall time, 1,016s, spent inside factories.** Assertions are cheap; building
the world for each example is not.

The cost comes from **cascades**, not from the specs themselves:

| Factory | Times run (incl. nested) | Run directly by specs | Time when run directly | Why it's expensive |
|---|---|---|---|---|
| `order` | 1,683 | 1,402 | 276s | builds organisation(+country, district, org type), beneficiary(+identity type), 3× stockit_*, country, district, booking type; callbacks + PaperTrail + push |
| `user` | 9,886 | 3,161 | 190s | each one builds address→district→territory, image, contact, auth token |
| `package` | 3,023 | 1,509 | 137s | storage type, donor condition, package type → child package types + subpackage rows |
| `packages_inventory` | 2,715 | 1,660 | 119s | a fresh package **and** a fresh user **and** a location per ledger row |
| `requested_package` | 657 | 646 | 61s | fresh user + published package |
| `district` | **14,130** | 74 | (127s nested) | find-or-create run 14k times |
| `location` | **12,451** | 1,119 | (73s nested) | same |
| `package_type` / `base_package_type` | 3,478 / 6,673 | — | (162s / 68s nested) | after-create builds the child tree |

Hot files: `spec/models/order_spec.rb` 173s, `requested_packages_controller_spec` 114s,
`packages_controller_spec` 88s, `orders_controller_spec` 70s, `packages_inventory_spec`
54s. Controllers 573s, models 438s, everything else ~115s.

**Approach chosen: hybrid.** FactoryBot stays, because `db:seed`, `db:demo` and
`lib/goodcity/demo_data.rb` depend on it. Fixtures take over three things: the
reference data, a small canonical set of users, organisations and orders, and the
expensive associations inside factories. Bespoke per-test records keep using factories.

## Why fixtures fit this codebase so well

Most reference factories **already find-or-create on a natural key**: `district`,
`territory` and `package_type` via `to_create`, and `location`, `role`, `permission`,
`country`, `donor_condition`, `storage_type`, `booking_type`, `identity_type`,
`organisation_type`, `crossroads_transport`, `process_checklist` and `subpackage_type`
via `initialize_with`. Once those rows are preloaded as fixtures, every one of those
factory calls becomes a single SELECT, with no INSERT, callbacks or PaperTrail rows.
**Step 1 needs no spec edits at all.**

Rails inserts fixtures **once per process, outside the per-example transaction**,
because `use_transactional_fixtures = true` is already on. Every example then rolls
back to that same baseline.

## Ground rules for working piecemeal

1. **One fixture table, or one tight cluster, per commit.** Each commit contains the
   fixture YAML, any factory change it enables, and the spec fixups it forces. It must
   leave the suite green.
2. **Every commit message records its measured effect.** Measure before and after with
   `FPROF=1` (top factories) and the suite wall time. Example:
   `perf(spec): fixture districts+territories (suite 1128s → 1003s, district creates 14130 → 0 inserts)`.
3. **Run the full suite** before each commit with `--order random`, plus a second seed
   for any commit that touches users, roles or orders. Fixtures change what
   `Model.first` and `Model.count` return, so look for order-dependent fallout.
4. **Pick the next target from the profile, not from intuition.** Re-run `FPROF=1`
   after each step; the ranking shifts.
5. **Never fixture a table and keep relying on `before(:suite)` rows in it.** On the
   first example, fixture loading `DELETE`s every row in each table that has a fixture
   file.
6. **Don't change what a spec proves.** If a spec relied on a role having *no*
   permissions, or on being the only row in a table, fix the assertion to be explicit
   (scope it to the records it created). Don't delete it.
7. Small PRs to `master` every 2–3 steps, so speed gains land in CI incrementally.
   CI already splits rspec 3 ways by timing, so it benefits automatically.

## Steps

### Step 0: Branch, tooling, baseline *(done)*
- Branch `chore/spec-fixtures` from `master` (`3e7a835f`).
- `test-prof` added to the `:test` group. Use `FPROF=1 bundle exec rspec` for factory
  counts and time, `FPROF=flamegraph`, and `EVENT_PROF=factory.create`.
- **Baseline, 2026-11-13, `FPROF=1`, seed 50161:** 3,480 examples, **977s wall
  (16m15s)**. Factories account for **14m34s of 16m15s (90%)**: 132,947 factory runs,
  of which 15,751 are called directly by specs.
  Top factories by direct-call time: `user` 164s, `package` 118s, `packages_inventory`
  100s. Most frequently run (mostly nested): `territory` 14,105, `district` 14,092,
  `location` 12,515, `image` 10,109, `address` 9,900, `user` 8,795.
- Fixed a latent failure: `user_safe_delete_job_spec` assumed user id 1 never exists.
  On a freshly migrated DB the suite's system user, created in `before(:suite)` and
  never rolled back, gets id 1.
- Known order-dependent flake: seed 961 failed
  `users_controller_spec.rb:129` ("returns charity users", 2 vs 3) on the
  2026-10-30 master. It predates this work.

### Step 1: Fixture plumbing plus the first table (districts and territories) *(done)*
- In `spec/rails_helper.rb`: `config.fixture_path = Rails.root.join("spec/fixtures")`
  and `config.global_fixtures = :all`. `spec/fixtures/organisation.json` is unaffected,
  because only `*.yml` files are loaded.
- Generate the fixtures **from the existing seed YAMLs via ERB**, so `db/*.yml` stays
  the single source of truth. For example `spec/fixtures/districts.yml`:
  ```erb
  <% YAML.load_file(Rails.root.join("db/districts.yml")).each do |name, a| %>
  <%= name.parameterize.underscore %>:
    name_en: <%= name.to_json %>
    name_zh_tw: <%= a[:name_zh_tw].to_json %>
    latitude: <%= a[:latitude] %>
    longitude: <%= a[:longitude] %>
    territory: <%= a[:territory_name_en].parameterize.underscore %>
  <% end %>
  ```
- Fixtures are loaded explicitly in `before(:suite)`, *before* the system user is
  created. Otherwise the first example's fixture load deletes the districts the system
  user's address points at. Rails caches loaded fixture sets per connection, so
  examples don't reload them (verified: one `DELETE`/`INSERT` per run).
- Local and CI DB users are both `postgres` (superuser), so
  `DISABLE TRIGGER ALL` during fixture load works with the 120 foreign keys.
- *Done.* The `district` factory now takes its territory from the seed's
  `territory_name_en`. Before, it took one from the territory sequence, so a *found*
  district came back with a `territory_id` that didn't match its row. Once every
  district pre-existed, that latent bug failed `districts_controller_spec:16`.
- **Measured (seed 50161):** 3,480 examples, 0 failures; cucumber 21/21.
  | Factory (incl. nested) | Baseline | Step 1 |
  |---|---|---|
  | `district` | 109.1s (7.7ms/call) | 47.9s (3.4ms/call) |
  | `territory` | 33.5s | 22.0s |
  | `address` | 128.2s | 90.4s |

  Wall time was 1,007s against 977s. Run-to-run noise on the local WSL box is about
  ±5%: `location`, untouched by this step, moved 64s → 71s. That noise swamps a ~60s
  gain.

**Lesson that changes the sequencing:** fixtures turn INSERTs into SELECTs, but the
factory machinery (attribute evaluation plus nested factories) still runs 14k times.
Fixtures alone halve the per-call cost. The large wins arrive when associations read
fixture rows directly and the factory never runs (Step 4). From Step 2 onward,
**pair each fixture table with its Step 4 association change in the same commit**, so
each commit shows a measurable gain.

**Measuring:** use the `FPROF=1` "total time" for the factories a commit touches as
the primary metric, since it is far less noisy than wall time locally. Use CI
timings for wall clock.

### Step 2: Remaining callback-free reference tables (one commit per cluster)
In profile order: `locations` (12k creates), `countries`, `donor_conditions`,
`storage_types`, `booking_types` + `process_checklists`, `identity_types`,
`organisation_types`, `crossroads_transports`/`gogovan_transports`,
`cancellation_reasons`, `rejection_reasons`, `roles`, `permissions`.
- **`roles`/`permissions` only, not `roles_permissions`.** The user factory's
  `:with_<role>_role` traits deliberately create roles *without* permissions, and
  preloading the production mapping would silently grant them.
- `Location` includes `PushUpdates`, but fixtures skip callbacks. That's fine for
  static reference rows.
- Expect fallout in a few specs that assume an empty table, such as `Location.first`
  or index endpoints compared against a hard-coded count. Fix them to be explicit.

### Step 3: Package types (the biggest reference cascade, 162s nested)
- Fixtures for `package_types` from `db/package_types.yml`, plus `subpackage_types`
  rows for every `default_packages`/`other_packages` pair. `PackageType`'s
  `after_create :create_default_sub_package_type` doesn't run for fixtures, so those
  rows must be written explicitly.
- `package_type`'s `after(:create)` then finds everything it needs. Optionally make it
  skip the child-building loop when the rows already exist.
- `package_types.location_id`: point at one fixture location.

### Step 4: Point factory associations at fixture rows
Reference data is now always present, so stop running sub-factories for it:
`association :country` → `country { Country.find_by!(name_en: "Hong Kong") }`, and
likewise for district, booking type, identity type and organisation type. This is the
main lever on `order` (276s): it cuts each order's ~12 nested factory runs to a few
SELECTs. Also review the `stockit_*` associations on `order`. The legacy Stockit
columns are nullable, so they may not need records at all except in specs that assert
them. Do this one factory per commit (order, organisation, beneficiary, user's
address).

### Step 5: Canonical users and the system user
- `users.yml`: the system user (replacing `before(:suite)` creation and the
  `after(:suite)` cleanup) plus one user per staff role used heavily by
  controller specs (reviewer, supervisor, order fulfilment, stock admin, charity).
  Include `user_roles` and `auth_tokens` rows, because `refresh_auth_token!` won't run.
- Give fixture mobiles a range the `:mobile` sequence can't reach (e.g. `+85298880xxx`).
  The user factory does `find_or_initialize_by(mobile:)` and would otherwise silently
  reuse, and mutate, a fixture user.
- **Decision point (spike first):** count which specs break if the canonical role
  users carry their full production permission set. If only a few, fixture
  `roles_permissions` for *dedicated* fixture roles. If many, keep permissions
  factory-assigned.
- Convert the bare `create(:user)` calls in controller specs (`generate_and_set_token`)
  to fixture users, file by file, hottest files first.

### Step 6: Canonical domain records, hot file by hot file
Add small fixture sets for `organisations`, `beneficiaries`, `orders` (one per state,
with explicit `code`), and `packages` **with matching `packages_inventories` ledger
rows**. Denormalised quantities must equal the ledger, so check them with the
`lib/goodcity/health_checks` integrity checks. Then convert, in order:
`order_spec`, `requested_packages_controller_spec`, `packages_controller_spec`,
`orders_controller_spec` and `packages_inventory_spec`. Use fixtures where a spec
just needs "an X to exist", and keep factories (fed fixture associations) where the
spec is about X's attributes. Commit one spec file per commit.

### Stop rule
Stop when the top remaining factories are bespoke per-test records, where a fixture
would hide what the test is about. Expect most of the gain from Steps 1–4, which
need almost no spec edits. Steps 5–6 are a judgment call per file.

## Risks and traps
- **Fixture rows persist in the test DB** after rspec, because they're inserted
  outside transactions. Cucumber uses DatabaseCleaner `:transaction` and runs before
  rspec in CI, so CI is fine. Locally, a cucumber run after rspec will see them.
- **Migration specs** (`spec/migrations/`, 2 files) inspect live tables. Re-check them
  after any fixture touching `messages` or `order_transports`.
- `Kernel.srand 852` plus `rand`/`sample` in factories means fixture-backed SELECTs
  shift the random stream. A previously masked order-dependent failure may surface.
  Treat that as a real bug.
- Don't fixture tables whose models carry business callbacks (orders, packages)
  until Step 6, and then only with hand-checked consistent data.

## Verification (every step)
```bash
RAILS_ENV=test rails db:drop db:create db:migrate   # if schema changed; schema:load is broken
FPROF=1 bundle exec rspec                           # green + factory table
bundle exec rspec --seed <other>                    # second seed for user/role/order steps
bundle exec cucumber                                # CI runs it first
```
Record suite time and the top-5 FPROF rows in the commit message.
