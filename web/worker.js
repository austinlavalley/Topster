// topster.app Worker.
//
// Static files and the rules in _redirects are served by the assets layer and
// never reach this code. Only the paths under run_worker_first in
// wrangler.jsonc do: the export log endpoint and the private gallery.

// Tiles per row, top to bottom. Mirrors GridType.rowShape in the app.
const ROWS = {
  fortyTwo: [5, 5, 6, 6, 10, 10],
  twenty: [4, 4, 4, 4, 4],
  twentyWide: [5, 5, 5, 5],
  twentyFive: [5, 5, 5, 5, 5],
};
// Grid rows per list section. Mirrors GridType.rowsPerListSection: the 42
// reads as three bands of tile size, the fixed layouts as rows.
const SECTIONS = {
  fortyTwo: [2, 2, 2],
  twenty: [1, 1, 1, 1, 1],
  twentyWide: [1, 1, 1, 1],
  twentyFive: [1, 1, 1, 1, 1],
};
const LABELS = new Set(['none', 'overlay', 'list']);
const BACKGROUNDS = new Set(['light', 'dark']);
// Every placed album is a Last.fm album with Last.fm art, from these hosts.
const COVER_HOST = /^lastfm[a-z0-9-]*\.freetls\.fastly\.net$/;
const MAX_BODY = 32 * 1024;

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/api/exports') {
      if (request.method !== 'POST') {
        return new Response(null, { status: 405, headers: { Allow: 'POST' } });
      }
      return recordExport(request, env);
    }
    if (pathname === '/grids' || pathname === '/grids/') {
      return gallery(request, env);
    }
    return text(404, 'Not found');
  },
};

// The export log. A copy of a grid someone saved to Photos, with no
// identifier. The network address is never read. The date is kept and the
// time is not, so a grid cannot be matched to its analytics event by when it
// arrived.
async function recordExport(request, env) {
  if (Number(request.headers.get('content-length') || 0) > MAX_BODY) {
    return text(413, 'Too large');
  }
  const buffer = await request.arrayBuffer();
  if (buffer.byteLength > MAX_BODY) return text(413, 'Too large');

  let body;
  try {
    body = JSON.parse(new TextDecoder().decode(buffer));
  } catch {
    return text(400, 'Not JSON');
  }

  const clean = validate(body);
  if (typeof clean === 'string') return text(400, clean);

  try {
    await ensureTable(env);
    await env.DB.prepare(
      'INSERT INTO exports (created_on, app_version, layout, labels, background, slots) VALUES (?, ?, ?, ?, ?, ?)',
    )
      .bind(new Date().toISOString().slice(0, 10), clean.app_version, clean.layout,
        clean.labels, clean.background, JSON.stringify(clean.slots))
      .run();
  } catch (error) {
    console.error('export insert failed', error);
    return text(500, 'Not recorded');
  }
  return new Response(null, { status: 204 });
}

// Returns the fields worth keeping, or a reason for rejecting the body. Only
// known fields survive, so nothing the app did not mean to send is stored.
function validate(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return 'Expected an object';
  const { layout, labels, background, app_version: version, slots } = body;
  if (!Object.hasOwn(ROWS, layout)) return 'Unknown layout';
  if (!LABELS.has(labels)) return 'Unknown labels';
  if (!BACKGROUNDS.has(background)) return 'Unknown background';
  if (typeof version !== 'string' || version.length === 0 || version.length > 32) {
    return 'Bad app_version';
  }
  const capacity = ROWS[layout].reduce((sum, width) => sum + width, 0);
  if (!Array.isArray(slots) || slots.length === 0 || slots.length > capacity) return 'Bad slots';

  const seen = new Set();
  const clean = [];
  for (const entry of slots) {
    if (!entry || typeof entry !== 'object') return 'Bad slot';
    const { slot, artist, album, cover } = entry;
    if (!Number.isInteger(slot) || slot < 1 || slot > capacity || seen.has(slot)) {
      return 'Bad slot number';
    }
    if (!isName(artist) || !isName(album)) return 'Bad name';
    seen.add(slot);
    // A cover that fails the host check is dropped rather than the export. If
    // Last.fm ever moves its art, the gallery shows names instead of nothing.
    clean.push({ slot, artist, album, cover: isCover(cover) ? cover : null });
  }
  clean.sort((a, b) => a.slot - b.slot);
  return { layout, labels, background, app_version: version, slots: clean };
}

function isName(value) {
  return typeof value === 'string' && value.length > 0 && value.length <= 300;
}

function isCover(value) {
  if (typeof value !== 'string' || value.length > 500) return false;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && COVER_HOST.test(url.hostname);
  } catch {
    return false;
  }
}

