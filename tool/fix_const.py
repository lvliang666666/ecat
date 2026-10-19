# 一次性工具：按 flutter analyze 文本输出修复深色模式 const 级联
# 用法：python tool/fix_const.py
# 报错行本身往往没有 const（const 在祖先构造上），所以从报错行向上
# 查找最近的含 const 的行并移除其 const 关键字。
import os
import re
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PATTERN = re.compile(
    r'^\s*(?:error|warning)\s*-\s*.*?-\s*(lib[^:]+(?:\\[^:]+)*):(\d+):\d+\s*-\s*(\w+)\s*$'
)
CODES = {'invalid_constant', 'non_constant_list_element',
         'non_constant_default_value'}

CONST_RE = re.compile(r'\bconst\s+(?=[A-Za-z_(\[])')


def remove_const(text: str) -> str:
    """移除一行里第一个 const 关键字（const X / const( / const [）"""
    return CONST_RE.sub('', text, count=1)


def main():
    env = {**os.environ,
           'PUB_HOSTED_URL': 'https://pub.flutter-io.cn',
           'FLUTTER_STORAGE_BASE_URL': 'https://storage.flutter-io.cn',
           'PATH': r'D:\flutter\bin;' + os.environ.get('PATH', '')}
    proc = subprocess.run(
        ['flutter', 'analyze'],
        capture_output=True, text=True, cwd=ROOT, env=env, shell=True,
    )
    fixes = defaultdict(set)
    for line in proc.stdout.splitlines():
        m = PATTERN.match(line)
        if not m:
            continue
        path, ln, code = m.group(1), int(m.group(2)), m.group(3)
        if code not in CODES:
            continue
        fixes[str(ROOT / path)].add(ln)

    total = 0
    for file, lines in sorted(fixes.items()):
        p = Path(file)
        if not p.exists():
            continue
        src = p.read_text(encoding='utf-8').splitlines(keepends=True)
        changed = False
        for ln in sorted(set(lines)):
            i = ln - 1
            if i >= len(src):
                continue
            # 从报错行向上找最近的含 const 的行
            j = i
            while j >= 0 and not CONST_RE.search(src[j]):
                j -= 1
            if j < 0:
                continue
            src[j] = remove_const(src[j])
            total += 1
            changed = True
        if changed:
            p.write_text(''.join(src), encoding='utf-8')
    print(f'fixed {total} const sites across {len(fixes)} files')


if __name__ == '__main__':
    main()
