# ConsentKit CMP — Google Tag Manager custom template

Deploy the [ConsentKit](https://consentkit.us) consent widget through Google
Tag Manager and wire it into **Google Consent Mode v2**. ConsentKit is a
US-privacy-focused consent management platform; this template is for customers
who manage their tags (GA4, Google Ads, pixels, …) through GTM instead of
pasting the ConsentKit script tag into their site HTML.

## What the template does

When the tag fires on **Consent Initialization** (before any other tags):

1. Sets the **default consent state** from the tag fields via
   `setDefaultConsentState` — the four Consent Mode v2 signals
   (`analytics_storage`, `ad_storage`, `ad_user_data`, `ad_personalization`),
   optionally restricted to a list of regions, plus `wait_for_update` so
   early tags pause briefly for the widget instead of firing blind.
2. Restores a **returning visitor's** saved consent by reading the widget's
   own `consentkit_prefs` cookie and applying it with `updateConsentState`,
   so consent-gated tags behave correctly from the very first event.
3. Loads the ConsentKit widget.

When the visitor makes a choice in the ConsentKit banner (and on every page
load for returning visitors), the widget pushes
`{event: 'consent_update', consent_preferences: {necessary, analytics, marketing}}`
to the dataLayer. The same tag, also triggered on that custom event, applies
it to GTM's consent state with `updateConsentState`:

| ConsentKit preference | Consent Mode signal(s)                                  |
|-----------------------|---------------------------------------------------------|
| `analytics`           | `analytics_storage`                                     |
| `marketing`           | `ad_storage`, `ad_user_data`, `ad_personalization`      |

This mirrors the widget's own gtag mapping (see `updateGTMConsent` in
`widget/v1.js`).

Consent Mode defaults also set `functionality_storage: granted`,
`security_storage: granted` and `personalization_storage: denied`, matching
the widget's built-in gtag defaults.

## Why there is a loader script

The ConsentKit widget reads its configuration from attributes on its own
script tag (`data-site-id`, `data-api`, `data-debug`). GTM's sandboxed
`injectScript` API **cannot set attributes** on the script tags it creates —
its signature is `injectScript(url, onSuccess, onFailure, cacheToken)`. Every
CMP template hits this wall; Cookiebot's official template solves it by
passing configuration in the script URL query string, which the ConsentKit
widget does not read.

So the template writes the configuration to `window.ConsentKit_GTM` and
injects `loader.js` (this directory), a 30-line unsandboxed bridge that
creates the real widget script tag with the required attributes. The loader
is served by the **ConsentKit widget Cloudflare Worker** — the same service
and origin that serves the widget itself:

```
https://widget.consentkit.us/gtm/loader.js
```

`widget/build.js` embeds this directory's `loader.js` into the worker
bundle, so the loader ships with every worker deploy: no third-party CDN,
no dependency on the consentkit repo's visibility, nothing extra to host.
Self-hosters who run their own widget worker can point the template's
**Widget loader URL** field (plus a matching entry under Permissions →
Injects Scripts) at their own `/gtm/loader.js`.

If your site has a Content-Security-Policy, `script-src` must allow
`widget.consentkit.us` (loader and widget come from the same origin).

## Directory contents

| File                        | Purpose                                                        |
|-----------------------------|----------------------------------------------------------------|
| `template.tpl`              | Importable GTM template export (generated — do not edit by hand) |
| `build-tpl.js`              | Regenerates `template.tpl` from the sources: `node build-tpl.js` |
| `loader.js`                 | On-page bridge that creates the widget script tag; source of truth for the worker's `/gtm/loader.js` route (embedded by `widget/build.js`) |
| `template-editor/code.js`   | Source of the template's sandboxed JS (Code tab)               |
| `template-editor/fields.json` | Field definitions (Fields tab)                               |
| `template-editor/info.md`   | Info tab values + `___INFO___` reference                       |
| `template-editor/permissions.md` | Exact Permissions tab entries                             |
| `metadata.yaml`             | Gallery version manifest (for the dedicated gallery repo)      |
| `LICENSE`                   | Apache 2.0 — required by the Community Template Gallery        |

There is no test suite in this directory (it previously contained only an
early `template.js` sketch). `template.tpl` carries three test scenarios in
its `___TESTS___` section that run in the template editor's Tests tab, and
the sandboxed code was verified against a mocked-GTM harness during
development.

