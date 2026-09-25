---
paths:
  - "resources/js/**"
  - "resources/css/**"
  - "**/*.vue"
---
# Vue 3, PrimeVue, Inertia — house deviations

## PrimeVue 4, not 3

Assume PrimeVue `^4.x` unless the repo's `package.json` says otherwise. Two consequences
older standards get wrong:

- **Components were renamed in v4.** `Dropdown` → `Select`, `Calendar` → `DatePicker`,
  `InputSwitch` → `ToggleSwitch`, `OverlayPanel` → `Popover`, `Sidebar` → `Drawer`. Code
  and docs written against v3 names will not resolve.
- **Use the Aura theme preset**, the common default. `unstyled` mode with `:pt`
  pass-through on everything is easy to mandate and rarely adopted; do not introduce it. Targeted `:pt` on a single component is fine.

## State

**No Pinia unless the repo already has it.** Page state comes
from Inertia props; shared state from Inertia shared data; local state from `ref`/`computed`.
If something genuinely needs a store, raise it rather than adding the dependency quietly.

## Inertia

Check `package.json` for v1 or v2 before using a v2-only API (deferred props, prefetching). Forms go through `useForm()` with its error state;
navigation through `router.visit()`, not a raw `<a>` for an internal link.

## Components

`<script setup lang="ts">` only. Props and emits typed through generics, never the runtime
object form. Shared interfaces live in a `*Types.ts` file — a new field means updating both
the TypeScript interface and the backend serialization, or the two silently diverge.

## Tailwind

Use the repo's declared palette; do not introduce arbitrary colours. A palette lint
(`npm run lint:palette`, a script that rejects colours outside the theme) is cheap and
worth adding.

## Not repeated here

`any`, Options API, import order, `console.log` and `debugger` are ESLint errors — see
`.global-docs/linters/eslint.framework.mjs`. Component size and accessibility are review
judgement, not a rule this file can enforce.
