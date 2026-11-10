import json
import os
from pathlib import Path
import subprocess
import time
import urllib.request


def stats():
    try:
        with urllib.request.urlopen('http://127.0.0.1:6871/_runs-on/apt-cache/stats', timeout=5) as response:
            return json.load(response)
    except Exception as error:
        return {'unavailable': type(error).__name__}


def timed(name, command):
    started = time.monotonic()
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    seconds = time.monotonic() - started
    (output / (name + '.log')).write_text(result.stdout)
    print(json.dumps({'phase': name, 'seconds': round(seconds, 3), 'exit': result.returncode}), flush=True)
    print('\n'.join(result.stdout.splitlines()[-8:]), flush=True)
    result.check_returncode()
    return {'seconds': round(seconds, 3), 'exit': result.returncode}


workload = os.environ['WORKLOAD']
mode = os.environ['MODE']
packages = {
    'cross': ['gcc-aarch64-linux-gnu', 'g++-aarch64-linux-gnu'],
    'desktop': ['clang', 'cmake', 'ninja-build', 'pkg-config', 'libgtk-3-dev', 'lld', 'llvm'],
}[workload]
output = Path('benchmark-results')
output.mkdir(exist_ok=True)
before_packages = subprocess.run(['dpkg-query', '-W', '-f=${Package}\t${Version}\t${Status}\n', *packages], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
(output / 'packages-before.txt').write_text(before_packages.stdout)
before = stats()
print(json.dumps({'mode': mode, 'workload': workload, 'statsBefore': before}), flush=True)
options = ['-o', 'Acquire::Retries=3', '-o', 'Acquire::http::Timeout=30']
update = timed('apt-update', ['sudo', 'apt-get', *options, 'update', '-qq'])
after_update = stats()
install = timed('apt-install', ['sudo', 'apt-get', *options, 'install', '-y', '--no-install-recommends', *packages])
after_install = stats()
versions = subprocess.check_output(['dpkg-query', '-W', '-f=${Package}\t${Version}\n', *packages], text=True)
(output / 'packages-after.txt').write_text(versions)
compile_result = None
if workload == 'cross':
    (output / 'probe.cpp').write_text('#include <vector>\nint f() { return std::vector<int>{1, 2}.size(); }\n')
    compile_result = timed('cross-compile', ['aarch64-linux-gnu-g++', '-c', str(output / 'probe.cpp'), '-o', str(output / 'probe.o')])
    identification = subprocess.check_output(['file', str(output / 'probe.o')], text=True)
    assert 'ARM aarch64' in identification, identification
    (output / 'object-type.txt').write_text(identification)
sources = subprocess.check_output(['bash', '-c', 'cat /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true'], text=True)
(output / 'apt-sources.txt').write_text(sources)
configuration = subprocess.check_output(['apt-config', 'dump'], text=True)
(output / 'apt-config.txt').write_text(configuration)
result = {'workload': workload, 'mode': mode, 'packages': packages, 'update': update, 'install': install, 'compile': compile_result, 'statsBefore': before, 'statsAfterUpdate': after_update, 'statsAfterInstall': after_install, 'runId': os.environ['GITHUB_RUN_ID'], 'job': os.environ['GITHUB_JOB'], 'runner': os.environ['RUNNER_NAME']}
(output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
print('APT_BENCHMARK_RESULT=' + json.dumps(result), flush=True)
