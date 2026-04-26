# Lovelri Operations Hub

A self-contained set of HTML pages for running the Lovelri customer-facing booking flow and Tony's internal operations dashboard. Designed to be deployed to GitHub Pages, Vercel, Netlify, or embedded in the Lovelri Shopify storefront.

## Files

| File | Audience | Purpose |
| --- | --- | --- |
| `index.html` | Tony / team | Central hub — site audit, competition, marketing, SEO, social, leads, bookings admin |
| `bookings.html` | Customers | 4-step booking flow → emails Tony + sends customer confirmation with calendar links |
| `emailjs-test.html` | Internal | Diagnostic page to verify EmailJS credentials are wired correctly |
| `rings/` | All pages | Ring photos used by the configurator + chat widget |

All pages are static HTML with React + Babel + EmailJS pulled from CDNs at runtime. **No build step. No server.** Open any file in a browser and it works.

## Deploying to GitHub Pages

1. Push this folder to a GitHub repo (e.g. `lovelri-hub`).
2. In the repo, go to **Settings → Pages**.
3. Source: **Deploy from a branch**, branch `main`, folder `/ (root)`.
4. Wait ~30 seconds. Your hub is live at `https://<username>.github.io/lovelri-hub/`.

The hub root (`index.html`) loads automatically. Other pages: `/bookings.html`, `/emailjs-test.html`.

## Deploying to Vercel (recommended for production)

```
npx vercel --prod
```

Vercel auto-detects this as a static site and deploys in ~10 seconds. Custom domain (e.g. `book.lovelri.com`) takes 2 more clicks.

## Embedding the booking flow on lovelri.com (Shopify)

Once `bookings.html` is hosted (Vercel/GitHub Pages/etc.), drop this into a Shopify page:

```html
<iframe src="https://your-deploy-url.com/bookings.html"
        style="width:100%; height:100vh; border:0;"
        loading="lazy">
</iframe>
```

Or embed the JSX-compiled bundle directly via `<script>` once we set up a real build step.

## EmailJS Template Configuration

The booking emails use one EmailJS template with 5 variables. Make sure `template_zi2yxpb` in your EmailJS dashboard has these:

| Variable | Where it's used in EmailJS |
| --- | --- |
| `{{to_name}}` | Free use anywhere in the body |
| `{{to_email}}` | "To Email" recipient field |
| `{{subject}}` | Email Subject field |
| `{{message}}` | Email Body — full booking details + calendar links land here |
| `{{reply_to}}` | "Reply To" field |

Service ID: `service_ood0bss`
Template ID: `template_zi2yxpb`
Public Key: `bRAPk3VW--Jj1UcpG`
Sends to: `garykcli@gmail.com`

## How calendar invites work

When a booking confirms, the customer and Tony each get an email containing one-click calendar deep links:

- **Google Calendar** — pre-filled event in `America/Toronto` time
- **Outlook** (live + Office 365)
- **Yahoo / Apple Calendar**
- **`.ics` download** — universal fallback

The recipient taps the link matching their calendar app and the event opens pre-filled. They click Save and it's on their calendar. No copy-paste, no attachments.

## Local development

Just open `index.html` in your browser. That's it.

If you make changes:

1. Edit the `<script type="text/babel">` block at the bottom of any `.html` file
2. Reload the browser
3. Babel recompiles the JSX in-browser (~1s on first load, instant on subsequent reloads)

For faster iteration once the project grows, switch to a real Vite project — see `docs/migrate-to-vite.md` (coming soon).

## TODO (in progress)

- [ ] Scrape lovelri.com → download all ring photos to `rings/`
- [ ] Fold bookings admin into `index.html` as a tab
- [ ] Add Lead Magnet email-capture page
- [ ] LocalStorage persistence for bookings (currently in-memory)
- [ ] Real-time conflict prevention for double-bookings
- [ ] Migrate to a real backend when scale demands it
