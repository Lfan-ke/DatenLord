#!/usr/bin/env python3
import json
import re
import subprocess
import sys
from collections import defaultdict
from datetime import date, timedelta
from html import escape as html_escape
from pathlib import Path

README = Path('README.md')
DOCS = Path('public')
REPO = 'Lfan-ke/DatenLord'
REPO_URL = f'https://github.com/{REPO}'
ISSUE_URL = 'https://github.com/datenlord/training/issues/74'
COMPLETION = 'completed: all done.'

ROW_RE = re.compile(
    r'^\| `(?P<time>[^`]+)` \| `(?P<branch>[^`]+)` \| \[`(?P<sha>[^`]+)`\]\((?P<url>[^)]+)\) \| (?P<title>.+?) \| `[^`]+` \| `[^`]+` \|\s*$'
)


def filestat(sha):
    try:
        r = subprocess.run(
            ['git', 'show', '--name-status', '--format=', sha],
            capture_output=True, text=True, check=False,
        )
        a = m = d = 0
        for line in r.stdout.splitlines():
            if not line.strip():
                continue
            ch = line[0]
            if ch in ('A', 'C'):
                a += 1
            elif ch in ('M', 'R', 'T'):
                m += 1
            elif ch == 'D':
                d += 1
        return (a, m, d)
    except Exception:
        return (0, 0, 0)

COURSES = [
    {'old': '6.004', 'new': '6.1910', 'name': 'Computation Structures',
     'tag': 'Digital circuits · ISA · single-cycle / pipelined RISC-V',
     'icon': 'material-cpu-64-bit',
     'res_label': 'Bilibili video',
     'res_url': 'https://b23.tv/o7YjSkA'},
    {'old': '6.175', 'new': '6.1920', 'name': 'Constructive Computer Architecture',
     'tag': 'Bluespec microarchitecture · pipelining · caches · multicore',
     'icon': 'material-cog-transfer',
     'res_label': 'csg.csail.mit.edu/6.175',
     'res_url': 'http://csg.csail.mit.edu/6.175/index.html'},
    {'old': '6.375', 'new': '6.5900', 'name': 'Computer System Architecture',
     'tag': 'Memory hierarchy · OoO execution · vector & GPU',
     'icon': 'material-server-network',
     'res_label': 'csg.csail.mit.edu/6.375',
     'res_url': 'http://csg.csail.mit.edu/6.375/6_375_2019_www/index.html'},
]


def remote_branches():
    try:
        r = subprocess.run(
            ['git', 'for-each-ref', '--format=%(refname:short)', 'refs/remotes/origin'],
            capture_output=True, text=True, check=False,
        )
    except Exception:
        return []
    out = []
    for line in r.stdout.splitlines():
        name = line.strip()
        if name.startswith('origin/'):
            name = name[7:]
        if name and name not in ('main', 'gh-pages', 'HEAD'):
            out.append(name)
    return out


def shortstat(sha):
    try:
        r = subprocess.run(
            ['git', 'show', '--shortstat', '--format=', sha],
            capture_output=True, text=True, check=False,
        )
    except Exception:
        return {'files': 0, 'insertions': 0, 'deletions': 0}
    text = r.stdout or ''

    def grab(pat):
        m = re.search(pat, text)
        return int(m.group(1)) if m else 0
    return {
        'files': grab(r'(\d+) files? changed'),
        'insertions': grab(r'(\d+) insertions?'),
        'deletions': grab(r'(\d+) deletions?'),
    }


def parse_entries():
    seen, out = set(), []
    for line in README.read_text(encoding='utf-8').splitlines():
        m = ROW_RE.match(line.strip())
        if not m:
            continue
        d = {k: v.strip() for k, v in m.groupdict().items()}
        if d['sha'] in seen:
            continue
        seen.add(d['sha'])
        d['title'] = d['title'].replace('\\|', '|')
        d['is_completion'] = COMPLETION in d['title'].lower()
        fa, fm, fd = filestat(d['sha'])
        d['files_added'] = fa
        d['files_modified'] = fm
        d['files_deleted'] = fd
        d.update(shortstat(d['sha']))
        out.append(d)
    return out


def completed_branches(entries):
    return {e['branch'] for e in entries if e['is_completion']}


def grid(cards):
    return '<div class="grid cards" markdown>\n\n' + '\n\n'.join(c.rstrip() for c in cards) + '\n\n</div>'


def card(icon, title, lines):
    head = f'-   :{icon}:{{ .lg .middle }} __{title}__\n\n    ---\n'
    body = '\n'.join(f'    {l}' if l else '' for l in lines)
    return f'{head}\n{body}\n'


