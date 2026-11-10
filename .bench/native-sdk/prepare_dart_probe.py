import hashlib
import json
import os
from pathlib import Path
import re

root = Path.cwd()
fixture = Path(os.environ['RUNNER_TEMP']) / 'native-sdk-loader-fixture'
fixture.mkdir(parents=True, exist_ok=True)
lock = (root / 'pubspec.lock').read_text()
versions = {}
for name in ['archive', 'hooks', 'http', 'path']:
    block = re.search(r'^  ' + name + r':\n((?: {4}.*\n)+)', lock, re.M)[1]
    versions[name] = re.search(r'    version: "([^"]+)"', block)[1]
spec = 'name: native_sdk_loader_probe\nenvironment:\n  sdk: ^3.11.0\ndependencies:\n'
spec += ''.join('  ' + key + ': "' + value + '"\n' for key, value in versions.items())
(fixture / 'pubspec.yaml').write_text(spec)
loader = root / 'packages/cbl/src/install/download.dart'
hook = root / 'packages/cbl/hook/build.dart'
source = (root / '.bench/native-sdk/loader_probe.dart').read_text().replace('SOURCE_URI', loader.as_uri())
(fixture / 'main.dart').write_text(source)
hook_text = hook.read_text()
metadata = {
    'LOADER_SHA256': hashlib.sha256(loader.read_bytes()).hexdigest(),
    'HOOK_SHA256': hashlib.sha256(hook.read_bytes()).hexdigest(),
    'CBL_RELEASE': re.search(r"_cbliteRelease = '([^']+)'", hook_text)[1],
    'VS_RELEASE': re.search(r"_vectorSearchRelease = '([^']+)'", hook_text)[1],
    'ARCHIVE_VERSION': versions['archive'],
    'FIXTURE': str(fixture),
    'SDK_CACHE_ROOT': str(root / '.native-dart-sdk-cache' / os.environ['BENCH_TARGET']),
    'RESULT_PATH': str(root / 'dart-loader-result.json'),
}
with open(os.environ['GITHUB_ENV'], 'a') as output:
    for key, value in metadata.items():
        output.write(f'{key}={value}\n')
key_material = {
    'loader': metadata['LOADER_SHA256'], 'hook': metadata['HOOK_SHA256'],
    'versions': versions, 'target': os.environ['BENCH_TARGET'],
    'edition': 'enterprise', 'vector_search': True,
    'cache': 'extracted-tree', 'epoch': os.environ['BENCH_EPOCH'],
}
digest = hashlib.sha256(json.dumps(key_material, sort_keys=True).encode()).hexdigest()
with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
    output.write(f"key=bench-real-native-sdk-{digest}\npath={metadata['SDK_CACHE_ROOT']}\n")
print(json.dumps(key_material, indent=2))
