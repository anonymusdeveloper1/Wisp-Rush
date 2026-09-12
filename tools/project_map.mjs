#!/usr/bin/env node
// Builds docs/generated/PROJECT_MAP.md — an exhaustive, auto-generated index of the Godot project
// (autoloads, input actions, layers, groups, scenes, scripts, resources, signal connections, assets,
// docs) so agents can orient without crawling every file. Never hand-edit the output; re-run this.
//
//   node tools/project_map.mjs           write/refresh the map
//   node tools/project_map.mjs --check   exit 1 if the committed map is stale
//   node tools/project_map.mjs --stdout  print instead of writing
//
// No dependencies; output is deterministic (sorted, no timestamps) so --check is reliable.

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join, relative, sep, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = join(ROOT, 'docs', 'generated', 'PROJECT_MAP.md');
// Top-level folders that are not game content (addons are summarised separately).
const SKIP_TOP = new Set(['addons', 'docs', 'tools', 'build', 'export', 'logs', 'node_modules']);
const ASSET_LIST_CAP = 400;

const toRes = (abs) => 'res://' + relative(ROOT, abs).split(sep).join('/');
const toRepo = (abs) => relative(ROOT, abs).split(sep).join('/');
const read = (abs) => readFileSync(abs, 'utf8');
const cell = (s) => String(s ?? '').replace(/\|/g, '\\|').replace(/\r?\n/g, ' ').trim() || '—';
const tick = (s) => (s ? '`' + String(s).replace(/`/g, '') + '`' : '—');
const list = (arr) => (arr.length ? arr.map(tick).join(', ') : '—');

function walk(dir, out = []) {
  for (const name of readdirSync(dir).sort()) {
    if (name.startsWith('.')) continue;
    const abs = join(dir, name);
    if (statSync(abs).isDirectory()) {
      if (dir === ROOT && SKIP_TOP.has(name)) continue;
      if (existsSync(join(abs, '.gdignore'))) continue;
      walk(abs, out);
    } else {
      out.push(abs);
    }
  }
  return out;
}

// --- project.godot (Godot ConfigFile: [section] + key=value; values may span lines) -------------
function parseConfig(text) {
  const sections = { '': {} };
  let current = '';
  for (const line of text.split(/\r?\n/)) {
    const sec = line.match(/^\[([^\]]+)\]\s*$/);
    if (sec) {
      current = sec[1];
      sections[current] ??= {};
      continue;
    }
    const kv = line.match(/^([A-Za-z0-9_\/.\-]+)=(.*)$/);
    if (kv) sections[current][kv[1]] = kv[2];
  }
  return sections;
}
const unquote = (v) => (v ?? '').replace(/^"(.*)"$/, '$1');

// --- .tscn / .tres (sections with attributes, then `key = value` properties) --------------------
function parseAttrs(s) {
  const o = {};
  for (const m of s.matchAll(/(\w+)=("([^"]*)"|\[[^\]]*\]|[^\s\]]+)/g)) o[m[1]] = m[3] ?? m[2];
  return o;
}
function parseSections(text) {
  const out = [];
  let cur = null;
  for (const line of text.split(/\r?\n/)) {
    const head = line.match(/^\[(gd_scene|gd_resource|ext_resource|sub_resource|node|connection|editable|resource)\b(.*)\]\s*$/);
    if (head) {
      cur = { tag: head[1], attrs: parseAttrs(head[2]), props: {} };
      out.push(cur);
      continue;
    }
    const kv = cur && line.match(/^([\w\/:.]+)\s*=\s*(.*)$/);
    if (kv) cur.props[kv[1]] = kv[2];
  }
  return out;
}
const extId = (v) => (v || '').match(/ExtResource\(\s*"([^"]+)"\s*\)/)?.[1];

function parseScene(text) {
  const secs = parseSections(text);
  const ext = new Map(secs.filter((s) => s.tag === 'ext_resource').map((s) => [s.attrs.id, s.attrs]));
  const nodes = secs.filter((s) => s.tag === 'node');
  const root = nodes.find((n) => n.attrs.parent === undefined) || nodes[0];
  const pathOf = (v) => ext.get(extId(v))?.path;
  const rootType = root
    ? root.attrs.type || (root.attrs.instance ? `inherits ${pathOf(root.attrs.instance) ?? '?'}` : '?')
    : '?';
  const instances = [...new Set(nodes.map((n) => pathOf(n.attrs.instance)).filter(Boolean))].sort();
  const scripts = [...new Set(nodes.map((n) => pathOf(n.props.script)).filter(Boolean))].sort();
  const connections = secs
    .filter((s) => s.tag === 'connection')
    .map((s) => ({ signal: s.attrs.signal, from: s.attrs.from, to: s.attrs.to, method: s.attrs.method }));
  const groups = [...new Set(nodes.flatMap((n) => (n.attrs.groups || '').match(/"([^"]+)"/g) || []))]
    .map((g) => g.replace(/"/g, ''))
    .sort();
  return {
    root: root?.attrs.name ?? '?',
    rootType,
    rootScript: pathOf(root?.props.script),
    nodeCount: nodes.length,
    instances,
    scripts,
    connections,
    groups,
  };
}

// --- .gd -----------------------------------------------------------------------------------------
function parseScript(text) {
  const header = text.match(/^class_name\s+(\w+)(?:\s+extends\s+(\S+))?/m);
  const ext = text.match(/^extends\s+(\S+)/m)?.[1] ?? header?.[2];
  // Class doc brief = first non-empty `##` line before the first member declaration.
  let brief = '';
  for (const raw of text.split(/\r?\n/)) {
    const l = raw.trim();
    if (l.startsWith('##')) {
      const t = l.replace(/^##\s?/, '').trim();
      if (t && !t.startsWith('@')) { brief = t; break; }
      continue;
    }
    if (/^(signal|var|const|enum|func|static|class\s|@export|@onready)/.test(l)) break;
  }
  const all = (re) => [...text.matchAll(re)].map((m) => m[1]);
  return {
    className: header?.[1],
    extends: ext,
    tool: /^@tool\b/m.test(text),
    brief,
    signals: all(/^signal\s+(\w+)/gm),
    exports: all(/^@export\w*(?:\([^)]*\))?\s+(?:@\w+(?:\([^)]*\))?\s+)*var\s+(\w+)/gm),
    methods: all(/^(?:static\s+)?func\s+([A-Za-z]\w*)\s*\(/gm),
  };
}

function parseResource(text) {
  const head = parseSections(text).find((s) => s.tag === 'gd_resource');
  return { type: head?.attrs.type ?? '?', scriptClass: head?.attrs.script_class };
}

// --- build ---------------------------------------------------------------------------------------
function build() {
  const cfgPath = join(ROOT, 'project.godot');
  const cfg = existsSync(cfgPath) ? parseConfig(read(cfgPath)) : {};
  const app = cfg.application ?? {};
  const files = walk(ROOT);
  const byExt = (e) => files.filter((f) => extname(f) === e);
  const scenes = byExt('.tscn').map((f) => ({ path: toRes(f), ...parseScene(read(f)) }));
  const scripts = byExt('.gd').map((f) => ({ path: toRes(f), ...parseScript(read(f)) }));
  const resources = byExt('.tres').map((f) => ({ path: toRes(f), ...parseResource(read(f)) }));
  const shaders = byExt('.gdshader').map(toRes);
  const assetsDir = join(ROOT, 'assets');
  const assets = existsSync(assetsDir)
    ? walk(assetsDir).filter((f) => !/\.(import|uid)$/.test(f) && !f.endsWith('.gitkeep')).map(toRes)
    : [];

  const L = [];
  const p = (...lines) => L.push(...lines);
  const table = (headers, rows) => {
    if (!rows.length) return p('_None._', '');
    p(`| ${headers.join(' | ')} |`, `|${headers.map(() => '---').join('|')}|`);
    rows.forEach((r) => p(`| ${r.join(' | ')} |`));
    p('');
  };

  p(
    '# Project Map (generated)',
    '',
    '> **AUTO-GENERATED by `node tools/project_map.mjs` — do not edit by hand.** Re-run it (or',
    '> `tools/validate.sh`) after adding, moving or deleting scenes, scripts, resources, autoloads,',
    '> input actions or assets. This file records **what exists**; what it **means** lives in',
    '> [../PROJECT_CONTEXT.md](../PROJECT_CONTEXT.md).',
    '',
    `**Main scene:** ${tick(unquote(app['run/main_scene']))} · ` +
      `**Features:** ${tick((app['config/features'] || '').replace(/^PackedStringArray\((.*)\)$/, '$1').replace(/"/g, ''))}`,
    '',
    `**Counts:** ${scenes.length} scenes · ${scripts.length} scripts · ${resources.length} resources · ` +
      `${shaders.length} shaders · ${assets.length} asset files`,
    '',
  );

  p('## Autoloads', '');
  table(
    ['Name', 'Path', 'Global name'],
    Object.entries(cfg.autoload ?? {}).map(([k, v]) => {
      const raw = unquote(v);
      return [tick(k), tick(raw.replace(/^\*/, '')), raw.startsWith('*') ? 'yes' : 'no'];
    }),
  );

  p('## Input actions', '');
  table(['Action'], Object.keys(cfg.input ?? {}).sort().map((k) => [tick(k)]));

  p('## Named physics / render / navigation layers', '');
  table(
    ['Key', 'Name'],
    Object.entries(cfg.layer_names ?? {}).sort().map(([k, v]) => [tick(k), cell(unquote(v))]),
  );

  p('## Global groups', '');
  table(
    ['Group', 'Description'],
    Object.entries(cfg.global_group ?? {}).sort().map(([k, v]) => [tick(k), cell(unquote(v))]),
  );

  p('## Scenes', '');
  table(
    ['Scene', 'Root (type)', 'Root script', 'Nodes', 'Instanced scenes', 'Groups used'],
    scenes.map((s) => [
      tick(s.path),
      `${tick(s.root)} (${cell(s.rootType)})`,
      tick(s.rootScript),
      String(s.nodeCount),
      list(s.instances),
      list(s.groups),
    ]),
  );

  const conns = scenes.flatMap((s) => s.connections.map((c) => [tick(s.path), tick(c.signal), `${tick(c.from)} → ${tick(c.to)}`, tick(c.method)]));
  p('### Editor-wired signal connections', '');
  table(['Scene', 'Signal', 'From → To', 'Method'], conns);

  p('## Scripts', '');
  table(
    ['Script', 'class_name', 'extends', 'Summary (`##` brief)', 'Signals', 'Exports', 'Public methods'],
    scripts.map((s) => [
      tick(s.path) + (s.tool ? ' 🛠' : ''),
      tick(s.className),
      tick(s.extends),
      cell(s.brief || '⚠ missing `##` class doc'),
      list(s.signals),
      list(s.exports),
      list(s.methods),
    ]),
  );

  p('## Resources (.tres)', '');
  table(['Resource', 'Type', 'Script class'], resources.map((r) => [tick(r.path), tick(r.type), tick(r.scriptClass)]));

  p('## Shaders', '');
  table(['Shader'], shaders.map((s) => [tick(s)]));

  p('## Addons', '');
  const addonsDir = join(ROOT, 'addons');
  const addons = existsSync(addonsDir)
    ? readdirSync(addonsDir).filter((n) => !n.startsWith('.') && statSync(join(addonsDir, n)).isDirectory()).sort()
    : [];
  const enabled = cfg.editor_plugins?.enabled ?? '';
  table(
    ['Addon', 'plugin.cfg name', 'Enabled'],
    addons.map((a) => {
      const pc = join(addonsDir, a, 'plugin.cfg');
      const name = existsSync(pc) ? unquote(parseConfig(read(pc)).plugin?.name) : '';
      return [tick(`res://addons/${a}`), cell(name), enabled.includes(`res://addons/${a}/`) ? 'yes' : 'no'];
    }),
  );

  p('## Assets', '');
  if (!assets.length) p('_None yet._', '');
  else {
    const counts = {};
    assets.forEach((a) => { const e = extname(a) || '(none)'; counts[e] = (counts[e] || 0) + 1; });
    p(Object.entries(counts).sort().map(([e, n]) => `${tick(e)} × ${n}`).join(' · '), '');
    assets.slice(0, ASSET_LIST_CAP).forEach((a) => p(`- ${tick(a)}`));
    if (assets.length > ASSET_LIST_CAP) p(`- _…and ${assets.length - ASSET_LIST_CAP} more (list capped at ${ASSET_LIST_CAP})._`);
    p('');
  }

  p('## Documentation index', '');
  const docRows = [];
  const docsDir = join(ROOT, 'docs');
  for (const sub of ['systems', 'decisions']) {
    const d = join(docsDir, sub);
    if (!existsSync(d)) continue;
    for (const f of readdirSync(d).filter((n) => n.endsWith('.md') && !n.startsWith('_')).sort()) {
      const title = read(join(d, f)).match(/^#\s+(.+)$/m)?.[1] ?? f;
      docRows.push([sub, `[${cell(title)}](../${sub}/${f})`]);
    }
  }
  table(['Kind', 'Document'], docRows);

  const undocumented = scripts.filter((s) => !s.brief).map((s) => s.path);
  p('## Documentation gaps', '');
  if (!undocumented.length) p('_None — every script has a `##` class doc._', '');
  else undocumented.forEach((s) => p(`- ⚠ ${tick(s)} has no \`##\` class doc`)), p('');

  return L.join('\n').replace(/\n+$/, '') + '\n';
}

const map = build();
const args = new Set(process.argv.slice(2));
if (args.has('--stdout')) {
  process.stdout.write(map);
} else if (args.has('--check')) {
  const current = existsSync(OUT) ? read(OUT) : '';
  if (current !== map) {
    console.error(`${toRepo(OUT)} is stale — run: node tools/project_map.mjs`);
    process.exit(1);
  }
  console.log(`${toRepo(OUT)} is up to date`);
} else {
  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, map);
}
