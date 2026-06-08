#!/bin/bash

set -e

mkdir -p \
~/projects/PXD007160/batch1/{raw,mzml,search,results,database}

cd ~/projects/PXD007160/batch1/raw

batch="frontalcortex_batch1"
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

