#!/usr/bin/env python3
"""Build docs/overview.html — a human-readable view of the project's tech specs
and structure, from the docs/ tree alone.

Reads: architecture.md, features.md, roadmap.md, risks.md, model.md,
requirements/F-*.md. Writes one self-contained HTML file. No network, no deps,
no external reports. The page is DERIVED — edit the sources, regenerate.
"""
import argparse, datetime, html, os, re, sys

# ---------------------------------------------------------------- utilities

def read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return ""

def section(text, heading_re):
    """Body of the first '## <heading_re>' up to the next '## '."""
    m = re.search(r"^##\s+" + heading_re + r".*$", text, re.M | re.I)
    if not m:
        return ""
    rest = text[m.end():]
    nxt = re.search(r"^##\s", rest, re.M)
    return rest[:nxt.start()] if nxt else rest

def table_rows(body):
    """Rows of the first markdown table in body, as lists of cells."""
    out = []
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if all(re.fullmatch(r":?-{2,}:?", c) for c in cells if c):
            continue
        if out == [] and any(c.lower() in ("id", "#", "layer", "service", "date") for c in cells):
            continue  # header row
        out.append(cells)
    return out

def e(s):
    return html.escape(s or "", quote=True)

def is_placeholder(s):
    s = (s or "").strip()
    return s in ("", "—", "-", "TBD", "TBC", "none") or s.startswith("<")

# ---------------------------------------------------------------- parsers

def parse_architecture(text):
    arch = {"purpose": "", "stack": [], "modules": [], "flow": "", "services": []}
    body = section(text, r"1\.")
    for para in body.strip().split("\n\n"):
        para = para.strip()
        if para and not para.startswith(("<", "|", "-", "#")):
            arch["purpose"] = para
            break
    for row in table_rows(section(text, r"2\.")):
        if len(row) >= 3 and not is_placeholder(row[1]):
            arch["stack"].append({"layer": row[0], "choice": row[1], "why": row[2]})
    for line in section(text, r"3\.").splitlines():
        m = re.match(r"\s*[-*]\s+`?([\w\-./]+)`?\s*[—-]\s*(.*)", line)
        if not m:
            continue
        name, rest = m.group(1), m.group(2)
        if name.lower() in ("example", "name"):
            continue
        deps = []
        dm = re.search(r"depends on\s+(.*)", rest, re.I)
        purpose = re.split(r";\s*depends on", rest, flags=re.I)[0].strip(" .;")
        if dm and "nothing" not in dm.group(1).lower():
            deps = [d for d in re.findall(r"`?([\w\-./]+)`?", dm.group(1)) if d.lower() != "nothing"]
        arch["modules"].append({"name": name, "purpose": purpose, "deps": deps})
    arch["flow"] = " ".join(section(text, r"4\.").split())[:400]
    for row in table_rows(section(text, r"5\.")):
        if len(row) >= 2 and not is_placeholder(row[0]):
            arch["services"].append({"name": row[0], "purpose": row[1]})
    return arch

FEATURE_SECTIONS = [("Planned", "planned"), ("In progress", "in-progress"),
                    ("Shipped", "shipped"), ("Deprecated", "deprecated")]

def parse_features(text):
    feats = []
    for heading, status in FEATURE_SECTIONS:
        for line in section(text, re.escape(heading)).splitlines():
            m = re.match(r"\s*[-*]\s+(?:\[[ x]\]\s*)?\[?(F-\d+)\]?\s+([\w\-]+)\s*[—-]\s*(.*)", line)
            if not m:
                continue
            desc = re.split(r"\s+[—-]\s+", m.group(3))[0].strip()
            feats.append({"id": m.group(1), "slug": m.group(2), "desc": desc, "status": status})
    return feats

ROADMAP_LANES = [(r"Now", "Сейчас"), (r"Next", "Дальше"),
                 (r"Later", "Потом"), (r"Explicitly NOT", "Не делаем")]