// Created on first use, so a deploy needs no separate migration step.
let tableReady = false;
async function ensureTable(env) {
  if (tableReady) return;
  await env.DB.prepare(`CREATE TABLE IF NOT EXISTS exports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_on TEXT NOT NULL,
    app_version TEXT NOT NULL,
    layout TEXT NOT NULL,
    labels TEXT NOT NULL,
    background TEXT NOT NULL,
    slots TEXT NOT NULL
  )`).run();
  tableReady = true;
}

// The gallery. Behind a password, fails closed if none is set.
async function gallery(request, env) {
  if (!env.VIEWER_PASSWORD) return text(503, 'Gallery not configured');
  if (!authorised(request, env.VIEWER_PASSWORD)) {
    return new Response('Password required', {
      status: 401,
      headers: { 'WWW-Authenticate': 'Basic realm="Topster grids", charset="UTF-8"' },
    });
  }

  const params = new URL(request.url).searchParams;
  const limit = Math.min(Math.max(Number(params.get('limit')) || 60, 1), 200);
  const before = Number(params.get('before')) || 0;
  const columns = 'id, created_on, app_version, layout, labels, background, slots';

  // One row past the page, so the Older link appears only when there is more.
  await ensureTable(env);
  const { results } = before > 0
    ? await env.DB.prepare(`SELECT ${columns} FROM exports WHERE id < ? ORDER BY id DESC LIMIT ?`)
      .bind(before, limit + 1).all()
    : await env.DB.prepare(`SELECT ${columns} FROM exports ORDER BY id DESC LIMIT ?`)
      .bind(limit + 1).all();
  const total = await env.DB.prepare('SELECT COUNT(*) AS n FROM exports').first('n');
  const hasOlder = results.length > limit;

  return new Response(page(results.slice(0, limit), total, limit, hasOlder), {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Robots-Tag': 'noindex',
      'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy':
        "default-src 'none'; img-src https://*.freetls.fastly.net; style-src 'unsafe-inline'",
    },
  });
}

// Basic auth, any username. Constant-time compare; unequal lengths still run
// a comparison so the password length does not leak through timing.
function authorised(request, password) {
  const header = request.headers.get('Authorization') || '';
  if (!header.startsWith('Basic ')) return false;
  let given;
  try {
    const bytes = Uint8Array.from(atob(header.slice(6)), (c) => c.charCodeAt(0));
    const decoded = new TextDecoder().decode(bytes);
    given = decoded.slice(decoded.indexOf(':') + 1);
  } catch {
    return false;
  }
  const a = new TextEncoder().encode(given);
  const b = new TextEncoder().encode(password);
  if (a.byteLength !== b.byteLength) {
    crypto.subtle.timingSafeEqual(b, b);
    return false;
  }
  return crypto.subtle.timingSafeEqual(a, b);
}

