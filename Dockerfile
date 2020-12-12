
#    Copyright 2020 Darren Weber
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

ARG python_ver=3.7

# For more information about this base image, see
# https://hub.docker.com/r/lambci/lambda
FROM lambci/lambda:build-python${python_ver}

# This docker image will compile google s2geometry and the python library.
# https://github.com/google/s2geometry

RUN yum -y update \
    && yum -y groupinstall development \
    && yum install -y -q \
        ca-certificates \
        openssh-client \
        openssl-devel \
        gcc \
        gcc-c++ \
        git \
        make \
        swig \
        # Build dependencies often required by python packages
        tar \
        wget \
        curl \
        libcurl-devel \
        bzip2-devel \
        readline-devel \
        sqlite-devel \
        llvm \
        ncurses-devel \
        libffi-devel \
        xz \
        xz-devel \
        zlib-devel \
        zip

ENV CMAKE_VERSION=3.19
ENV CMAKE_BUILD=1
ENV CMAKE_SH=cmake-$CMAKE_VERSION.$CMAKE_BUILD-Linux-x86_64.sh
RUN wget -q https://cmake.org/files/v$CMAKE_VERSION/$CMAKE_SH && \
    mkdir /opt/cmake && \
    sh $CMAKE_SH --prefix=/opt/cmake --skip-license && \
    ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake && \
    cmake --version

# TODO: are these available?
RUN yum install -y -q \
    gtest-devel
#    libgflags-devel \
#    libgoogle-glog-devel \

ENV BUILDDIR /app
WORKDIR ${BUILDDIR}

# AWS lambda python installations are like:
#
# import sys
# data = {
#     "exe": sys.executable,
#     "exe_prefix": sys.exec_prefix,
#     "path": sys.path
# }
# from pprint import pprint
# pprint(data)
# {'exe': '/var/lang/bin/python3.6',
# 'exe_prefix': '/var/lang',
# 'path': ['/var/task',
#          '/opt/python/lib/python3.6/site-packages',
#          '/opt/python',
#          '/var/runtime',
#          '/var/runtime/awslambda',
#          '/var/lang/lib/python36.zip',
#          '/var/lang/lib/python3.6',
#          '/var/lang/lib/python3.6/lib-dynload',
#          '/var/lang/lib/python3.6/site-packages']}

RUN git clone https://github.com/google/s2geometry.git \
    && mkdir ${BUILDDIR}/s2geometry/build \
    && cd ${BUILDDIR}/s2geometry/build

WORKDIR ${BUILDDIR}/s2geometry/build

# match the AWS lambda environment for extra packages
ENV S2_PREFIX /opt/python

RUN cmake \
        -DCMAKE_INSTALL_PREFIX:PATH=${S2_PREFIX} \
        -DPYTHON_INCLUDE_DIR=${PY3_INC} \
        -DPYTHON_LIBRARY=${PY3_LIB} \
        -DPYTHON_EXECUTABLE:FILEPATH=${PY3_EXE} \
        .. \
    && make
RUN make install/strip/fast

# Copy the shared lib into a default LD_LIBRARY_PATH
RUN cp /opt/python/lib/libs2.so  /var/lang/lib/  && \
    python -c 'import pywraps2 as s2; print(s2)'

COPY archive_package.sh .
RUN ./archive_package.sh