def parse_roadmap(text):
    lanes = []
    for pat, label in ROADMAP_LANES:
        items = []
        for line in section(text, pat).splitlines():
            m = re.match(r"\s*(?:\d+\.|[-*])\s+`?([\w\-./]+)`?\s*[—-]\s*(.*)", line)
            if m and not m.group(1).startswith("<"):
                items.append({"what": m.group(1), "why": m.group(2).strip()})
        if items:
            lanes.append({"label": label, "items": items})
    return lanes

def parse_risks(text, today):
    risks = []
    for row in table_rows(section(text, r"Open")):
        if len(row) < 6 or is_placeholder(row[0]):
            continue
        review = row[5]
        overdue = None
        dm = re.search(r"(\d{4})-(\d{2})-(\d{2})", review)
        if dm:
            due = datetime.date(*map(int, dm.groups()))
            if due < today:
                overdue = (today - due).days
        risks.append({"id": row[0], "date": row[1], "what": row[3],
                      "reason": row[4], "review": review, "overdue": overdue})
    return risks

REQ_FIELD = {"mid": r"^mid:\s*(.+)$", "status": r"^status:\s*(.+)$",
             "ears": r"^Acceptance \(EARS\):\s*(.+)$", "source": r"^Source:\s*(.+)$"}

def _brace(block, key):
    m = re.search(key + r":\s*\{(.*?)\}", block, re.S)
    if not m:
        return {}
    out = {}
    for part in m.group(1).split(","):
        if ":" in part:
            k, v = part.split(":", 1)
            out[k.strip()] = v.strip()
    return out

def parse_requirement_file(path):
    text = read(path)
    fm = {}
    m = re.match(r"\s*---\n(.*?)\n---\n", text, re.S)
    if m:
        for line in m.group(1).splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip()
    feature = {"id": fm.get("id", ""), "slug": fm.get("slug", ""),
               "status": fm.get("status", ""), "frs": [], "nfrs": [], "scs": []}
    blocks = re.split(r"^###\s+", text, flags=re.M)[1:]
    for block in blocks:
        head = block.splitlines()[0].strip()
        rid = head.split()[0]
        title = head[len(rid):].strip()
        item = {"id": rid, "title": title}
        for key, pat in REQ_FIELD.items():
            mm = re.search(pat, block, re.M)
            item[key] = mm.group(1).strip() if mm else ""
        if rid.startswith("FR"):
            item["verify"] = _brace(block, "verify")
            item["code"] = _brace(block, "code")
            feature["frs"].append(item)
        elif rid.startswith("NFR"):
            mm = re.search(r"^Threshold:\s*(.+)$", block, re.M)
            parts = [p.strip() for p in (mm.group(1) if mm else "").split("·")]
            item["threshold"] = parts[0] if parts else ""
            item["command"] = next((p.split(":", 1)[1].strip() for p in parts
                                    if p.lower().startswith("proving command")), "")
            item["counter"] = next((p.split(":", 1)[1].strip() for p in parts
                                    if p.lower().startswith("counter-metric")), "")
            feature["nfrs"].append(item)
    for row in table_rows(section(text, r"Success criteria")):
        if len(row) >= 5 and not is_placeholder(row[0]):
            feature["scs"].append({"id": row[0], "text": row[1], "status": row[2].lower(),
                                   "evidence": row[3], "checked": row[4]})
    return feature

def parse_requirements(docs):
    d = os.path.join(docs, "requirements")
    if not os.path.isdir(d):
        return {}
    out = {}
    for name in sorted(os.listdir(d)):
        if name.endswith(".md") and name.startswith("F-"):
            f = parse_requirement_file(os.path.join(d, name))
            if f["id"]:
                out[f["id"]] = f
    return out

# ---------------------------------------------------------------- derivations

STAGES = [("идея", "ld-1"), ("продумана", "ld-2"), ("в работе", "ld-3"),
          ("сделана", "ld-4"), ("подтверждена", "ld-5"), ("снята", "ld-6")]