function page(rows, total, limit, hasOlder) {
  const cards = rows.map(card).join('\n');
  const oldest = rows.length ? rows[rows.length - 1].id : 0;
  const older = hasOlder
    ? `<a class="more" href="?before=${oldest}&amp;limit=${limit}">Older</a>`
    : '';
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Topster grids</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; padding: 32px 20px 64px; background: #16181a; color: #e8e6e1;
    font: 15px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; }
  header, main, .more { max-width: 1100px; margin-left: auto; margin-right: auto; }
  header h1 { font-size: 22px; letter-spacing: -0.01em; margin: 0 0 4px; }
  header p { margin: 0 0 24px; color: #9a978f; }
  /* minmax(0, 1fr), not auto: an auto column grows to its widest card and
     pushes the page sideways on a phone. */
  main { display: grid; grid-template-columns: minmax(0, 1fr); gap: 28px; }
  /* Each card is as wide as its export: the grid alone, or grid and list. */
  .card { width: fit-content; max-width: 100%; border: 1px solid #34373a; padding: 16px; }
  .card.light { background: #fff; color: #111; }
  .card.dark { background: #000; color: #f2f2f2; }
  .meta { margin: 0 0 12px; opacity: .65;
    font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
  .export { display: flex; flex-wrap: wrap; gap: 16px; align-items: flex-start; }
  .grid { width: 720px; max-width: 100%; display: grid; gap: 4px; }
  .row { display: grid; gap: 4px; }
  .tile { position: relative; aspect-ratio: 1; overflow: hidden; background: #8a8a8e; }
  .tile.blank { opacity: .45; }
  .tile img { position: absolute; inset: 0; display: block; width: 100%; height: 100%; object-fit: cover; }
  /* Drawn only when the image fails, over the browser's broken-image icon. */
  .tile img::after { content: attr(data-name); position: absolute; inset: 0; display: flex; align-items: center;
    justify-content: center; padding: 6px; text-align: center; font-size: 11px; line-height: 1.25;
    color: #fff; background: #8a8a8e; }
  .missing { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
    padding: 6px; text-align: center; font-size: 11px; line-height: 1.25; color: #fff; }
  .caption { position: absolute; left: 0; right: 0; bottom: 0; padding: 3px 5px; background: rgba(0,0,0,.6);
    color: #fff; font-size: 10px; line-height: 1.2; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .list { width: 320px; max-width: 100%; font: 12px/1.5 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
  .list ol { list-style: none; margin: 0 0 14px; padding: 0; }
  .list li span { display: inline-block; min-width: 2.4em; text-align: right; opacity: .6; }
  .none-yet { color: #9a978f; }
  .more { display: block; margin-top: 28px; color: #8fb4ff; }
</style>
</head>
<body>
<header>
  <h1>Exported grids</h1>
  <p>${Number(total) || 0} saved to Photos since the log began. Newest first.</p>
</header>
<main>
${cards || '<p class="none-yet">Nothing yet.</p>'}
</main>
${older}
</body>
</html>`;
}

// One export, drawn the way the app draws it: the layout's row shape, empty
// rows hidden on the 42, captions or the numbered list per the titles option.
function card(row) {
  let slots = [];
  try {
    slots = JSON.parse(row.slots);
  } catch {
    // A row that will not parse draws as an empty grid rather than breaking the page.
  }
  const bySlot = new Map(slots.map((entry) => [entry.slot, entry]));
  const shape = ROWS[row.layout] || [];
  const hideEmptyRows = row.layout === 'fortyTwo';
  const overlay = row.labels === 'overlay';

  const drawn = [];
  const filledByRow = [];
  let first = 1;
  for (const width of shape) {
    const cells = [];
    const filled = [];
    for (let offset = 0; offset < width; offset += 1) {
      const entry = bySlot.get(first + offset);
      if (entry) filled.push(entry);
      cells.push(tile(entry, overlay));
    }
    filledByRow.push(filled);
    if (!(hideEmptyRows && filled.length === 0)) {
      drawn.push(`<div class="row" style="grid-template-columns:repeat(${width},1fr)">${cells.join('')}</div>`);
    }
    first += width;
  }

  const list = row.labels === 'list'
    ? numberedList(filledByRow, SECTIONS[row.layout] || [], hideEmptyRows)
    : '';
  const meta = [
    `#${row.id}`, row.created_on, row.layout, `titles ${row.labels}`,
    row.background, `v${row.app_version}`, `${slots.length} albums`,
  ].map(escape).join(' · ');

  return `<article class="card ${row.background === 'dark' ? 'dark' : 'light'}">
  <p class="meta">${meta}</p>
  <div class="export"><div class="grid">${drawn.join('')}</div>${list}</div>
</article>`;
}

// Numbered over placed albums, not slots, one block per section, like the app.
function numberedList(filledByRow, sections, hideEmptyRows) {
  let number = 0;
  let rowIndex = 0;
  const blocks = [];
  for (const rowsInSection of sections) {
    const lines = [];
    for (let i = 0; i < rowsInSection && rowIndex < filledByRow.length; i += 1, rowIndex += 1) {
      for (const entry of filledByRow[rowIndex]) {
        number += 1;
        lines.push(`<li><span>${number}.</span> ${escape(entry.artist)} – ${escape(entry.album)}</li>`);
      }
    }
    if (lines.length || !hideEmptyRows) blocks.push(`<ol>${lines.join('')}</ol>`);
  }
  return `<div class="list">${blocks.join('')}</div>`;
}

// The name always sits under the image. Last.fm's 300px file 404s on first
// request for about one cover in eight (decisions/0003), and a failed image
// with an empty alt draws nothing, so the name shows instead of a blank tile.
// The CSP rules out an onerror handler, which is why it is done this way.
function tile(entry, overlay) {
  if (!entry) return '<div class="tile blank"></div>';
  const name = `${entry.artist} – ${entry.album}`;
  const art = entry.cover && isCover(entry.cover)
    ? `<img src="${escape(entry.cover)}" alt="" data-name="${escape(name)}" loading="lazy">`
    : '';
  const caption = overlay ? `<span class="caption">${escape(name)}</span>` : '';
  return `<div class="tile" title="${escape(name)}"><span class="missing">${escape(name)}</span>${art}${caption}</div>`;
}

function escape(value) {
  const entities = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
  return String(value).replace(/[&<>"']/g, (c) => entities[c]);
}

function text(status, message) {
  return new Response(message, { status, headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
}