def courses_grid(entries):
    done = completed_branches(entries)
    cards = []
    for c in COURSES:
        status = ':material-check-decagram:{ .completed } **Completed**' if c['new'] in done else ':material-progress-clock: In progress'
        cards.append(card(
            c['icon'],
            c['name'],
            [
                f'`{c["old"]}` &nbsp;→&nbsp; `{c["new"]}` · {status}',
                '',
                c['tag'],
                '',
                f'[:octicons-arrow-right-24: Branch]({REPO_URL}/tree/{c["new"]}) · '
                f'[:material-book-open-variant: {c["res_label"]}]({c["res_url"]})',
            ],
        ))
    return grid(cards)


def stats_grid(entries):
    done = completed_branches(entries)
    total_ins = sum(e['insertions'] for e in entries)
    total_dele = sum(e['deletions'] for e in entries)
    cards = [
        card('material-source-commit', str(len(entries)), ['Total commits', '', 'across all courses']),
        card('material-calendar-check', str(len({e['time'][:10] for e in entries})), ['Active days']),
        card('material-trophy', f'{len(done)} / {len(COURSES)}', ['Courses completed']),
        card('material-plus-circle', f'+{total_ins}', ['Lines added']),
        card('material-minus-circle', f'−{total_dele}', ['Lines removed']),
    ]
    return grid(cards)


def humanize(n):
    import math
    if n < 1000:
        return str(n)
    suffixes = ['', 'k', 'm', 'g']
    val = float(n)
    mag = 0
    while val >= 1000 and mag < len(suffixes) - 1:
        val /= 1000
        mag += 1
    x = math.floor(val * 10 + 0.5) / 10
    if x >= 1000 and mag < len(suffixes) - 1:
        val /= 1000
        mag += 1
        x = math.floor(val * 10 + 0.5) / 10
    if x < 10:
        return f'{x:.1f}{suffixes[mag]}'
    xi = math.floor(val + 0.5)
    if xi >= 1000 and mag < len(suffixes) - 1:
        val /= 1000
        mag += 1
        x = math.floor(val * 10 + 0.5) / 10
        return f'{x:.1f}{suffixes[mag]}'
    return f'{int(xi)}{suffixes[mag]}'


def recent_table(entries, n=5):
    rows = ['| Time | Batch | Hash | Summary | Codes | Files |',
            '| :---: | :---: | :---: | :---: | :---: | :---: |']
    for e in entries[:n]:
        rows.append(
            f'| `{e["time"]}` | `{e["branch"]}` | [`{e["sha"][:7]}`]({e["url"]})'
            f' | {e["title"]} | `+{humanize(e["insertions"])}/−{humanize(e["deletions"])}`'
            f' | `+{humanize(e["files_added"])}/${humanize(e["files_modified"])}/−{humanize(e["files_deleted"])}` |'
        )
    return '\n'.join(rows)


BRANCH_COLOR = {'6.1910': '#3b82f6', '6.1920': '#a855f7', '6.5900': '#10b981'}


def timeline_html(entries):
    if not entries:
        return '<p class="dl-tl-empty">No commits yet.</p>'
    out = ['<div class="dl-tl">']
    for e in sorted(entries, key=lambda x: x['time']):
        color = BRANCH_COLOR.get(e['branch'], '#64748b')
        cls = ' is-completion' if e['is_completion'] else ''
        d, _, t = e['time'].partition(' ')
        out += [
            f'<article class="dl-tl-entry{cls}" style="--c:{color}">',
            f'<header class="dl-tl-stamp"><time>{html_escape(d)}</time><span class="dl-tl-clock">{html_escape(t)}</span></header>',
            '<span class="dl-tl-dot"></span>',
            '<div class="dl-tl-card">',
            '<div class="dl-tl-row">',
            f'<span class="dl-tl-branch">{html_escape(e["branch"])}</span>',
            f'<a class="dl-tl-hash" href="{html_escape(e["url"])}" target="_blank" rel="noopener">{html_escape(e["sha"][:7])}</a>',
            '</div>',
            f'<div class="dl-tl-heading">{html_escape(e["title"])}</div>',
            '<ul class="dl-tl-metrics">',
            f'<li class="add">+{e["insertions"]}</li>',
            f'<li class="del">−{e["deletions"]}</li>',
            f'<li class="files">{e["files_added"]}A · {e["files_modified"]}M · {e["files_deleted"]}D</li>',
            '</ul>',
            '</div>',
            '</article>',
        ]
    out.append('</div>')
    return '\n'.join(out)


