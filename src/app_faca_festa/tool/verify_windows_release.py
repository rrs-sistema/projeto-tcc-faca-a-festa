"""Offline artifact verification. Does not execute the app or installer."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'release/desktop-feed/desktop/updates/latest.json').read_text(encoding='utf-8'))
version = manifest['version']
build = manifest['build']
package = root / f'release/desktop-feed/desktop/packages/FacaFesta_{version}+{build}.exe'
assert package.stat().st_size == manifest['size']
with package.open('rb') as stream:
    assert hashlib.file_digest(stream, 'sha256').hexdigest() == manifest['sha256']
public = re.search(r'"([A-Za-z0-9+/]{43}=)"', (root / 'windows/runner/updater_public_key.h').read_text(encoding='utf-8-sig')).group(1)
tool = root / '.dart_tool/winsparkle-0.9.4/WinSparkle-0.9.4/bin/winsparkle-tool.exe'
subprocess.run([str(tool),'verify','--public-key',public,'--signature',manifest['signature'],str(package)],check=True,capture_output=True)
bundle = root / 'build/windows/x64/runner/Release'
required = ['app_faca_festa.exe','faca_festa_update_helper.exe','WinSparkle.dll','flutter_windows.dll',
            'sqlite3.dll','data/app.so','data/icudtl.dat','data/WinSparkle-LICENSE.txt']
assert all((bundle / name).is_file() for name in required)
assert (bundle / 'data/flutter_assets').is_dir()
assert public.encode() in (bundle / 'app_faca_festa.exe').read_bytes()
assert b'https://faca-a-festa.web.app/desktop/updates/appcast.xml' in (bundle / 'app_faca_festa.exe').read_bytes()
for target in [bundle/'app_faca_festa.exe',package]:
    stamp = subprocess.check_output(['powershell.exe','-NoProfile','-Command',
      '$v=(Get-Item -LiteralPath $env:FACA_FESTA_VERIFY_FILE).VersionInfo; "$($v.FileMajorPart).$($v.FileMinorPart).$($v.FileBuildPart).$($v.FilePrivatePart)"'],
      env={**os.environ,'FACA_FESTA_VERIFY_FILE':str(target)},text=True).strip()
    assert stamp == f'{version}.{build}', (target,stamp)
print(json.dumps({'verified':True,'version':version,'build':build,'size':manifest['size'],
                  'sha256':manifest['sha256'],'signature':'Ed25519 valid','bundleFiles':required}))
