#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <batch_number>"
    echo "Example: $0 1"
    exit 1
fi

BATCH_NUM=$1

PROJECT_ROOT=~/projects/PXD007160
BATCH_DIR="${PROJECT_ROOT}/batch${BATCH_NUM}"

mkdir -p \
"${BATCH_DIR}"/{raw,mzml,search,results,database}

cd "${BATCH_DIR}/raw"

batch="frontalcortex_batch${BATCH_NUM}"
base="https://ftp.pride.ebi.ac.uk/pride/data/archive/2018/02/PXD007160"

for i in $(seq -w 1 21)
do
    filename="${batch}_fraction${i}.raw"

    echo "Downloading $filename"

    wget -c "$base/$filename"
done

echo "Download complete"

echo "RAW file count:"
ls *.raw | wc -l
