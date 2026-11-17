// Care First used to live at onlinebuildstudio.com. Its old addresses now open the same page on its own
// subdomain, keeping the query string and #fragment. The redirect pages also carry a meta refresh, so this
// script only adds the query and fragment; on the 404 page it is the only redirect (for deep admin links).
(function () {
  var TARGET = "https://carefirst.onlinebuildstudio.com";
  // Keep in sync with PAGES in dental-webpage/backend/app/site.py, plus the admin and API.
  var PREFIXES = ["/treatments", "/smile-gallery", "/about", "/your-visit", "/book", "/contact", "/admin", "/api", "/media"];
  var path = location.pathname;
  var match = PREFIXES.some(function (p) { return path === p || path.indexOf(p + "/") === 0; });
  if (!match) return;
  // GitHub Pages adds a trailing slash to folder pages; Care First's own routes have none (its admin keeps it).
  if (path.length > 1 && path.slice(-1) === "/" && path.indexOf("/admin") !== 0) path = path.slice(0, -1);
  location.replace(TARGET + path + location.search + location.hash);
})();
