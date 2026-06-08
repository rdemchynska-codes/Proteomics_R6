Protein Identification Using TPP + Comet

Open WSL and enter your project directory:
cd ~/projects/PXD007160/batch1

Launch the TPP docker:
docker run -it --rm -u 0 -v ~/projects/PXD007160/batch1:/data biocontainers/tpp:v5.2_cv1 bash

Verifying files 
cd /data/search
ls /data/mzml/*.mzML

Download Human Protein Database
Move to the database directory:
cd /data/database
Download the UniProt Human Proteome:
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz
Uncompress:
gunzip UP000005640_9606.fasta.gz
Verify:
ls -lh UP000005640_9606.fasta

Create Default Comet Parameters

cd /data/search
comet -p
Check comet.params.new contents. Navigate with up/down arrows. To exit press Ctrl+C.
less comet.params.new

Set database path and mode inside comet.params.new file.

Database
sed -i "s|^database_name =.*|database_name = /data/database/UP000005640_9606.fasta|" comet.params.new
sed -i "s|^decoy_search =.*|decoy_search = 1|" comet.params.new

Comet parametrs
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

Search All Fractions Automatically
for file in /data/mzml/*.mzML; do comet -Pcomet.params.new "$file"; done
This will process all 21 fractions assigned to the batch.

Run identification
xinteract -N/data/results/interact.pep.xml /data/mzml/*.pep.xml
ProteinProphet /data/results/interact.pep.xml /data/results/interact.prot.xml

Make TPP output readable by R
Inside the docker
Convert to mzIdentML and read file with mzID library in R.
cd /data/results
idconvert interact.pep.xml
mv *.mzid interact.pep.mzid
input="interact.pep.mzid"
output="interact.pep_Rcompatible.mzid"
sed '/<MzIdentML /{s|http://psidev.info/psi/pi/mzIdentML/1\.2|http://psidev.info/psi/pi/mzIdentML/1.1|g}' "$input" > "$output"


