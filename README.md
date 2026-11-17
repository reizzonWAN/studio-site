# studio-site

The front page of **onlinebuildstudio.com**: one page listing every app. It is served from the VPS
(`2.29.152.218`) by the shared edge Caddy (repo `caddy`, site file `sites/studio.caddy`).

Plain HTML and CSS, no build step, no JavaScript on the main page, no web fonts. Light and dark follow the system.

## Layout

```
index.html            the hub: header, hero, one <li class="card"> per app, footer
assets/css/site.css   all styles (light and dark tokens at the top)
assets/icons/         app icons (square; shown at 56 px) and the studio favicon
404.html              not-found page (Caddy serves it for any missing path)
robots.txt, sitemap.xml
scripts/deploy.sh     publishes the committed site to /opt/sites/studio-site on the server
```

Old Care First addresses on this domain (`/book`, `/treatments/…`, `/admin/…`) are redirected (301) to
`carefirst.onlinebuildstudio.com` by Caddy itself, in the edge repo's `sites/studio.caddy`. Its path list must
match `PAGES` in `dental-webpage/backend/app/site.py`.

## Add or update an app

1. Add its icon to `assets/icons/` (square, at least 112 px).
2. Copy a `<li>` card in `index.html`. Status classes: `status-live`, `status-dev` (In development), `status-soon`
   (Coming soon). Give the card `is-link` and a `card-link` on the name when it has a main link (the whole card
   becomes clickable); secondary links such as store badges or Privacy and Terms go in `.links`.
3. When an app goes live in a store, change its status and add the store links.
4. Add the app's name to the meta description in `<head>`.
5. Commit, push, and deploy (below).

## Preview locally

```bash
python3 -m http.server 8090 --directory .
```

Open <http://localhost:8090>.

## Deploy

**Production ships only `origin/release/prod`.** Work lands on `main`; to release, fast-forward `release/prod` to
`main` and push both (as `reizzonWAN`). Then, in a visible terminal (the `vps-deploy` skill's rules apply):

```bash
scripts/deploy.sh deploy@2.29.152.218
```

It fetches origin, exports exactly `origin/release/prod` with `git archive`, and rsyncs it into
`/opt/sites/studio-site`; local or unpushed changes never ship. Caddy serves straight from disk, so there is nothing
to restart. Emergency hotfix only: `DEPLOY_REF=<commit> scripts/deploy.sh …`, then merge it into `release/prod`.

**First-time setup** (once, on the server): `sudo install -d -m 755 -o deploy -g deploy /opt/sites/studio-site`.
The edge's compose file mounts `/opt/sites` read-only at `/srv`.

## Links

The Legal links point at the legal site on GitHub Pages (`reizzonwan.github.io/app--legal/`). When that site gets
its own subdomain (`legal.onlinebuildstudio.com`), GitHub redirects the old URLs, and these links can be updated.
