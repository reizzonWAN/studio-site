# studio-site

The front page of **onlinebuildstudio.com**: one page listing every app, published with GitHub Pages.

Plain HTML and CSS, no build step, no Jekyll (`.nojekyll`), no JavaScript on the main page, no web fonts. Light and
dark follow the system.

## Layout

```
index.html                    the hub: header, hero, one <li class="card"> per app, footer
assets/css/site.css           all styles (light and dark tokens at the top)
assets/icons/                 app icons (square; shown at 56 px) and the studio favicon
assets/js/carefirst-redirect.js   sends old Care First addresses to carefirst.onlinebuildstudio.com
treatments/ … admin/          one redirect page per old Care First route (meta refresh + the script)
404.html                      not-found page; also redirects deep Care First links such as /admin/bookings
CNAME                         the custom domain GitHub Pages serves
robots.txt, sitemap.xml
```

## Add or update an app

1. Add its icon to `assets/icons/` (square, at least 112 px).
2. Copy a `<li>` card in `index.html`. Status classes: `status-live`, `status-dev` (In development), `status-soon`
   (Coming soon). Give the card `is-link` and a `card-link` on the name when it has a main link (the whole card
   becomes clickable); secondary links such as store badges or Privacy and Terms go in `.links`.
3. When an app goes live in a store, change its status and add the store links.
4. Add the app's name to the meta description in `<head>`.

## Preview locally

```bash
python3 -m http.server 8090 --directory .
```

Open <http://localhost:8090>. Pages serves files the same way, so what you see is what ships.

## Care First redirects

Care First moved from `onlinebuildstudio.com` to `carefirst.onlinebuildstudio.com`. GitHub Pages can't send real
301s, so each old route has a page that redirects at once (keeping `?query` and `#fragment`) and points its
canonical link at the new address. The list of routes must match `PAGES` in `dental-webpage/backend/app/site.py`;
`carefirst-redirect.js` holds the same list as prefixes for deep links that land on the 404 page.

## Cut-over runbook (one-time)

Do the steps in order. Until step 4, onlinebuildstudio.com keeps serving Care First, so nothing is down.

DNS is edited at WebHost Nepal → My Domains → onlinebuildstudio.com → DNS Management. Note that this zone answers
every unknown subdomain with a parking address (`162.159.36.12`); a record you add replaces that for its name.

1. **Care First on its subdomain, behind the shared edge Caddy.** Follow "The switch from Care First's own
   Caddy" in the `caddy` repo's README (`~/Documents/PersonalProjects/caddy`). Afterwards Care First answers at
   <https://carefirst.onlinebuildstudio.com>, and the bare domain temporarily redirects there (302).
2. *(Covered by step 1.)*
3. **Publish this site.** Create `reizzonWAN/studio-site` on GitHub, push `main`, then Settings → Pages → Deploy
   from branch `main` / root. Under Custom domain, enter `onlinebuildstudio.com`.
   Also verify the domain for the account (GitHub → Settings → Pages → Add a domain), which gives a TXT record to
   add; it stops anyone else's repo from claiming the domain.
4. **Point the domain at GitHub Pages** (do this at a quiet hour):

   | Host | Type | Address |
   | --- | --- | --- |
   | `@` | A | `185.199.108.153` |
   | `@` | A | `185.199.109.153` |
   | `@` | A | `185.199.110.153` |
   | `@` | A | `185.199.111.153` |
   | `www` | CNAME | `reizzonwan.github.io` |
   | `_github-pages-challenge-reizzonwan` | TXT | the value GitHub shows in step 3 |

   Delete the old `@` and `www` A records for `2.29.152.218`. Keep `vps` and `carefirst`.
5. **HTTPS.** Wait for GitHub to issue the certificate (Settings → Pages shows it, usually within an hour), then
   tick **Enforce HTTPS**. Care First sent `Strict-Transport-Security: …; includeSubDomains` from the bare domain,
   so browsers that visited it will only use HTTPS here; expect a short window of certificate errors for them
   between step 4 and the certificate. That is why step 4 is at a quiet hour.
6. **Check.** <https://onlinebuildstudio.com> shows this hub; <https://onlinebuildstudio.com/book?x=1> lands on
   `https://carefirst.onlinebuildstudio.com/book?x=1`; <https://www.onlinebuildstudio.com> redirects to the bare
   domain.
7. **Clean up** (right after step 4 resolves): delete `sites/onlinebuildstudio-move.caddy` in the `caddy` repo,
   commit and deploy the edge.

The legal site moves to `legal.onlinebuildstudio.com` separately (see the `app--legal` README): `legal` → CNAME →
`reizzonwan.github.io`, plus a `CNAME` file and `baseurl: ""` in that repo.
