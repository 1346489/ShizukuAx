#!/usr/bin/env python3
# CI 前置校验：不依赖 Android SDK，尽早失败
import os, re, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
errs = []

def read(p):
    return open(os.path.join(ROOT, p), encoding='utf-8', errors='ignore').read()

def walk(ext):
    for d, _, fs in os.walk(ROOT):
        for f in fs:
            if f.endswith(ext):
                yield os.path.join(d, f)

# Kotlin 花括号平衡
for f in walk('.kt'):
    src = re.sub(r'//.*', '', open(f, encoding='utf-8').read())
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    src = re.sub(r'\$\{[^}]*\}', '@@', src)
    if src.count('{') != src.count('}'):
        errs.append(f'{os.path.relpath(f,ROOT)}: 花括号不平衡')

# Bridge 方法完整性
js = ''.join(open(p, encoding='utf-8').read() for p in walk('.js'))
html = ''.join(open(p, encoding='utf-8').read() for p in walk('.html'))
bridge = read('app/src/main/java/me/x/shizukuax/AppBridge.kt')
main = read('app/src/main/java/me/x/shizukuax/MainActivity.kt')
for m in set(re.findall(r'AxNative\.(\w+)\(', js + html)):
    if f'fun {m}(' not in bridge and f'fun {m}(' not in main:
        errs.append(f'AxNative.{m} 无对应 fun')

# 关键文件
for must in ['assets/web/index.html','assets/web/detail.html','assets/web/style.css','assets/web/app.js',
             'java/me/x/shizukuax/ProtectedPackages.kt','java/me/x/shizukuax/Backend.kt',
             'java/me/x/shizukuax/RootBackend.kt','java/me/x/shizukuax/PmFacade.kt',
             'java/me/x/shizukuax/ShizukuGate.kt','java/me/x/shizukuax/IPackageManagerCompat.kt',
             'java/me/x/shizukuax/ProfileStore.kt','java/me/x/shizukuax/AppInfo.kt']:
    if not os.path.exists(os.path.join(ROOT, 'app/src/main', must)):
        errs.append(f'缺失: {must}')

# 白名单含自身
pp = read('app/src/main/java/me/x/shizukuax/ProtectedPackages.kt')
if 'me.x.shizukuax' not in pp:
    errs.append('白名单未包含自身包名')

if errs:
    print('CI VERIFY FAILED:', file=sys.stderr)
    for e in errs: print(' -', e, file=sys.stderr)
    sys.exit(1)
print('CI VERIFY OK')
