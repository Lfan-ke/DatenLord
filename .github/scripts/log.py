#!/usr/bin/env python3
import json
import os
import re
import subprocess
from datetime import datetime, timezone, timedelta
from pathlib import Path

CST = timezone(timedelta(hours=8))
README = Path('README.md')
MARKER = '<!-- more -->'
SECTION = '## Learning Log'
TABLE_HEAD = '| Time | Batch | Hash | Summary | Δ | Files |\n| :---: | :---: | :---: | :---: | :---: | :---: |'
HINT = '> Records of every commit on a course branch. A commit titled `completed: all done.` marks the course as finished.'
COURSE_NAME = {'6.1910': 'MIT 6.1910', '6.1920': 'MIT 6.1920', '6.5900': 'MIT 6.5900'}
COURSE_OLD = {'6.1910': '6.004', '6.1920': '6.175', '6.5900': '6.375'}
COURSE_DESC = {
    '6.1910': 'Computation Structures',
    '6.1920': 'Constructive Computer Architecture',
    '6.5900': 'Computer System Architecture',
}
ROW_RE = re.compile(r'^\| `\d{4}-')
COMPLETION = 'completed: all done.'
TRAILER_RE = re.compile(r'^[A-Za-z][A-Za-z0-9-]*:\s+\S')


def split_msg(msg):
    lines = msg.rstrip('\n').splitlines()
    if not lines:
        return '', '', ''
    title = lines[0]
    rest = lines[1:]
    while rest and not rest[0].strip():
        rest.pop(0)
    if not rest:
        return title, '', ''
    last_blank = -1
    for i in range(len(rest) - 1, -1, -1):
        if not rest[i].strip():
            last_blank = i
            break
    tail = rest[last_blank + 1:] if last_blank >= 0 else rest
    trailers = ''
    if tail and all(TRAILER_RE.match(l) for l in tail if l.strip()):
        trailers = '\n'.join(l for l in tail if l.strip())
        rest = rest[:last_blank] if last_blank >= 0 else []
    while rest and not rest[-1].strip():
        rest.pop()
    return title, '\n'.join(rest), trailers


def fmt_ts(iso):
    dt = datetime.fromisoformat(iso.replace('Z', '+00:00')).astimezone(CST)
    return dt.strftime('%Y-%m-%d %H:%M:%S')


def fmt_ts_min(iso):
    dt = datetime.fromisoformat(iso.replace('Z', '+00:00')).astimezone(CST)
    return dt.strftime('%Y-%m-%d %H:%M')


def is_completion(title):
    return title.strip().lower() == COMPLETION


def render_title(title):
    if is_completion(title):
        return f'**✅ {title}**'
    return title


def numstat(sha):
    try:
        r = subprocess.run(
            ['git', 'show', '--shortstat', '--format=', sha],
            capture_output=True, text=True, check=False,
        )
        out = r.stdout.strip().splitlines()
        line = out[-1] if out else ''
        ins = re.search(r'(\d+) insertion', line)
        dele = re.search(r'(\d+) deletion', line)
        return (int(ins.group(1)) if ins else 0, int(dele.group(1)) if dele else 0)
    except Exception:
        return (0, 0)


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


def entry_line(branch, sha, msg, ts, repo_url):
    short = sha[:7]
    title = msg.split('\n', 1)[0].replace('|', '\\|')
    if len(title) > 38:
        title = title[:35] + '...'
    ins, dele = numstat(sha)
    fa, fm, fd = filestat(sha)
    return (f"| `{fmt_ts_min(ts)}` | `{branch}` | [`{short}`]({repo_url}/commit/{sha})"
            f" | {render_title(title)} | `+{humanize(ins)}/−{humanize(dele)}`"
            f" | `+{humanize(fa)}/${humanize(fm)}/−{humanize(fd)}` |")


