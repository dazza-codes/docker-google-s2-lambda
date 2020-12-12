
# Docker build for google S2

The `Dockerfile` is designed to build and install google S2 geometry into an
AWS Lambda runtime, using the same path prefixes used in AWS lambda.

The docker image built is not intended to be published or used directly. The
purpose of the build is to extract an AWS lambda layer as a packaged .zip
archive.

See also:

- https://github.com/google/s2geometry
- https://github.com/beyoung/s2geometry_docker

# Getting Started

This assumes that `git`, `docker` and `make` are installed and functioning as
expected.  A python version is detected in the current runtime - create a
virtual env with a required python version to build against that version
if a lambci docker image is available for it - the following assumes
python 3.6 is used.

```shell script
git clone https://github.com/dazza-codes/docker-google-s2-lambda.git
cd docker-google-s2-lambda
make build
make extract
unzip -t py36_google_s2.zip
```

The `py36_google_s2.zip` archive should work as an AWS lambda layer.
The docker build uses AWS lambda installation paths for python and
the extra package for s2geometry, i.e.

```text
opt/python/lib/libs2.so
opt/python/lib/python3.6/site-packages/pywraps2.py
opt/python/lib/python3.6/site-packages/_pywraps2.so
```

The initial test that it works is simply to import it.

# LICENSE

```text

   Copyright 2020 Darren Weber

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```
