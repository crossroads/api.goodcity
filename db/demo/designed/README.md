# The designed dataset

A demo dataset for the **stock app**, built to look and behave like the real warehouse:

- **Real reference data.** Package types, locations, districts, organisations and the rest
  come from production (a read-only grant of 32 reference tables). Organisations are
  largely the public s.88 register of tax-exempt charities.
- **Synthetic people.** Every user, beneficiary, contact and message is invented
  (`people.yml`).
- **A designed spine.** Stock and order cases chosen so every screen has something real
  to show — each one declares *why* it exists and what the checks assert about it
  (`items.yml`, `sets.yml`, `warehouse.yml`, `orders.yml`).
- **Profile-sampled filler** around the spine, from aggregate distributions of a real
  stock snapshot (`profile.json` — department mix, per-department quantities, condition
  → grade, dimensions, dates, locations). No row of the snapshot is in this repo.

Nothing is written behind the app's back. Every donation goes offer → item → package →
inventorised; every move, pack, loss, trash, designation and dispatch goes through
`Package::Operations`; every order walks the real state machine; each at its own moment
in time. So `packages_inventories`, derived quantities, versions and timestamps agree.

## Run it

```
rake db:demo:designed         # into a database with ONLY reference data loaded
rake db:demo:designed:check   # spine assertions + conformance to profile.json
SEED=7 rake db:demo:designed  # a different, still deterministic, dataset
```

The build refuses a database that already holds stock, orders or users, and runs in one
transaction. On the local test bed it is driven by `goodcity-local/scripts/build-designed.sh`
(fresh database from migrations + the production reference dump, build, snapshot) and
reset with `scripts/restore-designed.sh`.

It is additive: nothing existing in this repository is changed, and `rake db:demo` is
untouched.

## What is in it (seed 20260924)

About 1,000 packages — ~800 live and ~220 that were dispatched in full — 25 sets, 4
boxes/pallets, 250 orders over 18 months (22 open now), ~18,000 version rows. The fixed
test logins `+85251111111` (all admin roles) and `+85252222222` (Stock fulfilment) are
kept exactly as the local test bed creates them.

## Choices worth knowing

- **Descriptions are clean on purpose.** Production descriptions are terse and
  inconsistent; Crossroads expects to run a cleanup pass, so this data shows the
  post-cleanup state (sentence case, specific, consistent terms, no emoji, no
  `FOR <TAG>` earmarks inside descriptions).
- **Filler values come from the app's own valuation** (`ValuationCalculator`), not from
  sampling.
- **Inventory numbers** rise with the inventoried date across the real range; stock from
  before 2020 carries a legacy letter-prefixed number. Every lower number is reserved in
  `inventory_numbers`, so the next item created in the app is numbered after them, as in
  production.
- **Two tables were not in the production grant** — `canned_responses` (the upstream seed
  file is used, minus a stale "closed for team week" auto-reply) and
  `appointment_slot_presets` (invented: Tuesday–Saturday, 10:00 and 14:00, quota 3).