## Installing the template in GTM

### Option A — import `template.tpl` (recommended)

1. In GTM, open your web container → **Templates** → **Tag Templates** →
   **New**.
2. In the template editor, open the menu (⋮, top right) → **Import**.
3. Select `template.tpl` from this directory. GTM fills in all tabs
   (Info, Fields, Code, Permissions) from the file.
4. Review the Permissions tab, then **Save**.

### Option B — build it by hand in the template editor

1. **Templates** → **Tag Templates** → **New**.
2. **Info tab**: fill in the values from
   [`template-editor/info.md`](template-editor/info.md).
3. **Fields tab**: recreate each field exactly as specified in
   [`template-editor/fields.json`](template-editor/fields.json) (field type,
   name, display name, default, select items, validation). Field names must
   match — the code reads them via `data.<name>`.
4. **Code tab**: paste the contents of
   [`template-editor/code.js`](template-editor/code.js).
5. **Permissions tab**: add every entry listed in
   [`template-editor/permissions.md`](template-editor/permissions.md). The
   sandbox refuses any API call whose permission is missing, so this tab
   must match the code exactly.
6. **Save**.

## Using the template (customer side)

1. **Create the tag**: Tags → New → Tag Configuration → choose
   **ConsentKit CMP** (under Custom). Fields, as they appear in the tag UI:
   - **ConsentKit Site ID** — text field, required. Copy it from the
     ConsentKit dashboard (Sites → your site → Installation); it looks like
     `my-site-a1b2c3d4`. Maps to the widget's `data-site-id`.
   - **API URL (optional)** — text field, prefilled with
     `https://api.consentkit.us`. Change only for self-hosted API installs.
     Maps to `data-api`.
   - **Enable widget debug logging** — checkbox, off by default. Adds the
     widget's `data-debug` attribute so the widget logs to the console.
   - **Default consent state (Google Consent Mode)** — an expandable group:
     - Four dropdowns (`analytics_storage`, `ad_storage`, `ad_user_data`,
       `ad_personalization`), each `denied` / `granted`, all defaulting to
       `denied`.
     - **Region (optional)** — text field. Comma-separated ISO 3166-2 codes
       (e.g. `US-CA, US-CT`) restricting the defaults to those regions;
       blank means worldwide. Typical US usage: leave blank (opt-out model —
       everything allowed until the visitor opts out) or keep `denied`
       worldwide for an opt-in posture.
     - **Wait for update (ms)** — prefilled `500`, matching the widget's own
       default. Consent-gated tags wait this long for the first consent
       update before firing.
   - **Advanced → Widget loader URL** — prefilled with
     `https://widget.consentkit.us/gtm/loader.js`, served by the ConsentKit
     widget worker. Change only if you self-host the worker (see "Why there
     is a loader script").
2. **Add two triggers to the same tag**:
   - **Consent Initialization - All Pages** (built-in trigger type
     "Consent Initialization"). This makes the defaults land before any
     other tag fires.
   - A **Custom Event** trigger with **Event name** `consent_update`
     (fires on all `consent_update` events). This is the event the
     ConsentKit widget pushes to the dataLayer on every consent choice and
     on every page load for returning visitors.
3. Use **one** ConsentKit tag per container.
4. **Preview** (GTM debug): on first load you should see the tag fire on
   Consent Initialization, the default consent state in the Consent tab, and
   — after accepting/rejecting in the banner — a `consent_update` event with
   the tag firing again and updated consent values.
5. **Publish** the container.

That's the whole setup: no other tags or variables are required. Tags that
use built-in consent checks (GA4, Google Ads, Floodlight) automatically obey
the consent state this template maintains. The widget keeps doing its own
US-state-law geo behavior, script blocking, and consent recording with the
ConsentKit API as usual.

## Community Template Gallery submission

The gallery lets any GTM user add this template in two clicks. Requirements
are from Google's
[submission guide](https://developers.google.com/tag-platform/tag-manager/templates/gallery)
(last checked 2026-07).

**Important repo note:** gallery repositories must have `template.tpl`,
`metadata.yaml`, and `LICENSE` at the repository **root**, contain exactly
**one** `template.tpl`, and serve everything from the **main** branch —
repos that don't match are removed from the gallery. The gallery repo must
also be **public** so Google's crawler can read it, while the
   monorepo this directory lives in is **private**. Submission therefore
requires a **dedicated public repository**. That repo is live at
[`StudioDDx/consentkit-gtm-template`](https://github.com/StudioDDx/consentkit-gtm-template)
(template file:
[template.tpl](https://github.com/StudioDDx/consentkit-gtm-template/blob/main/template.tpl)).
Keep this directory as the source of truth and copy `template.tpl`,
`metadata.yaml`, `LICENSE`, and `README.md` to the gallery repo root on
each release. (Note this is only for gallery listing — the template itself,
the loader, and the widget do not depend on any GitHub repo being public;
the loader is served by the widget worker.)

Steps:

1. **Build and test the template** in the GTM template editor (import
   `template.tpl` per Option A). Run the scenarios in the Tests tab and
   verify the tag in Preview mode on a real site. Google expects templates
   to follow the [style guide](https://developers.google.com/tag-platform/tag-manager/templates/style)
   and to be maintainable long-term.
2. **Agree to the Gallery Terms of Service**: read
   https://developers.google.com/tag-manager/gallery-tos, then in the
   template editor's Info tab check **"Agree to the Community Template
   Gallery Terms of Service"** and re-export. (The `template.tpl` here
   already contains the `___TERMS_OF_SERVICE___` section, so importing it
   satisfies this — verify the box is checked before exporting.)
3. **Export** the template (editor menu → Export) and rename the file
   `template.tpl`. Add a `categories` entry to the `___INFO___` section
   (already present here: `["TAG_MANAGEMENT", "UTILITY"]` — Google's fixed
   category list has no "consent" category; up to three categories, most
   relevant first).
4. **Create the dedicated GitHub repo** (public) with this layout at its
   root, on the `main` branch:
   - `template.tpl` — the export from step 3.
   - `metadata.yaml` — version manifest (template provided here). Fields:
     `homepage`, `documentation`, and `versions`, a list newest-first of
     `{sha, changeNotes}` entries where `sha` is the full SHA of the commit
     in *that repo* containing the template version to serve.
   - `LICENSE` — **Apache 2.0 only**, filename in all caps (provided here).
   - `README.md` — optional but recommended.
   The gallery automatically links each listing to the repo's Issues page
   for bug reports.
5. **Pin the initial version**: commit `template.tpl` to the gallery repo,
   copy that commit's full SHA into a new top entry in `metadata.yaml`'s
   `versions` list (replacing the `PLACEHOLDER`), add `changeNotes:
   Initial release.`, and commit `metadata.yaml`.
6. **Submit**: sign in to GitHub with an account that has access to the
   repo, go to the [Community Template Gallery](https://tagmanager.google.com/gallery),
   choose **Submit Template**, paste the repository URL, and submit.
7. **Updates**: push the new `template.tpl` to the gallery repo, add a new
   `{sha, changeNotes}` entry to the **top** of `versions` in
   `metadata.yaml` pointing at that commit, and commit. The gallery
   typically reflects updates within 2–3 days, and existing users get an
   update notification in GTM.
8. **Moving or removing**: transfer the repo on GitHub to move it (the
   gallery follows the redirect on the next update); delete `LICENSE` or
   `metadata.yaml` to have the template removed from the gallery.

## Developing

- Edit `template-editor/code.js` / `template-editor/fields.json` /
  `build-tpl.js` (Info, Permissions, Tests, Notes live in the build
  script), then run `node build-tpl.js` to regenerate `template.tpl`.
- `loader.js` is plain browser JS served to customer pages — keep it tiny,
  dependency-free, and IE-era-syntax-safe (no `const`/`let`/arrows).
- After changing `loader.js`, rebuild and redeploy the widget worker to
  publish it (`cd widget && node build.js`, then `wrangler deploy` in
  `widget-worker/`); the worker's `/gtm/loader.js` route serves whatever is
  embedded in the bundle. Worker route tests live in
  `widget/tests/worker.test.js` (`npx jest` in `widget/tests/`).
- Do not commit `template.tpl` edits made by hand — regenerate instead so
  the export and its sources never drift.
