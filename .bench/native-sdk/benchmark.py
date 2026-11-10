#!/usr/bin/env python3
"""Download/extract only: the exact release URLs/layout used by cbl's hook."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.request
import zipfile

ROOT = Path.cwd()
TARGET = os.environ['BENCH_TARGET']
MODE = os.environ['BENCH_MODE']
PHASE = os.environ.get('BENCH_PHASE', 'cold')
CACHE = ROOT / '.native-sdk-cache' / MODE / TARGET
WORK = ROOT / '.native-sdk-work' / MODE / TARGET
HOOK = (ROOT / 'packages/cbl/hook/build.dart').read_text()
CBL = re.search(r"_cbliteRelease = '([^']+)'", HOOK)[1]
VS = re.search(r"_vectorSearchRelease = '([^']+)'", HOOK)[1]
OS, ARCH = TARGET.split('-')
PLATFORM = 'linux-x86_64' if OS == 'linux' else 'android'
FORMAT = 'tar.gz' if OS == 'linux' else 'zip'
FILES = [
    {'library': 'cblite', 'release': CBL, 'edition': 'enterprise',
     'features': ['database'], 'os': OS, 'consumer_arch': ARCH,
     'archive_target': PLATFORM, 'format': FORMAT,
     'url': f'https://packages.couchbase.com/releases/couchbase-lite-c/{CBL}/couchbase-lite-c-enterprise-{CBL}-{PLATFORM}.{FORMAT}',
     'shared_dir': f'cblite-enterprise-{OS}-{ARCH}-{CBL}'},
    {'library': 'vectorSearch', 'release': VS, 'edition': 'enterprise',
     'features': ['vector_search'], 'os': OS, 'consumer_arch': ARCH,
     'archive_target': f'{OS}-x86_64', 'format': 'zip',
     'url': f'https://packages.couchbase.com/releases/couchbase-lite-vector-search/{VS}/couchbase-lite-vector-search-{VS}-{OS}-x86_64.zip',
     'shared_dir': f'vector-search-{OS}-{ARCH}-{VS}'},
]
MANIFEST = {'schema': 1, 'artifacts': FILES}
MANIFEST_HASH = hashlib.sha256(json.dumps(MANIFEST, sort_keys=True).encode()).hexdigest()


def digest_file(path):
    h = hashlib.sha256()
    with path.open('rb') as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def tree_digest(path):
    h = hashlib.sha256()
    size = 0
    count = 0
    for file in sorted(path.rglob('*')):
        if file.is_symlink():
            h.update((str(file.relative_to(path)) + '\0' + os.readlink(file)).encode())
        elif file.is_file() and file.name != 'payload-manifest.json':
            h.update((str(file.relative_to(path)) + '\0' + digest_file(file)).encode())
            size += file.stat().st_size
            count += 1
    return {'sha256': h.hexdigest(), 'bytes': size, 'files': count}


def extract(archive, destination, kind):
    destination.mkdir(parents=True, exist_ok=True)
    if kind == 'tar.gz':
        with tarfile.open(archive) as tar:
            assert all(not Path(x.name).is_absolute() and '..' not in Path(x.name).parts for x in tar.getmembers())
        subprocess.run(['tar', '-xzf', str(archive), '-C', str(destination)], check=True)
    else:
        with zipfile.ZipFile(archive) as z:
            assert all(not Path(x.filename).is_absolute() and '..' not in Path(x.filename).parts for x in z.infolist())
        subprocess.run(['unzip', '-q', str(archive), '-d', str(destination)], check=True)


if sys.argv[1] == 'prepare':
    CACHE.mkdir(parents=True, exist_ok=True)
    key = f"bench-native-sdk-{os.environ['BENCH_EPOCH']}-{MODE}-{TARGET}-{MANIFEST_HASH}"
    with open(os.environ['GITHUB_OUTPUT'], 'a') as out:
        out.write(f'key={key}\npath={CACHE}\n')
    print(json.dumps(MANIFEST, indent=2))
    sys.exit(0)

start = time.perf_counter()
hit = os.environ.get('CACHE_HIT') == 'true'
assert hit == (PHASE == 'warm'), f'Expected {PHASE} cache state, got cache-hit={hit}'
download_s = 0.0
extract_s = 0.0
verify_s = 0.0
records = []
payload_file = CACHE / 'payload-manifest.json'
existing = json.loads(payload_file.read_text()) if hit else None
if existing:
    assert existing['manifest'] == MANIFEST

for index, item in enumerate(FILES):
    archive_name = item['url'].rsplit('/', 1)[1]
    package_name = Path(archive_name).stem  # Matches basenameWithoutExtension, including .tar.
    target_root = CACHE if MODE == 'tree' else WORK
    package_dir = target_root / item['shared_dir'] / package_name
    archive = (CACHE / 'archives' if MODE == 'archive' else WORK / 'archives') / archive_name
    record = {'url': item['url'], 'shared_dir': item['shared_dir'], 'package_dir': str(package_dir.relative_to(ROOT))}
    if not hit:
        archive.parent.mkdir(parents=True, exist_ok=True)
        tick = time.perf_counter()
        with urllib.request.urlopen(item['url'], timeout=120) as response, archive.open('wb') as file:
            shutil.copyfileobj(response, file)
        download_s += time.perf_counter() - tick
        record['archive_bytes'] = archive.stat().st_size
        record['archive_sha256'] = digest_file(archive)
    else:
        record.update({key: existing['artifacts'][index][key] for key in ['archive_bytes', 'archive_sha256']})
    if MODE == 'archive' or not hit:
        tick = time.perf_counter()
        assert digest_file(archive) == record['archive_sha256']
        verify_s += time.perf_counter() - tick
        tick = time.perf_counter()
        extract(archive, package_dir, item['format'])
        extract_s += time.perf_counter() - tick
    tick = time.perf_counter()
    tree = tree_digest(package_dir)
    if existing:
        assert tree == existing['artifacts'][index]['tree'], (tree, existing['artifacts'][index]['tree'])
    record['tree'] = tree
    # Verify the requested target's actual shared library has the x86-64 ELF machine.
    if item['library'] == 'cblite':
        triple = 'x86_64-linux-gnu' if OS == 'linux' else 'x86_64-linux-android'
        library = package_dir / f'libcblite-{CBL}' / 'lib' / triple / 'libcblite.so'
        assert (package_dir / f'libcblite-{CBL}' / 'include/cbl/CouchbaseLite.h').is_file()
    else:
        library = package_dir / 'lib' / ('CouchbaseLiteVectorSearch.so' if OS == 'linux' else 'libCouchbaseLiteVectorSearch.so')
    elf = library.read_bytes()[:20]
    assert elf[:4] == b'\x7fELF' and int.from_bytes(elf[18:20], 'little') == 62, str(library)
    verify_s += time.perf_counter() - tick
    records.append(record)

if not hit:
    payload_file.write_text(json.dumps({'manifest': MANIFEST, 'artifacts': records}, indent=2))
result = {'target': TARGET, 'mode': MODE, 'phase': PHASE, 'cache_hit': hit,
          'manifest_hash': MANIFEST_HASH, 'download_seconds': download_s,
          'extract_seconds': extract_s, 'verify_seconds': verify_s,
          'workload_seconds': time.perf_counter() - start,
          'archive_bytes': sum(x['archive_bytes'] for x in records),
          'sdk_tree_bytes': sum(x['tree']['bytes'] for x in records),
          'cache_payload_bytes': sum(x.stat().st_size for x in CACHE.rglob('*') if x.is_file() and not x.is_symlink()),
          'artifacts': records}
Path('benchmark-result.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
