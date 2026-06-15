#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <batch_number>"
    echo "Example: $0 1"
    exit 1
fi

BATCH_NUM=$1
BATCH_DIR="/data/batch${BATCH_NUM}"

echo "Processing batch${BATCH_NUM}"

echo "Batch directory: ${BATCH_DIR}"

if ! compgen -G "${BATCH_DIR}/mzml/*.mzML" > /dev/null
then
    echo "No mzML files found"
    exit 1
fi

########################################
# Download database if missing
########################################

DB="${BATCH_DIR}/database/UP000005640_9606.fasta"

if [ ! -f "${DB}" ]; then

    echo "Downloading UniProt human proteome"

    wget \
    https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz \
    -O "${BATCH_DIR}/database/UP000005640_9606.fasta.gz"

    gunzip "${BATCH_DIR}/database/UP000005640_9606.fasta.gz"
fi

########################################
# Create Comet parameters
########################################

cd "${BATCH_DIR}/search"

echo "Creating Comet parameters"

comet -p

PARAMS="comet.params.new"

sed -i "s|^database_name =.*|database_name = ${DB}|" ${PARAMS}
sed -i "s|^decoy_search =.*|decoy_search = 1|" ${PARAMS}
sed -i "s|^isotope_error =.*|isotope_error = 3|" ${PARAMS}

sed -i "s|^peptide_mass_tolerance =.*|peptide_mass_tolerance = 20.0|" ${PARAMS}
sed -i "s|^peptide_mass_units =.*|peptide_mass_units = 2|" ${PARAMS}

sed -i "s|^fragment_bin_tol =.*|fragment_bin_tol = 1.0005|" ${PARAMS}
sed -i "s|^fragment_bin_offset =.*|fragment_bin_offset = 0.4|" ${PARAMS}

sed -i "s|^allowed_missed_cleavage =.*|allowed_missed_cleavage = 2|" ${PARAMS}

sed -i "s|^add_C_cysteine =.*|add_C_cysteine = 57.021464|" ${PARAMS}
sed -i "s|^add_K_lysine =.*|add_K_lysine = 229.162932|" ${PARAMS}
sed -i "s|^add_Nterm_peptide =.*|add_Nterm_peptide = 229.162932|" ${PARAMS}

sed -i 's/^variable_mod01.*/variable_mod01 = 15.994915 M 0 3 -1 0 0/' ${PARAMS}
sed -i 's/^variable_mod02.*/variable_mod02 = 0.984016 NQ 0 3 -1 0 0/' ${PARAMS}

########################################
# Run Comet
########################################

echo "Running Comet"

for file in "${BATCH_DIR}"/mzml/*.mzML
do

    echo "Processing $(basename "$file")"

    comet -P"${PARAMS}" "$file"

done

########################################
# Create Libra configuration
########################################

echo "Creating Libra configuration"

cat > libra_condition.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<libraSummary>
    <fragmentMasses tolerance="20" />
    <channel mz="126.127726" />
    <channel mz="127.124761" />
    <channel mz="127.131081" />
    <channel mz="128.128116" />
    <channel mz="128.134436" />
    <channel mz="129.131471" />
    <channel mz="129.137790" />
    <channel mz="130.134825" />
    <channel mz="130.141145" />
    <channel mz="131.138180" />
</libraSummary>
EOF

########################################
# PeptideProphet + Libra
########################################

echo "Running PeptideProphet + Libra"

xinteract \
-N"${BATCH_DIR}/results/interact.pep.xml" \
-OAP \
-l"${BATCH_DIR}/search/libra_condition.xml" \
"${BATCH_DIR}"/mzml/*.pep.xml

########################################
# ProteinProphet
########################################

echo "Running ProteinProphet"

ProteinProphet \
"${BATCH_DIR}/results/interact.pep.xml" \
"${BATCH_DIR}/results/interact.prot.xml"

########################################
# Export for R
########################################

echo "Exporting for R"

cd "${BATCH_DIR}/results"

input=$(ls *.mzid | head -n1)
output="interact.pep_Rcompatible.mzid"

sed '/<MzIdentML /{
s|http://psidev.info/psi/pi/mzIdentML/1\.2|http://psidev.info/psi/pi/mzIdentML/1.1|g
}' "$input" > "$output"

rm frontalcortex_*.mzid anteriorcingulategyrus_*.mzid 2>/dev/null || true

echo "Done"
