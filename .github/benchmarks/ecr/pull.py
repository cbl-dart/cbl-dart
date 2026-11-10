import json
import os
from pathlib import Path
import subprocess
import time
import urllib.request

output = Path('.benchmark-ecr')
output.mkdir(exist_ok=True)
image = os.environ['BENCH_IMAGE']
backend = os.environ['BENCH_BACKEND']
registry = '020676528030.dkr.ecr.eu-central-1.amazonaws.com'
reference = image if backend == 'direct' else f"{registry}/{os.environ['BENCH_ECR_PREFIX']}/{image}"
before = subprocess.run(['docker', 'image', 'inspect', reference], capture_output=True).returncode == 0
metadata = {}
try:
    request = urllib.request.Request('http://169.254.169.254/latest/api/token', method='PUT', headers={'X-aws-ec2-metadata-token-ttl-seconds': '60'})
    with urllib.request.urlopen(request, timeout=2) as response:
        token = response.read().decode()
    for key in ['instance-id', 'instance-type', 'ami-id', 'placement/availability-zone']:
        request = urllib.request.Request('http://169.254.169.254/latest/meta-data/' + key, headers={'X-aws-ec2-metadata-token': token})
        with urllib.request.urlopen(request, timeout=2) as response:
            metadata[key] = response.read().decode()
except Exception as error:
    metadata['unavailable'] = type(error).__name__
if before:
    raise RuntimeError('Image was already present on this runner; this is not a fresh-daemon sample')
started = time.perf_counter()
with (output / 'pull.log').open('w') as log:
    result = subprocess.run(['docker', 'pull', '--platform', 'linux/amd64', reference], stdout=log, stderr=subprocess.STDOUT)
seconds = time.perf_counter() - started
record = {
    'backend': backend, 'sample': os.environ['BENCH_SAMPLE'], 'label': os.environ['BENCH_LABEL'],
    'sourceImage': image, 'pulledReference': reference, 'platform': 'linux/amd64',
    'runner': metadata, 'localImageBefore': before, 'pullSeconds': seconds, 'returncode': result.returncode,
}
if result.returncode == 0:
    info = json.loads(subprocess.check_output(['docker', 'image', 'inspect', reference]))[0]
    record.update(imageId=info['Id'], repoDigests=info.get('RepoDigests', []), uncompressedBytes=info['Size'], rootFSLayers=info['RootFS']['Layers'])
(output / 'result.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record, indent=2))
raise SystemExit(result.returncode)