def hero(entries):
    if not entries:
        return ''
    e = entries[0]
    if e['is_completion']:
        return (
            '!!! success "🎉 Latest Milestone"\n'
            f'    **Course `{e["branch"]}` completed** at `{e["time"]}`\n\n'
            f'    [`{e["sha"]}`]({e["url"]}) — {e["title"]}\n'
        )
    return (
        f'!!! tip "Latest · `{e["branch"]}`"\n'
        f'    `{e["time"]}` · [`{e["sha"]}`]({e["url"]}) · +{e["insertions"]}/−{e["deletions"]} · {e["files_added"]}A/{e["files_modified"]}M/{e["files_deleted"]}D files\n\n'
        f'    {e["title"]}\n'
    )


def resources_section():
    cards = [
        card('material-play-circle', 'New driver guide',
             ['Bilibili — must-watch onboarding', '',
              '[:octicons-arrow-right-24: BV1u8411i7Qw](https://www.bilibili.com/video/BV1u8411i7Qw/)']),
        card('material-school', 'Experience sharing',
             ['Bilibili — alumni experience', '',
              '[:octicons-arrow-right-24: BV1cs4y1r7T3](https://www.bilibili.com/video/BV1cs4y1r7T3/)']),
        card('material-help-circle', 'Q&A',
             ['Frequently asked questions', '',
              '[:octicons-arrow-right-24: WeChat article](https://mp.weixin.qq.com/s/-MnRFCXHy5v-tt4MujfqtQ)']),
        card('material-note-text', 'Learning notes',
             ['Reference notes from community', '',
              '[:octicons-arrow-right-24: WeChat article](https://mp.weixin.qq.com/s/I5bPw_AUWTh2VgzAm4SHhg)']),
        card('material-account-group', 'QQ community',
             ['Join the learning QQ group', '',
              '[:octicons-arrow-right-24: Signup](https://mp.weixin.qq.com/s/gB7_y4CFFf7QIBUceNbsoA)']),
    ]
    return grid(cards)


def render_index(entries):
    return (
        '---\nhide:\n  - toc\n---\n\n'
        '# BSV Learning Repo\n\n'
        '!!! abstract ""\n'
        '    **MIT Architecture Courses** in Bluespec SystemVerilog · '
        f'Student **D202605002** · Tracked via [datenlord/training#74]({ISSUE_URL})\n\n'
        + hero(entries) + '\n'
        '## :material-school-outline: Courses\n\n' + courses_grid(entries) + '\n\n'
        '## :material-chart-timeline-variant: At a Glance\n\n' + stats_grid(entries) + '\n\n'
        '## :material-pulse: Recent Commits\n\n' + recent_table(entries, 5) + '\n\n'
        '## :material-library-shelves: Onboarding & Resources\n\n' + resources_section() + '\n\n'
        f'[:material-chart-bar: Stats](stats.md){{ .md-button .md-button--primary }} &nbsp; '
        f'[:material-timeline-clock-outline: Timeline](timeline.md){{ .md-button }} &nbsp; '
        f'[:material-source-branch: Repository]({REPO_URL}){{ .md-button }}\n'
    )


def render_timeline(entries, label, course=None):
    title = label if label != 'All' else 'Timeline'
    intro = ''
    if course:
        intro = (
            f'> **{course["name"]}** · `{course["old"]}` &nbsp;→&nbsp; `{course["new"]}` · '
            f'[Resource]({course["res_url"]}) · [Branch]({REPO_URL}/tree/{course["new"]})\n\n'
        )
    scope = f'on branch `{course["new"]}`' if course else 'across all branches'
    return (
        '---\nhide:\n  - toc\n---\n\n'
        f'# :material-timeline-clock-outline: {title}\n\n'
        + intro +
        '!!! note ""\n'
        f'    {len(entries)} commit(s) {scope}. A commit titled '
        '`completed: all done.` marks the course as finished.\n\n'
        + timeline_html(entries) + '\n'
    )


