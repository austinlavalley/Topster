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
// The export's own measurements, in the app's canvas pixels. The gallery draws
// everything as a fraction of these, so a card is the export to scale. Keep in
// step with ExportCanvas, ExportSidebar and ExportWatermark in RenderView.
const CANVAS = {
  grid: 3366,
  margin: 72,
  gap: 24,
  list: 1600,
  listLead: 24,
  markFont: 40,
  markBottom: 12,
  listFont: { fortyTwo: 36, twenty: 56, twentyWide: 56, twentyFive: 56 },
};
const LABELS = new Set(['none', 'overlay', 'list']);
const BACKGROUNDS = new Set(['light', 'dark']);
// Every placed album is a Last.fm album with Last.fm art, from these hosts.
const COVER_HOST = /^lastfm[a-z0-9-]*\.freetls\.fastly\.net$/;
const MAX_BODY = 32 * 1024;
// One CSS pixel per canvas pixel at this scale, so a 3366px grid draws 720px.
const SCALE = 720 / CANVAS.grid;

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
    const { slot, artist, album } = entry;
    if (!Number.isInteger(slot) || slot < 1 || slot > capacity || seen.has(slot)) {
      return 'Bad slot number';
    }
    if (!isName(artist) || !isName(album)) return 'Bad name';
    seen.add(slot);
    // A cover that fails the host check is dropped rather than the export. If
    // Last.fm ever moves its art, the gallery shows names instead of nothing.
    clean.push({ slot, artist, album, cover: isCover(entry.cover) ? entry.cover : null });
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
  const nonce = crypto.randomUUID();

  return new Response(page(results.slice(0, limit), total, limit, hasOlder, nonce), {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Robots-Tag': 'noindex',
      'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy': "default-src 'none'; img-src https://*.freetls.fastly.net 'self'; "
        + `style-src 'unsafe-inline'; script-src 'nonce-${nonce}'`,
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

function page(rows, total, limit, hasOlder, nonce) {
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
  header, main, .more { max-width: 1180px; margin-left: auto; margin-right: auto; }
  header h1 { font-size: 22px; letter-spacing: -0.01em; margin: 0 0 4px; }
  header p { margin: 0 0 24px; color: #9a978f; }
  /* minmax(0, 1fr), not auto: an auto column grows to its widest card and
     pushes the page sideways on a phone. */
  main { display: grid; grid-template-columns: minmax(0, 1fr); gap: 28px; }
  .card { width: fit-content; max-width: 100%; }
  .meta { margin: 0 0 8px; opacity: .55;
    font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }

  /* The sheet is the exported image to scale. Every measurement inside it is
     a fraction of the app's canvas, through --u (one canvas pixel). */
  .sheet { position: relative; display: flex; align-items: flex-start; max-width: 100%;
    container-type: inline-size; border: 1px solid #34373a; }
  .sheet.light { background: #fff; color: #111; }
  .sheet.dark { background: #000; color: #f2f2f2; }
  .gridblock { padding: calc(var(--u) * ${CANVAS.margin}); }
  .grid { width: calc(var(--u) * ${CANVAS.grid}); display: grid; gap: calc(var(--u) * ${CANVAS.gap}); }
  .row { display: grid; gap: calc(var(--u) * ${CANVAS.gap}); }
  .tile { position: relative; aspect-ratio: 1; overflow: hidden; background: #8a8a8e;
    container-type: inline-size; }
  .tile.blank { opacity: .45; }
  .tile img { position: absolute; inset: 0; display: block; width: 100%; height: 100%; object-fit: cover; }
  /* Drawn only when the image fails, over the browser's broken-image icon. */
  .tile img::after { content: attr(data-name); position: absolute; inset: 0; display: flex;
    align-items: center; justify-content: center; padding: 4cqw; text-align: center;
    font-size: 5cqw; line-height: 1.25; color: #fff; background: #8a8a8e; }
  .missing { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
    padding: 4cqw; text-align: center; font-size: 5cqw; line-height: 1.25; color: #fff; }
  .caption { position: absolute; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,.6); color: #fff;
    padding: 2.5cqw 2.75cqw; font-size: 5.5cqw; line-height: 1.2; font-weight: 500;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

  .listblock { padding: calc(var(--u) * ${CANVAS.margin}) calc(var(--u) * ${CANVAS.margin})
    calc(var(--u) * ${CANVAS.margin}) calc(var(--u) * ${CANVAS.listLead}); }
  .list { position: relative; width: calc(var(--u) * ${CANVAS.list});
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
  .list ol { position: absolute; left: 0; right: 0; margin: 0; padding: 0; list-style: none; }
  .list li + li { margin-top: .35em; }
  .list .n { display: inline-block; min-width: 2.2em; text-align: right; }

  .mark { position: absolute; left: 0; right: 0; bottom: calc(var(--u) * ${CANVAS.markBottom});
    display: flex; align-items: center; justify-content: center; opacity: .7;
    gap: calc(var(--u) * ${CANVAS.markFont * 0.4}); font-size: calc(var(--u) * ${CANVAS.markFont});
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-weight: 600; }
  .mark img { width: calc(var(--u) * ${CANVAS.markFont * 1.15});
    height: calc(var(--u) * ${CANVAS.markFont * 1.15}); border-radius: calc(var(--u) * ${CANVAS.markFont * 0.3}); }

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
<script nonce="${nonce}">
// A cover that fails falls back to the next size down, the way the app races
// them. Last.fm's 300px file 404s on first request for about one in eight.
document.addEventListener('error', (event) => {
  const img = event.target;
  if (img.tagName !== 'IMG') return;
  const rest = (img.dataset.rest || '').split(' ').filter(Boolean);
  if (!rest.length) return;
  img.dataset.rest = rest.slice(1).join(' ');
  img.src = rest[0];
}, true);

// Each list section starts level with its band of rows, and the list ends at
// the bottom of the grid: a section too tall for its band pulls up into the
// slack above. Same rule as ExportList.groupTops in the app, which needs the
// rendered height of each section and so has to run here.
function packLists() {
  for (const list of document.querySelectorAll('.list')) {
    const grid = list.closest('.sheet').querySelector('.grid');
    const unit = grid.getBoundingClientRect().width / ${CANVAS.grid};
    const gap = ${CANVAS.gap} * unit;
    const blocks = [...list.querySelectorAll('ol')];
    const heights = blocks.map((block) => block.getBoundingClientRect().height);
    const tops = [];
    let ceiling = Number(list.dataset.floor) * unit;
    for (let i = blocks.length - 1; i >= 0; i -= 1) {
      tops[i] = Math.min(Number(blocks[i].dataset.top) * unit, ceiling - heights[i]);
      ceiling = tops[i] - gap;
    }
    const overflow = tops.length && tops[0] < 0 ? -tops[0] : 0;
    blocks.forEach((block, i) => { block.style.top = (tops[i] + overflow) + 'px'; });
  }
}
addEventListener('load', packLists);
addEventListener('resize', packLists);
</script>
</body>
</html>`;
}

// One export, drawn as the app draws it: the layout's row shape, empty rows
// hidden on the 42, captions or the numbered list per the titles option, the
// watermark in the bottom margin, all to scale.
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
  const withList = row.labels === 'list';

  // Walk the rows the export draws, tracking where each one lands on the
  // canvas so the list can line up with them.
  const drawn = [];
  const rows = [];
  let top = 0;
  let first = 1;
  for (const width of shape) {
    const cells = [];
    const filled = [];
    for (let offset = 0; offset < width; offset += 1) {
      const entry = bySlot.get(first + offset);
      if (entry) filled.push(entry);
      cells.push(tile(entry, overlay));
    }
    const height = (CANVAS.grid - CANVAS.gap * (width - 1)) / width;
    const visible = !(hideEmptyRows && filled.length === 0);
    rows.push({ filled, top, height, visible });
    if (visible) {
      drawn.push(`<div class="row" style="grid-template-columns:repeat(${width},1fr)">${cells.join('')}</div>`);
      top += height + CANVAS.gap;
    }
    first += width;
  }
  const floor = top > 0 ? top - CANVAS.gap : 0;

  const total = CANVAS.grid + CANVAS.margin * 2
    + (withList ? CANVAS.listLead + CANVAS.list + CANVAS.margin : 0);
  const style = `--u:${(100 / total).toFixed(5)}cqw;width:${Math.round(total * SCALE)}px`;
  const list = withList ? numberedList(rows, SECTIONS[row.layout] || [], hideEmptyRows, floor, row.layout) : '';
  const meta = [
    `#${row.id}`, row.created_on, row.layout, `titles ${row.labels}`,
    row.background, `v${row.app_version}`, `${slots.length} albums`,
  ].map(escape).join(' · ');

  return `<article class="card">
  <p class="meta">${meta}</p>
  <div class="sheet ${row.background === 'dark' ? 'dark' : 'light'}" style="${style}">
    <div class="gridblock"><div class="grid">${drawn.join('')}</div></div>${list}
    <div class="mark"><img src="/images/favic.png" alt=""><span>Made with topster.app</span></div>
  </div>
</article>`;
}

// Numbered over placed albums, not slots, one block per section, each starting
// level with its band of rows. The browser does the final placement.
function numberedList(rows, sections, hideEmptyRows, floor, layout) {
  let number = 0;
  let rowIndex = 0;
  const blocks = [];
  for (const rowsInSection of sections) {
    const lines = [];
    let sectionTop = null;
    for (let i = 0; i < rowsInSection && rowIndex < rows.length; i += 1, rowIndex += 1) {
      const row = rows[rowIndex];
      if (!row.visible) continue;
      if (sectionTop === null) sectionTop = row.top;
      for (const entry of row.filled) {
        number += 1;
        lines.push(`<li><span class="n">${number}.</span> ${escape(entry.artist)} – ${escape(entry.album)}</li>`);
      }
    }
    if (sectionTop === null && hideEmptyRows) continue;
    blocks.push(`<ol data-top="${sectionTop ?? 0}">${lines.join('')}</ol>`);
  }
  const size = CANVAS.listFont[layout] || 56;
  return `<div class="listblock"><div class="list" data-floor="${floor}"
    style="font-size:calc(var(--u) * ${size});height:calc(var(--u) * ${floor})">${blocks.join('')}</div></div>`;
}

// Last.fm keeps the size in the path (`/i/u/300x300/<hash>.png`), so the
// smaller files can be named from the one the app sent. The app races these
// same sizes because the 300px file 404s on first request for about one cover
// in eight; see decisions/0003. Deriving them here rather than sending them
// keeps this a web-only change and repairs rows already stored.
function coverSizes(cover) {
  if (!isCover(cover)) return [];
  const sizes = [cover];
  if (/\/i\/u\/[^/]+\//.test(cover)) {
    for (const size of ['174s', '64s']) {
      const smaller = cover.replace(/\/i\/u\/[^/]+\//, `/i/u/${size}/`);
      if (!sizes.includes(smaller)) sizes.push(smaller);
    }
  }
  return sizes;
}

function tile(entry, overlay) {
  if (!entry) return '<div class="tile blank"></div>';
  const name = `${entry.artist} – ${entry.album}`;
  const covers = coverSizes(entry.cover);
  const art = covers.length
    ? `<img src="${escape(covers[0])}" alt="" data-name="${escape(name)}"`
      + ` data-rest="${escape(covers.slice(1).join(' '))}" loading="lazy">`
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
