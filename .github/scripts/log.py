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
TABLE_HEAD = '| Time | Batch | Hash | Summary | Δ | Files |\n| --- | --- | --- | --- | --- | --- |'
HINT = '> Records of every commit on a course branch. A commit titled `completed: all done.` marks the course as finished.'
COURSE_NAME = {'6.1910': 'MIT 6.1910', '6.1920': 'MIT 6.1920', '6.5900': 'MIT 6.5900'}
ROW_RE = re.compile(r'^\| `\d{4}-')
COMPLETION = 'completed: all done.'


def fmt_ts(iso):
    dt = datetime.fromisoformat(iso.replace('Z', '+00:00')).astimezone(CST)
    return dt.strftime('%Y-%m-%d %H:%M:%S')


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
        a = d = 0
        for line in r.stdout.splitlines():
            if not line.strip():
                continue
            ch = line[0]
            if ch == 'A':
                a += 1
            elif ch == 'D':
                d += 1
        return (a, d)
    except Exception:
        return (0, 0)


def entry_line(branch, sha, msg, ts, repo_url):
    short = sha[:7]
    title = msg.split('\n', 1)[0].replace('|', '\\|')
    if len(title) > 41:
        title = title[:38] + '...'
    ins, dele = numstat(sha)
    fa, fd = filestat(sha)
    return (f"| `{fmt_ts(ts)}` | `{branch}` | [`{short}`]({repo_url}/commit/{sha})"
            f" | {render_title(title)} | `+{humanize(ins)} / −{humanize(dele)}`"
            f" | `+{humanize(fa)} / −{humanize(fd)}` |")


def parse_log(text):
    idx = text.find(SECTION)
    if idx == -1:
        return text.rstrip() + '\n', [], []
    head = text[:idx]
    body = text[idx + len(SECTION):].lstrip('\n')
    if MARKER in body:
        top, bot = body.split(MARKER, 1)
    else:
        top, bot = body, ''
    top_entries = [l for l in top.splitlines() if ROW_RE.match(l)]
    bot_entries = [l for l in bot.splitlines() if ROW_RE.match(l)]
    return head, top_entries, bot_entries


def write_log(head, entries):
    out = head.rstrip() + '\n\n' + SECTION + '\n\n' + HINT + '\n\n'
    if entries:
        out += TABLE_HEAD + '\n' + '\n'.join(entries[:2]) + '\n\n'
    out += MARKER + '\n\n'
    rest = entries[2:]
    if rest:
        out += '<details>\n<summary><b>Older records</b></summary>\n\n'
        out += TABLE_HEAD + '\n' + '\n'.join(rest) + '\n\n</details>\n'
    return out


CODE_BADGE_RE = re.compile(r'(https://img\.shields\.io/badge/CODE-)[^?]+(\?[^"]+)')


def total_delta(entry_lines):
    ins = dele = 0
    for line in entry_lines:
        m = re.search(r'`\+(\d+) / −(\d+)` \| `\+\d+ / −\d+` \|\s*$', line)
        if m:
            ins += int(m.group(1))
            dele += int(m.group(2))
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
    return (f'{x:.1f}'.rstrip('0').rstrip('.')) + suffixes[mag]


def refresh_code_badge(text, entry_lines):
    ins, dele = total_delta(entry_lines)
    new_msg = f'%2B{humanize(ins)}%20%7C%20%E2%88%92{humanize(dele)}'
    return CODE_BADGE_RE.sub(r'\g<1>' + new_msg + r'-22c55e\g<2>', text)


def build_comment(branch, sha, msg, author, ts, repo_url, diffstat):
    short = sha[:7]
    title = msg.split('\n', 1)[0]
    course = COURSE_NAME.get(branch, branch)
    finished = is_completion(title)
    commit_url = f'{repo_url}/commit/{sha}'
    branch_url = f'{repo_url}/tree/{branch}'

    def badge(label, value, color):
        l = label.replace(' ', '_').replace('-', '--')
        v = value.replace(' ', '_').replace('-', '--')
        return f'https://img.shields.io/badge/{l}-{v}-{color}?style=for-the-badge&labelColor=0f172a'

    body = []
    if finished:
        body += [
            '<div align="center">',
            '',
            f'# 🎉 Course Completed',
            '',
            f'### `{branch}` · {course}',
            '',
            f'<img src="{badge("Status", "Completed", "22c55e")}" alt="Completed">',
            f'<img src="{badge("Branch", branch, "2563eb")}" alt="Branch">',
            f'<img src="{badge("Student", "D202605002", "7c3aed")}" alt="Student">',
            '',
            '**All labs done — milestone reached!** 🎓',
            '',
            f'`{fmt_ts(ts)}` · [`{short}`]({commit_url}) · *{author}*',
            '',
            '</div>',
            '',
        ]
    else:
        body += [
            '<div align="center">',
            '',
            f'<img src="{badge("Branch", branch, "2563eb")}" alt="Branch">',
            f'<img src="{badge(fmt_ts(ts)[:10], fmt_ts(ts)[11:], "64748b")}" alt="Time">',
            f'<img src="{badge("Hash", short, "7c3aed")}" alt="Hash">',
            '',
            '</div>',
            '',
            f'### `{branch}` · [`{short}`]({commit_url})',
            '',
            f'**{title}**  ',
            f'<sub>by <b>{author}</b> · `{fmt_ts(ts)}` UTC+8 · [branch]({branch_url})</sub>',
            '',
        ]

    extra = '\n'.join(msg.splitlines()[1:]).strip()
    if extra:
        body += ['> ' + l for l in extra.splitlines()]
        body.append('')

    if diffstat:
        body += [
            '<details>',
            '<summary><b>📝 Changes</b></summary>',
            '',
            '```',
            diffstat.strip(),
            '```',
            '',
            '</details>',
            '',
        ]

    body.append('---')
    body.append('')
    body.append(f'<sub>Auto-synced from <a href="{commit_url}"><code>{branch}@{short}</code></a> · Student ID: <b>D202605002</b></sub>')
    return '\n'.join(body)


def diffstat(sha):
    try:
        r = subprocess.run(
            ['git', 'show', '--stat', '--format=', sha],
            capture_output=True, text=True, check=False,
        )
        return r.stdout
    except Exception:
        return ''


def main():
    branch = os.environ['BRANCH_NAME']
    repo_url = os.environ['REPO_URL']
    commits = json.loads(os.environ['COMMITS_JSON'])
    if not commits:
        Path(os.environ['GITHUB_OUTPUT']).open('a').write('changed=false\n')
        return

    text = README.read_text(encoding='utf-8') if README.exists() else '# BSV Learning Repo\n\n'
    head, top, bot = parse_log(text)
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
    new_text = refresh_code_badge(write_log(head, entries), entries)
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