def render_stats(entries):
    by_branch = defaultdict(lambda: {'count': 0, 'ins': 0, 'dele': 0, 'files': 0})
    by_date_count = defaultdict(int)
    palette = ['#3b82f6', '#a855f7', '#10b981', '#f97316', '#ef4444', '#eab308']
    for e in entries:
        b = e['branch']
        by_branch[b]['count'] += 1
        by_branch[b]['ins'] += e['insertions']
        by_branch[b]['dele'] += e['deletions']
        by_branch[b]['files'] += e['files']
        by_date_count[e['time'][:10]] += 1

    branches = sorted(by_branch.keys())
    color = {b: palette[i % len(palette)] for i, b in enumerate(branches)}
    sorted_entries = sorted(entries, key=lambda x: x['time'])

    all_dates_raw = sorted(set(e['time'][:10] for e in entries))
    if all_dates_raw:
        d0 = date.fromisoformat(all_dates_raw[0])
        d1 = date.fromisoformat(all_dates_raw[-1])
    else:
        d0 = d1 = date.today()
    d_start = d0 - timedelta(days=3)
    d_end = min(d1 + timedelta(days=3), date.today())
    date_list = []
    cur = d_start
    while cur <= d_end:
        date_list.append(cur.isoformat())
        cur += timedelta(days=1)

    line_series = {}
    for b in branches:
        cum = 0
        ser = []
        for d in date_list:
            cum += sum(e['insertions'] + e['deletions']
                       for e in entries if e['branch'] == b and e['time'][:10] == d)
            ser.append([d, cum])
        line_series[b] = ser

    waterfall = []
    running = 0
    for e in sorted_entries:
        net = e['insertions'] - e['deletions']
        waterfall.append({
            'sha': e['sha'][:7],
            'time': e['time'],
            'branch': e['branch'],
            'ins': e['insertions'],
            'dele': e['deletions'],
            'before': running,
            'after': running + net,
            'net': net,
        })
        running += net

    files_series = []
    for e in sorted_entries:
        files_series.append({
            'sha': e['sha'][:7],
            'time': e['time'],
            'branch': e['branch'],
            'added': e['files_added'],
            'modified': e['files_modified'],
            'deleted': e['files_deleted'],
            'touched': e['files'],
        })

    candle = []
    for e in sorted_entries:
        ins = e['insertions']
        dele = e['deletions']
        net = ins - dele
        candle.append({
            'time': e['time'],
            'sha': e['sha'][:7],
            'branch': e['branch'],
            'values': [0, net, -dele, ins],
            'ins': ins,
            'dele': dele,
        })

    rose = [{'name': d, 'value': c} for d, c in sorted(by_date_count.items())]

    scatter = [{
        'time': e['time'],
        'branch': e['branch'],
        'ins': e['insertions'],
        'dele': e['deletions'],
        'size': e['insertions'] + e['deletions'],
        'label': e['title'][:40],
    } for e in entries]

    bar_branch = [
        {'branch': b, 'value': by_branch[b]['ins'] + by_branch[b]['dele']}
        for b in branches
    ]

    cal_data = [[d, c] for d, c in sorted(by_date_count.items())]
    cal_max = max(by_date_count.values()) if by_date_count else 1

    cal_year = d0.year if all_dates_raw else date.today().year
    cal_full_range = [date(cal_year, 1, 1).isoformat(), date(cal_year, 12, 31).isoformat()]

    day_meta = {}
    for e in sorted_entries:
        d = e['time'][:10]
        m = day_meta.setdefault(d, {'count': 0, 'lines': 0, 'branches': set()})
        m['count'] += 1
        m['lines'] += e['insertions'] + e['deletions']
        m['branches'].add(e['branch'])

    cal_nodes = []
    for d, m in sorted(day_meta.items()):
        primary = sorted(m['branches'])[0]
        cal_nodes.append({
            'name': d,
            'value': [d, m['count']],
            'symbolSize': min(34, max(14, 10 + m['count'] * 4)),
            'itemStyle': {'color': color[primary]},
            'lines': m['lines'],
            'branches': sorted(m['branches']),
        })
    cal_links = []
    active_days = sorted(day_meta.keys())
    for i in range(1, len(active_days)):
        cal_links.append({
            'source': active_days[i - 1],
            'target': active_days[i],
            'lineStyle': {'color': '#94a3b8', 'width': 1.5, 'curveness': 0.2},
        })

    branch_nodes = []
    for b in branches:
        commits = [e for e in sorted_entries if e['branch'] == b]
        children = []
        for e in commits:
            children.append({
                'name': e['sha'][:7],
                'value': max(1, e['insertions'] + e['deletions']),
                'ins': e['insertions'],
                'dele': e['deletions'],
                'label': e['title'][:36],
            })
        branch_nodes.append({
            'name': b,
            'itemStyle': {'color': color[b]},
            'children': children,
        })
    total_lines = sum(by_branch[b]['ins'] + by_branch[b]['dele'] for b in branches)
    total_pushes = sum(by_branch[b]['count'] for b in branches)
    treemap = [{
        'name': 'All branches · ' + str(total_pushes) + ' pushes · ' + str(total_lines) + ' lines',
        'itemStyle': {'color': 'rgba(148,163,184,0.10)'},
        'children': branch_nodes,
    }]

    completed = len(completed_branches(entries))
    active = remote_branches()
    total = len(active) if active else len(COURSES)
    completion_pct = round(completed / total * 100) if total else 0

    push_per_branch = [{'branch': b, 'value': by_branch[b]['count']} for b in branches]
    push_total = sum(p['value'] for p in push_per_branch)
    score_max = max([p['value'] for p in push_per_branch] + [1])

    data = {
        'branches': branches,
        'colors': [color[b] for b in branches],
        'date_list': date_list,
        'line_series': [{'branch': b, 'data': line_series[b]} for b in branches],
        'waterfall': waterfall,
        'candle': candle,
        'files_series': files_series,
        'rose': rose,
        'scatter': scatter,
        'bar_branch': bar_branch,
        'cal_data': cal_data,
        'cal_range': [d_start.isoformat(), d_end.isoformat()],
        'cal_full_range': cal_full_range,
        'cal_max': cal_max,
        'cal_nodes': cal_nodes,
        'cal_links': cal_links,
        'treemap': treemap,
        'completion_pct': completion_pct,
        'completed': completed,
        'total': total,
        'push_total': push_total,
        'push_per_branch': push_per_branch,
        'score_max': score_max,
    }

    return (
        '---\nhide:\n  - toc\n---\n\n'
        '# :material-view-dashboard-variant: Dashboard\n\n'
        + stats_grid(entries) + '\n\n'
        '### :material-trophy-variant: Commit Score · per-branch contribution to ' + str(push_total) + ' commits\n\n'
        '<div id="chart-score" class="echart" style="height:380px"></div>\n\n'
        '### :material-chart-line-stacked: Cumulative Code Volume · Step lines per branch\n\n'
        '<div id="chart-line" class="echart" style="height:380px"></div>\n\n'
        '### :material-chart-waterfall: Waterfall · Net change cascading commit by commit\n\n'
        '<div id="chart-waterfall" class="echart" style="height:380px"></div>\n\n'
        '### :material-view-grid: Treemap · Branches contain their commits\n\n'
        '<div id="chart-treemap" class="echart" style="height:420px"></div>\n\n'
        '<div class="stats-grid" markdown>\n'
        '<div class="echart" id="chart-rose" style="height:380px"></div>\n'
        '<div class="echart" id="chart-scatter" style="height:380px"></div>\n'
        '</div>\n\n'
        '### :material-calendar-heart: Calendar Heatmap · Daily commit activity\n\n'
        '<div id="chart-calendar" class="echart" style="height:220px"></div>\n\n'
        '### :material-chart-areaspline-variant: Candlestick · Per-commit insertions (up) vs deletions (down)\n\n'
        '<div id="chart-candle" class="echart" style="height:380px"></div>\n\n'
        '### :material-file-tree: File Δ · Files added (↑) vs deleted (↓) per commit + lines net\n\n'
        '<div id="chart-files" class="echart" style="height:380px"></div>\n\n'
        '### :material-graph-outline: Commit Flow · Calendar graph with branch arrows\n\n'
        '<div id="chart-calgraph" class="echart" style="height:240px"></div>\n\n'
        '### :material-podium: Score Ring · per-branch share of ' + str(push_total) + ' commits\n\n'
        '<div id="chart-score-ring" class="echart" style="height:380px"></div>\n\n'
        '### :material-gauge: Course Progress · ' + str(completed) + ' / ' + str(total) + '\n\n'
        '<div id="chart-gauge" class="echart" style="height:380px"></div>\n\n'
        '<script id="stats-data" type="application/json">' + json.dumps(data) + '</script>\n'
    )


def main():
    entries = parse_entries()
    DOCS.mkdir(exist_ok=True)
    (DOCS / 'index.md').write_text(render_index(entries), encoding='utf-8')
    (DOCS / 'timeline.md').write_text(render_timeline(entries, 'All'), encoding='utf-8')
    (DOCS / 'stats.md').write_text(render_stats(entries), encoding='utf-8')
    for c in COURSES:
        be = [e for e in entries if e['branch'] == c['new']]
        (DOCS / f'timeline-{c["new"]}.md').write_text(
            render_timeline(be, c['new'], course=c), encoding='utf-8'
        )
    total = sum(e['insertions'] + e['deletions'] for e in entries)
    print(f'rendered {len(entries)} entries · {len(completed_branches(entries))} completed · {total} lines touched', file=sys.stderr)


if __name__ == '__main__':
    main()
