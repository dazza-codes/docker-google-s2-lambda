#!/usr/bin/env bash

python --version

PYTHON_VER=$(python --version | grep -o -E '[0-9]+[.][0-9]+')
PY_VER=$(echo "py${PYTHON_VER}" | sed -e 's/\.//g')

SITE_PATH=$(python3 -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')

## Match the AWS lambda environment
#LD_LIBRARY_PATH="${S2_PREFIX}/lib"
#PYTHONPATH="${S2_PREFIX}/lib/python${python_ver}/site-packages:${S2_PREFIX}"

python -c 'import pywraps2 as s2; print(s2)'

# /var/lang/lib/python${PYTHON_VER}/site-packages/pywraps2.py
# /var/lang/lib/python${PYTHON_VER}/site-packages/_pywraps2.so

zip_file="/tmp/${PY_VER}_google_s2.zip"
rm -f "${zip_file}"
zip -q -r9 --symlinks "${zip_file}" "${SITE_PATH}/pywraps2.py"
zip -q -r9 --symlinks "${zip_file}" "${SITE_PATH}/_pywraps2.so"
zip -q -r9 --symlinks "${zip_file}" /opt/python/lib/libs2.so
ls -al "${zip_file}"
unzip -q -t "${zip_file}"
echo "created ${zip_file}"
