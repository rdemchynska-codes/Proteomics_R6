#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <batch_number>"
    echo "Example: $0 1"
    exit 1
fi

BATCH_NUM=$1
BATCH_DIR="/data/batch${BATCH_NUM}"

PARAMS="/data/config/comet.params"

echo "Processing batch${BATCH_NUM}"

echo "Batch directory: ${BATCH_DIR}"

echo "Using Comet parameters: ${PARAMS}"

echo "Running Comet"

for file in "${BATCH_DIR}"/mzml/*.mzML
do
    echo "Processing $(basename "$file")"

    comet -P"${PARAMS}" "$file"
done

echo "Running PeptideProphet"


xinteract \
-N"${BATCH_DIR}/results/interact.pep.xml" \
"${BATCH_DIR}"/mzml/*.pep.xml

echo "Running ProteinProphet"
ProteinProphet \
"${BATCH_DIR}/results/interact.pep.xml" \
"${BATCH_DIR}/results/interact.prot.xml"

echo "Exporting for R"

cd "${BATCH_DIR}/results"

idconvert interact.pep.xml

mv *.mzid interact.pep.mzid

input="interact.pep.mzid"
output="interact.pep_Rcompatible.mzid"

sed '/<MzIdentML /{
s|http://psidev.info/psi/pi/mzIdentML/1\.2|http://psidev.info/psi/pi/mzIdentML/1.1|g
}' "$input" > "$output"

echo "Pipeline completed successfully"