def stage_of(feature, req):
    if feature["status"] == "deprecated":
        return "снята"
    if feature["status"] == "shipped":
        if req and any(sc["status"] == "met" for sc in req["scs"]):
            return "подтверждена"
        return "сделана"
    if feature["status"] == "in-progress":
        return "в работе"
    return "продумана" if req else "идея"

def module_of(req_item, modules):
    path = (req_item.get("code") or {}).get("path", "")
    if not path:
        return ""
    parts = [p for p in path.split("/") if p not in ("src", "lib", "")]
    names = {m["name"].strip("/") for m in modules}
    for p in parts:
        if p in names:
            return p + "/"
    return ""

def evidence_state(item):
    ev = (item.get("verify") or {}).get("evidence", "")
    if is_placeholder(ev):
        return ("crit", "нет свидетельства")
    code = item.get("code") or {}
    if code.get("path") and not os.path.exists(code["path"]):
        return ("warn", "файл связи не найден")
    return ("ok", "свидетельство заявлено")

def ears_ru(text):
    """Render the EARS modal in the prose register, emphasised."""
    out = e(text)
    out = re.sub(r"\bSHALL NOT\b", "<b>НЕ ДОЛЖЕН</b>", out)
    out = re.sub(r"\bSHALL\b", "<b>ДОЛЖЕН</b>", out)
    return out

# ---------------------------------------------------------------- svg graph

def build_graph(modules):
    if not modules or len(modules) > 15:
        return ""
    names = [m["name"].strip("/") for m in modules]
    by = {m["name"].strip("/"): m for m in modules}
    depth, guard = {}, 0
    while len(depth) < len(names) and guard < 40:
        guard += 1
        for n in names:
            deps = [d.strip("/") for d in by[n]["deps"] if d.strip("/") in by]
            if all(d in depth for d in deps):
                depth[n] = 1 + max([depth[d] for d in deps], default=-1)
    for n in names:
        depth.setdefault(n, 0)
    cols = {}
    for n in names:
        cols.setdefault(depth[n], []).append(n)
    W, H, GX, GY = 158, 52, 96, 30
    pos, height = {}, max(len(c) for c in cols.values()) * (H + GY)
    for d in sorted(cols):
        col = cols[d]
        span = len(col) * (H + GY) - GY
        y0 = (height - span) / 2.0
        for i, n in enumerate(col):
            pos[n] = (24 + d * (W + GX), y0 + i * (H + GY))
    total_w = 24 + (max(cols) + 1) * (W + GX) - GX + 24
    parts = ['<svg viewBox="0 0 %d %d" role="img" aria-label="Граф зависимостей модулей">' % (total_w, height + 24),
             '<defs><marker id="arw" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="7" '
             'markerHeight="7" orient="auto-start-reverse"><path d="M0,1 L9,5 L0,9 z" fill="currentColor"/>'
             '</marker></defs>']
    for n in names:  # edge: dependency -> dependent ("используется в")
        for dep in by[n]["deps"]:
            dep = dep.strip("/")
            if dep not in pos:
                continue
            x1, y1 = pos[dep][0] + W, pos[dep][1] + H / 2
            x2, y2 = pos[n][0], pos[n][1] + H / 2
            parts.append('<path class="edge" d="M%.0f,%.0f C%.0f,%.0f %.0f,%.0f %.0f,%.0f" '
                         'marker-end="url(#arw)"/>' % (x1, y1, x1 + 46, y1, x2 - 46, y2, x2 - 8, y2))
    for n in names:
        x, y = pos[n]
        m = by[n]
        parts.append(
            '<g class="node"><rect class="node-box" x="%.0f" y="%.0f" width="%d" height="%d" rx="6"/>'
            '<text class="node-name" x="%.0f" y="%.0f">%s/</text>'
            '<text class="node-meta" x="%.0f" y="%.0f">%s</text></g>'
            % (x, y, W, H, x + 14, y + 24, e(n), x + 14, y + 41, e(m["purpose"][:30])))
    parts.append("</svg>")
    return "".join(parts)

