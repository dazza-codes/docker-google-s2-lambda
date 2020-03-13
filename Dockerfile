
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

FROM amazonlinux

# This docker image will compile google s2geometry and the python library.
# https://github.com/google/s2geometry

RUN yum -y groupinstall development \
    && yum install -y \
        ca-certificates \
        openssh-client \
        openssl-devel \
        gcc \
        gcc-c++ \
        git \
        cmake3 \
        make \
        swig \
        # python build libs
        #python3-devel \
        #python3-wheel \
        #python3-pip \
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
        zlib-devel

ENV BUILDDIR /app
WORKDIR ${BUILDDIR}

# AWS lambda python 3.6 installations are like:
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

ENV PY_VER 3.6.10
ENV PY_PREFIX /var/lang
RUN wget https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tar.xz \
    && tar xJf Python-${PY_VER}.tar.xz \
    && rm Python-${PY_VER}.tar.xz \
    && cd Python-${PY_VER} \
    && mkdir -p ${PY_PREFIX} \
    && ./configure --prefix=${PY_PREFIX} \
    && make \
    && make install \
    && cd .. \
    && rm -rf Python-${PY_VER}

RUN git clone https://github.com/google/s2geometry.git \
    && mkdir ${BUILDDIR}/s2geometry/build \
    && cd ${BUILDDIR}/s2geometry/build

WORKDIR ${BUILDDIR}/s2geometry/build

# TODO: are these available?
RUN yum install -y -q \
    gtest-devel
#    libgflags-devel \
#    libgoogle-glog-devel \

ENV PY3_EXE ${PY_PREFIX}/bin/python3.6
ENV PY3_LIB ${PY_PREFIX}/lib/python3.6
ENV PY3_INC ${PY_PREFIX}/include/python3.6m

# match the AWS lambda environment for extra packages
ENV S2_PREFIX /opt/python

RUN cmake3 \
        -DCMAKE_INSTALL_PREFIX:PATH=${S2_PREFIX} \
        -DPYTHON_INCLUDE_DIR=${PY3_INC} \
        -DPYTHON_LIBRARY=${PY3_LIB} \
        -DPYTHON_EXECUTABLE:FILEPATH=${PY3_EXE} .. \
    && make \
    && make install

# Match the AWS lambda environment
ENV LD_LIBRARY_PATH "${S2_PREFIX}/lib"
ENV PYTHONPATH "${S2_PREFIX}/lib/python3.6/site-packages:${S2_PREFIX}"

# Or add the paths like so:
#>>> import sys
#>>> sys.path.append('/opt/python/lib/python3.6/site-packages')
#>>> sys.path.append('/opt/python')
#>>> import pywraps2 as s2
RUN ${PY3_EXE} -c 'import pywraps2 as s2'

# TODO: might also need to bundle up what libs2.so is linked to
#       ldd /opt/python/lib/libs2.so

RUN yum install -y -q zip \
    && zip_file="/tmp/py36_google_s2.zip" \
    && rm -f "${zip_file}" \
    && zip -q -r9 --symlinks "${zip_file}" /opt/python \
    && unzip -q -t "${zip_file}" \
    && echo "created ${zip_file}"