def parse_log(text):
    idx = text.find(SECTION)
    if idx == -1:
        return text.rstrip() + '\n', [], [], ''
    head = text[:idx]
    body = text[idx + len(SECTION):].lstrip('\n')
    if MARKER in body:
        top, bot = body.split(MARKER, 1)
    else:
        top, bot = body, ''
    top_entries = [l for l in top.splitlines() if ROW_RE.match(l)]
    bot_entries = [l for l in bot.splitlines() if ROW_RE.match(l)]
    m = re.search(r'</details>\s*', bot)
    if m:
        footer = bot[m.end():].strip()
    else:
        skip = ('|', '<details>', '<summary>', '</details>')
        footer = '\n'.join(
            l for l in bot.splitlines()
            if l.strip() and not l.strip().startswith(skip)
        ).strip()
    return head, top_entries, bot_entries, footer


def write_log(head, entries, footer=''):
    out = head.rstrip() + '\n\n' + SECTION + '\n\n' + HINT + '\n\n'
    if entries:
        out += TABLE_HEAD + '\n' + '\n'.join(entries[:2]) + '\n\n'
    out += MARKER + '<br/>\n\n'
    rest = entries[2:]
    if rest:
        out += '<details>\n\n<summary><b>Older records</b></summary>\n\n<br />\n\n'
        out += TABLE_HEAD + '\n' + '\n'.join(rest) + '\n\n</details>\n'
    if footer:
        out += '\n' + footer + '\n'
    return out


CODE_BADGE_RE = re.compile(r'(https://img\.shields\.io/badge/CODE-)[^?]+(\?[^"]+)')
DELTA_CELL_RE = re.compile(r'`\+([\d.]+[kmg]?)\s*/\s*−([\d.]+[kmg]?)`', re.IGNORECASE)
SUFFIX = {'': 1, 'k': 1000, 'm': 1_000_000, 'g': 1_000_000_000}


def parse_humanize(s):
    m = re.match(r'^(\d+(?:\.\d+)?)([kmg]?)$', s.strip().lower())
    return int(float(m.group(1)) * SUFFIX[m.group(2)]) if m else 0


def total_delta(entry_lines):
    ins = dele = 0
    for line in entry_lines:
        cells = [c.strip() for c in line.split('|')]
        if len(cells) < 7:
            continue
        m = DELTA_CELL_RE.match(cells[5])
        if m:
            ins += parse_humanize(m.group(1))
            dele += parse_humanize(m.group(2))
    return ins, dele


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


def refresh_code_badge(text, entry_lines):
    ins, dele = total_delta(entry_lines)
    new_msg = f'%2B{humanize(ins)}%20%7C%20%E2%88%92{humanize(dele)}'
    return CODE_BADGE_RE.sub(r'\g<1>' + new_msg + r'-22c55e\g<2>', text)


