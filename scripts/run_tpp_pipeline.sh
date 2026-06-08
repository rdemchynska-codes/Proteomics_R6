#!/bin/bash

set -e

echo "================================="
echo "Configuring Comet"
echo "================================="

cd /data/search

comet -p

sed -i "s|^database_name =.*|database_name = /data/database/UP000005640_9606.fasta|" comet.params.new
sed -i "s|^decoy_search =.*|decoy_search = 1|" comet.params.new

sed -i "s|^peptide_mass_tolerance =.*|peptide_mass_tolerance = 20.0|" comet.params.new
sed -i "s|^peptide_mass_units =.*|peptide_mass_units = 2|" comet.params.new
sed -i "s|^fragment_bin_tol =.*|fragment_bin_tol = 1.0005|" comet.params.new
sed -i "s|^fragment_bin_offset =.*|fragment_bin_offset = 0.4|" comet.params.new
sed -i "s|^allowed_missed_cleavage =.*|allowed_missed_cleavage = 2|" comet.params.new

sed -i "s|^add_C_cysteine =.*|add_C_cysteine = 57.021464|" comet.params.new
sed -i "s|^add_K_lysine =.*|add_K_lysine = 229.162932|" comet.params.new
sed -i "s|^add_Nterm_peptide =.*|add_Nterm_peptide = 229.162932|" comet.params.new

sed -i 's/^variable_mod01.*/variable_mod01 = 15.994915 M 0 3 -1 0 0/' comet.params.new
sed -i 's/^variable_mod02.*/variable_mod02 = 0.984016 NQ 0 3 -1 0 0/' comet.params.new

echo "================================="
echo "Running Comet"
echo "================================="

for file in /data/mzml/*.mzML
do
    echo "Processing $file"
    comet -Pcomet.params.new "$file"
done

echo "================================="
echo "Running PeptideProphet"
echo "================================="

xinteract \
-N/data/results/interact.pep.xml \
/data/mzml/*.pep.xml

echo "================================="
echo "Running ProteinProphet"
echo "================================="

ProteinProphet \
/data/results/interact.pep.xml \
/data/results/interact.prot.xml

echo "================================="
echo "Exporting for R"
echo "================================="

cd /data/results

idconvert interact.pep.xml

mv *.mzid interact.pep.mzid

input="interact.pep.mzid"
output="interact.pep_Rcompatible.mzid"

sed '/<MzIdentML /{
s|http://psidev.info/psi/pi/mzIdentML/1\.2|http://psidev.info/psi/pi/mzIdentML/1.1|g
}' "$input" > "$output"

echo "Pipeline completed successfully."
