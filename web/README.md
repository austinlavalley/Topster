# topster.app

The app's domain. Static, no build step, hosted on Cloudflare Pages from this
folder. Everything the domain does is in this folder, so changing it is a
commit.

| Path | What |
|---|---|
| `/` | 301 to the App Store listing. This is the URL the export watermark prints. |
| `/privacy` | The privacy policy, and the support page. Registered in App Store Connect as both. |
| `/support` | 301 to `/privacy`. |
| `_redirects` | The two rules above, in Cloudflare Pages' format. |

## Setting it up (once)

Either Cloudflare flow works; the folder carries what each needs.

**Workers** (what the dashboard offers first). Create an app from this repo.
Project name `topster`, build command empty, deploy command
`npx wrangler deploy`, Path `web`. Uncheck builds for non-production
branches, or every iOS feature branch will deploy a preview of the site.
`wrangler.jsonc` here tells the Worker to serve this folder as static
files, and `.assetsignore` keeps the config and this README out of what is
served.

**Pages.** Connect to Git, pick this repo, production branch `main`, build
command empty, build output directory `web`. It ignores `wrangler.jsonc`.

Then, on the project, add `topster.app` as a custom domain. The zone is
already on Cloudflare, so it writes the DNS record and issues the
certificate itself.

1. Delete the placeholder A record (`192.0.2.1`) and the Redirect Rule that
   were carrying the redirect before. From here the `_redirects` file is the
   only source of truth for the domain.
2. In App Store Connect, App Information, set the privacy policy URL and the
   support URL to `https://topster.app/privacy`.
3. Keep `topster.austinlavalley.com` redirecting to `https://topster.app/privacy`
   until every shipped version of the app links to the new address. 1.7.0
   still opens the old one from Settings.

## Campaign link

Generate one in App Store Connect (Analytics, Sources, Campaigns, Generate
campaign link) with campaign name `watermark`, and put it in `_redirects` as
the root target. App Analytics then reports downloads through the mark as
their own line.