def build_comment(branch, sha, msg, author, ts, repo_url, diffstat):
    short = sha[:7]
    title, body_text, trailers = split_msg(msg)
    course = COURSE_NAME.get(branch, branch)
    old = COURSE_OLD.get(branch, '')
    desc = COURSE_DESC.get(branch, '')
    finished = is_completion(title)
    commit_url = f'{repo_url}/commit/{sha}'
    branch_url = f'{repo_url}/tree/{branch}'
    issue_url = 'https://github.com/datenlord/training/issues/74'

    def badge(label, value, color):
        l = label.replace(' ', '_').replace('-', '--')
        v = value.replace(' ', '_').replace('-', '--')
        return f'https://img.shields.io/badge/{l}-{v}-{color}?style=for-the-badge&labelColor=0f172a'

    sections = []

    if finished:
        trophy = badge('🏆 Course Completed', course, '22c55e')
        meta_row = (
            f'<a href="{branch_url}"><img src="{badge("Branch", branch, "2563eb")}" alt="Branch"></a>'
            f' <a href="{commit_url}"><img src="{badge(fmt_ts(ts)[:10], fmt_ts(ts)[11:], "64748b")}" alt="Time"></a>'
            f' <a href="{commit_url}"><img src="{badge("Hash", short, "7c3aed")}" alt="Hash"></a>'
            f' <a href="{issue_url}"><img src="{badge("Student", "D202605002", "e11d48")}" alt="Student"></a>'
        )
        header = [
            f'## 🏆 {course} · Course Completed',
            '',
            '<div align="center">',
            '',
            f'<a href="{branch_url}"><img src="{trophy}" alt="Course Completed"></a>',
            '',
            f'### {desc}',
            f'<sub>`{old}` &nbsp;➜&nbsp; `{branch}` · *milestone reached*</sub>',
            '',
            '<br/>',
            '',
            meta_row,
            '',
            '<br/>',
            '',
            '**🎓 All labs complete — milestone reached!**',
            '',
            f'<sub>by <b>{author}</b> · `{fmt_ts(ts)}` UTC+8</sub>',
            '',
            '</div>',
        ]
    else:
        badges_row = (
            f'<a href="{branch_url}"><img src="{badge("Branch", branch, "2563eb")}" alt="Branch"></a>'
            f' <a href="{commit_url}"><img src="{badge(fmt_ts(ts)[:10], fmt_ts(ts)[11:], "64748b")}" alt="Time"></a>'
            f' <a href="{commit_url}"><img src="{badge("Hash", short, "7c3aed")}" alt="Hash"></a>'
        )
        header = [f'## {title}', '']
        if body_text:
            header += ['<br/>', '']
        header += [
            '<div align="center">',
            '',
            badges_row,
            '',
            '</div>',
            '',
            '<br/>',
            '',
            f'<sub>by <b>{author}</b> · `{fmt_ts(ts)}` UTC+8</sub>',
        ]
    sections.append(header)

    body_block = []
    if body_text:
        body_block.append(body_text)
    if trailers:
        if body_block:
            body_block.append('')
        body_block.extend('> ' + l for l in trailers.splitlines())
    if body_block:
        sections.append(body_block)

    if diffstat:
        sections.append([
            '<details>',
            '<summary><b>📝 Changes</b></summary>',
            '',
            '```',
            diffstat.strip(),
            '```',
            '',
            '</details>',
        ])

    sections.append([
        f'<sub>Auto-synced from <a href="{commit_url}"><code>{branch}@{short}</code></a> · Student ID: <b>D202605002</b></sub>'
    ])

    return '\n\n---\n\n'.join('\n'.join(s) for s in sections)


def diffstat(sha):
    try:
        r = subprocess.run(
            ['git', 'show', '--stat', '--format=', sha],
            capture_output=True, text=True, check=False,
        )
        return r.stdout
    except Exception:
        return ''


def keep_commit(c):
    if (c.get('author') or {}).get('name', '') == 'github-actions[bot]':
        return False
    files = (c.get('added') or []) + (c.get('removed') or []) + (c.get('modified') or [])
    if files and all(f.startswith('.github/') for f in files):
        return False
    return True


def main():
    branch = os.environ['BRANCH_NAME']
    repo_url = os.environ['REPO_URL']
    commits = [c for c in json.loads(os.environ['COMMITS_JSON']) if keep_commit(c)]
    if not commits:
        Path(os.environ['GITHUB_OUTPUT']).open('a').write('changed=false\n')
        return

    text = README.read_text(encoding='utf-8') if README.exists() else '# BSV Learning Repo\n\n'
    head, top, bot, footer = parse_log(text)
    existing = top + bot
    seen = {re.search(r'\[`([0-9a-f]+)`\]', l).group(1) for l in existing if re.search(r'\[`([0-9a-f]+)`\]', l)}

    new_lines = []
    for c in commits:
        if c['id'][:7] in seen:
            continue
        new_lines.append(entry_line(branch, c['id'], c['message'], c['timestamp'], repo_url))

    if not new_lines:
        Path(os.environ['GITHUB_OUTPUT']).open('a').write('changed=false\n')
        return

    entries = list(reversed(new_lines)) + existing
    new_text = refresh_code_badge(write_log(head, entries, footer), entries)
    README.write_text(new_text, encoding='utf-8')

    head_commit = commits[-1]
    stat = diffstat(head_commit['id'])
    body = build_comment(branch, head_commit['id'], head_commit['message'],
                         head_commit['author']['name'], head_commit['timestamp'], repo_url, stat)
    body_path = Path('/tmp/issue_body.md')
    body_path.write_text(body, encoding='utf-8')

    with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
        f.write('changed=true\n')
        f.write(f'body_file={body_path}\n')


if __name__ == '__main__':
    main()