# ---------------------------------------------------------------- rendering

CSS = read(os.path.join(os.path.dirname(os.path.abspath(__file__)), "page.css"))

def mid_tag(item):
    """Short mid under the id — the identity that survives renames and renumbering."""
    mid = (item.get("mid") or "").strip()
    return '<br><span class="mid">%s</span>' % e(mid[:8]) if mid else ""

def pill(kind, text):
    return '<span class="pill %s">%s</span>' % (kind, e(text))

def render(root, docs, out_path):
    today = datetime.date.today()
    arch = parse_architecture(read(os.path.join(docs, "architecture.md")))
    feats = parse_features(read(os.path.join(docs, "features.md")))
    lanes = parse_roadmap(read(os.path.join(docs, "roadmap.md")))
    risks = parse_risks(read(os.path.join(docs, "risks.md")), today)
    reqs = parse_requirements(docs)

    for f in feats:
        f["stage"] = stage_of(f, reqs.get(f["id"]))
    frs = [(fid, i) for fid, r in sorted(reqs.items()) for i in r["frs"]]
    nfrs = [(fid, i) for fid, r in sorted(reqs.items()) for i in r["nfrs"]]
    scs = [(fid, s) for fid, r in sorted(reqs.items()) for s in r["scs"]]
    counts = {s: sum(1 for f in feats if f["stage"] == s) for s, _ in STAGES}
    total = max(len(feats), 1)
    proven = sum(1 for _, i in frs + nfrs if evidence_state(i)[0] == "ok")

    P = ['<title>Обзор проекта</title>',
         '<link rel="preconnect" href="https://fonts.googleapis.com">',
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
         'family=Bricolage+Grotesque:opsz,wght@12..96,700&family=JetBrains+Mono:wght@400;500;700&'
         'family=Public+Sans:wght@0,400;0,600&display=swap">',
         "<style>%s</style>" % CSS]

    A = P.append
    A('<header class="masthead"><h1>%s</h1>' % e(arch["purpose"] or "Обзор проекта"))
    A('<div class="chips">'
      '<span class="chip"><span class="k">фич</span><b>%d</b></span>'
      '<span class="chip"><span class="k">модулей</span><b>%d</b></span>'
      '<span class="chip"><span class="k">ФТТ</span><b>%d</b></span>'
      '<span class="chip"><span class="k">НТТ</span><b>%d</b></span>'
      '<span class="chip"><span class="k">со свидетельством</span><b>%d / %d</b></span>'
      '<span class="chip"><span class="k">собрано</span><b>%s</b></span></div></header>'
      % (len(feats), len(arch["modules"]), len(frs), len(nfrs),
         proven, len(frs) + len(nfrs), today.strftime("%d.%m.%Y")))

    # --- 01 readiness ---
    A('<section><h2>01 · Готовность фич</h2>'
      '<p class="note">Ступень выводится из того, какие файлы есть на диске, а не из мнения. '
      '«Продумана» — спека одобрена и требования записаны, кода нет. '
      '«Сделана» — код в основной ветке. «Подтверждена» — критерий успеха отмечен met.</p>')
    A('<div class="card pad"><div class="ladder">')
    for name, cls in STAGES:
        if counts[name]:
            A('<div class="%s" style="width:%.1f%%">%d</div>' % (cls, 100.0 * counts[name] / total, counts[name]))
    A("</div><div class='ladder-key'>")
    for i, (name, cls) in enumerate(STAGES):
        A('<span class="lk"><i class="%s"></i><b>%02d %s</b> — %d</span>' % (cls, i + 1, name, counts[name]))
    A("</div></div></section>")

    # --- 02 ФТТ/НТТ ---
    A('<section><h2>02 · ФТТ / НТТ — требования</h2>'
      '<p class="note">Живые файлы требований: текущая правда о фиче, а не снимок на момент спеки. '
      'Идентификаторы остаются английскими и греппаемыми — человеческий регистр живёт в заголовках.</p>')
    A('<div class="tablewrap"><table><thead><tr><th>ID</th><th>Тип</th>'
      '<th>Формулировка (EARS)</th><th>Проверка</th><th>Свидетельство</th><th>Состояние</th></tr></thead><tbody>')
    for fid, i in frs:
        kind, label = evidence_state(i)
        v = i.get("verify") or {}
        A('<tr><td class="id">%s/%s%s</td><td>ФТТ%s</td><td class="ears">%s</td><td>%s</td>'
          '<td class="ev">%s</td><td>%s</td></tr>'
          % (e(fid), e(i["id"]), mid_tag(i),
             " " + pill("neutral", i["status"]) if i["status"] == "changed" else "",
             ears_ru(i["ears"]) or '<span class="muted">формулировка не записана</span>',
             e(" · ".join(x for x in (v.get("method"), v.get("oracle")) if x and not is_placeholder(x))) or "—",
             e(v.get("evidence", "")) or "—", pill(kind, label)))
    for fid, i in nfrs:
        A('<tr><td class="id">%s/%s%s</td><td>НТТ%s</td><td class="ears">%s</td><td>порог</td>'
          '<td class="ev">%s</td><td>%s</td></tr>'
          % (e(fid), e(i["id"]), mid_tag(i),
             " " + pill("neutral", i["status"]) if i["status"] == "changed" else "",
             e(i["threshold"]), e(i["command"]) or "—",
             pill("ok" if i["command"] else "crit",
                  "команда заявлена" if i["command"] else "нечем доказать")))
    A("</tbody></table></div>")

    anatomy = next((x for x in frs if (x[1].get("code") or {}).get("path")), None)
    if anatomy:
        fid, i = anatomy
        code = i["code"]
        v = i.get("verify") or {}
        A('<h3>Анатомия одного требования</h3>'
          '<p class="note">Происхождение, метод проверки, связь с кодом и история — на одном экране, '
          'без археологии по коммитам.</p><div class="req-card">')
        A('<div class="rc-top"><span class="rc-id">%s/%s</span>%s%s</div>'
          % (e(fid), e(i["id"]), pill("neutral", "ФТТ"), pill("neutral", "status: " + (i["status"] or "?"))))
        A('<dl class="rc-grid">'
          '<dt>mid</dt><dd class="mono">%s <span class="muted">— записан однажды, переживает переименования</span></dd>'
          '<dt>Формулировка</dt><dd class="ears">%s</dd>'
          '<dt>Источник</dt><dd>%s</dd>'
          '<dt>Проверка</dt><dd class="mono">method: %s · oracle: %s · evidence: %s</dd>'
          '<dt>Связь с кодом</dt><dd class="mono">%s → %s · sha256 %s · проверено %s</dd></dl>'
          % (e(i["mid"]), ears_ru(i["ears"]), e(i["source"]),
             e(v.get("method", "—")), e(v.get("oracle", "—")), e(v.get("evidence", "—")),
             e(code.get("path", "")), e(code.get("symbol", "")),
             e(code.get("sha256", "")), e(code.get("verified_at", ""))))
        A("</div>")
    A("</section>")

    # --- 03 NFR thresholds ---
    A('<section><h2>03 · НТТ: пороги и доказывающие команды</h2>'
      '<p class="note">У каждой НТТ порог с единицами, команда, которая его доказывает, '
      'и контр-метрика, которой запрещено ухудшаться.</p>'
      '<div class="tablewrap"><table><thead><tr><th>ID</th><th>Порог</th>'
      '<th>Доказывающая команда</th><th>Контр-метрика</th><th>Состояние</th></tr></thead><tbody>')
    for fid, i in nfrs:
        A('<tr><td class="id">%s/%s</td><td>%s</td><td class="ev">%s</td><td>%s</td><td>%s</td></tr>'
          % (e(fid), e(i["id"]), e(i["threshold"]), e(i["command"]) or "—",
             e(i["counter"]) if not is_placeholder(i["counter"]) else "—",
             pill("ok", "команда заявлена") if i["command"] else pill("crit", "нечем доказать")))
    A("</tbody></table></div></section>")

    # --- 04 success criteria ---
    if scs:
        met = sum(1 for _, s in scs if s["status"] == "met")
        missed = sum(1 for _, s in scs if s["status"] == "missed")
        A('<section><h2>04 · Критерии успеха</h2>'
          '<p class="note">Единственный слой, смотрящий наружу: не «тест зелёный», '
          'а «дало ли это результат». Колонками владеет <span class="mono">/validate</span>.</p>')
        A('<div class="stats"><div class="stat ok"><span class="k">met</span><span class="v">%d</span></div>'
          '<div class="stat crit"><span class="k">missed</span><span class="v">%d</span></div>'
          '<div class="stat warn"><span class="k">unchecked</span><span class="v">%d</span></div></div>'
          % (met, missed, len(scs) - met - missed))
        A('<div class="tablewrap"><table><thead><tr><th>ID</th><th>Критерий</th>'
          '<th>Статус</th><th>Свидетельство</th><th>Проверено</th></tr></thead><tbody>')
        for fid, s in scs:
            kind = {"met": "ok", "missed": "crit"}.get(s["status"], "warn")
            A('<tr><td class="id">%s/%s</td><td>%s</td><td>%s</td><td>%s</td><td class="id">%s</td></tr>'
              % (e(fid), e(s["id"]), e(s["text"]), pill(kind, s["status"]), e(s["evidence"]), e(s["checked"])))
        A("</tbody></table></div></section>")

    # --- 05 map + stack ---
    A('<section><h2>05 · Карта системы</h2>')
    graph = build_graph(arch["modules"])
    if graph:
        A('<div class="card"><figure class="diagram">%s<figcaption>Стрелка B → A читается '
          '«B используется в A»: слева — модули без зависимостей. %s</figcaption></figure></div>' % (graph, e(arch["flow"])))
    else:
        A('<p class="note">Модулей больше 15 — граф свёрнут в список.</p>')
    A('<div class="tablewrap" style="margin-top:14px"><table><thead><tr><th>Модуль</th>'
      '<th>Назначение</th><th>Зависит от</th><th>Требований</th></tr></thead><tbody>')
    for m in arch["modules"]:
        n = sum(1 for _, i in frs if module_of(i, arch["modules"]).strip("/") == m["name"].strip("/"))
        A('<tr><td class="id">%s</td><td>%s</td><td class="mono">%s</td><td class="id">%s</td></tr>'
          % (e(m["name"]), e(m["purpose"]), e(", ".join(m["deps"]) or "—"), n or "—"))
    A("</tbody></table></div></section>")

    if arch["stack"]:
        A('<section><h2>06 · Архитектурный стек</h2>'
          '<p class="note">Колонка «почему» защищает решение от переигрывания на каждом ревью. '
          'Пустая ячейка — решение без причины.</p>'
          '<div class="tablewrap"><table><thead><tr><th>Слой</th><th>Выбор</th><th>Почему</th></tr></thead><tbody>')
        for s in arch["stack"]:
            A('<tr><td>%s</td><td class="id">%s</td><td>%s</td></tr>'
              % (e(s["layer"]), e(s["choice"]), e(s["why"]) or pill("warn", "не записано")))
        A("</tbody></table></div></section>")

    # --- 07 features ---
    A('<section><h2>07 · Фичи построчно</h2><div class="tablewrap"><table><thead><tr>'
      '<th>ID</th><th>Фича</th><th>Описание</th><th>Статус</th><th>Ступень</th>'
      '<th>Требований</th></tr></thead><tbody>')
    for f in feats:
        r = reqs.get(f["id"])
        n = len(r["frs"]) + len(r["nfrs"]) if r else 0
        kind = {"подтверждена": "ok", "сделана": "warn", "в работе": "accent",
                "снята": "crit"}.get(f["stage"], "neutral")
        A('<tr><td class="id">%s</td><td class="mono">%s</td><td>%s</td><td>%s</td><td>%s</td>'
          '<td class="id">%s</td></tr>'
          % (e(f["id"]), e(f["slug"]), e(f["desc"]), pill("neutral", f["status"]),
             pill(kind, f["stage"]), n or "—"))
    A("</tbody></table></div></section>")

    # --- 08 roadmap ---
    if lanes:
        A('<section><h2>08 · Дорожная карта в разрезе статусов</h2>'
          '<p class="note">Полоса отвечает «когда», статус — «как записано», ступень — «что есть на диске». '
          'Расхождение между вторым и третьим и есть интересное.</p>'
          '<div class="tablewrap"><table><thead><tr><th>Полоса</th><th>Элемент</th>'
          '<th>Почему</th><th>Статус</th><th>Ступень</th></tr></thead><tbody>')
        by_slug = {f["slug"]: f for f in feats}
        for lane in lanes:
            for it in lane["items"]:
                f = by_slug.get(it["what"])
                st = pill("neutral", f["status"]) if f else pill("crit", "отказ" if lane["label"] == "Не делаем" else "нет в features.md")
                stg = pill("neutral", f["stage"]) if f else "—"
                A('<tr><td><b>%s</b></td><td class="mono">%s</td><td>%s</td><td>%s</td><td>%s</td></tr>'
                  % (e(lane["label"]), e(it["what"]), e(it["why"]), st, stg))
        A("</tbody></table></div></section>")

    # --- 09 risks ---
    if risks:
        A('<section><h2>09 · Принятые риски</h2>'
          '<p class="note">Каждая строка появилась потому, что находку критика перекрыли override.</p>'
          '<div class="tablewrap"><table><thead><tr><th>ID</th><th>Принят</th><th>Что принято</th>'
          '<th>Причина</th><th>Пересмотреть</th></tr></thead><tbody>')
        for r in risks:
            mark = pill("crit", "просрочен на %d дн." % r["overdue"]) if r["overdue"] else pill("neutral", r["review"])
            A('<tr><td class="id">%s</td><td class="id">%s</td><td>%s</td><td><i>%s</i></td><td>%s</td></tr>'
              % (e(r["id"]), e(r["date"]), e(r["what"]), e(r["reason"]), mark))
        A("</tbody></table></div></section>")

    A('<footer class="end">Страница производная: правьте файлы в <span class="mono">docs/</span> '
      'и перегенерируйте через <span class="mono">/overview</span>. Собрано %s из '
      '<span class="mono">%s</span>.</footer>' % (today.strftime("%d.%m.%Y"), e(os.path.abspath(docs))))

    page = "\n".join(P)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(page)
    return {"features": len(feats), "modules": len(arch["modules"]),
            "fr": len(frs), "nfr": len(nfrs), "risks": len(risks), "out": out_path}

def main():
    ap = argparse.ArgumentParser(description="Generate the project overview page from docs/.")
    ap.add_argument("root", nargs="?", default=".", help="project root (contains docs/)")
    ap.add_argument("-o", "--out", default=None, help="output path (default <root>/docs/overview.html)")
    a = ap.parse_args()
    docs = os.path.join(a.root, "docs")
    if not os.path.isdir(docs):
        sys.stderr.write("no docs/ under %s — run /init first\n" % os.path.abspath(a.root))
        return 1
    out = a.out or os.path.join(docs, "overview.html")
    s = render(a.root, docs, out)
    print("overview: %(features)d фич · %(modules)d модулей · %(fr)d ФТТ · %(nfr)d НТТ · "
          "%(risks)d рисков → %(out)s" % s)
    return 0

if __name__ == "__main__":
    sys.exit(main())
