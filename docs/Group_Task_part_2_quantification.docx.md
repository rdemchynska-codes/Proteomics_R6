**Protein Identification Using TPP \+ Comet+Libra**

Open WSL and enter your project directory:

```shell
cd ~/projects/PXD007160
```

Launch the TPP docker:

```shell
docker run -it --rm -u 0 -v ~/projects/PXD007160:/data biocontainers/tpp:v5.2_cv1 bash
```

**Verifying files** 

```shell
cd /data/batch1/search
ls /data/mzml/*.mzML
```

---

**Download Human Protein Database**

Move to the database directory and Download the UniProt Human Proteome:

```shell
cd /data/database
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz
```

Uncompress:

```shell
gunzip UP000005640_9606.fasta.gz
```

Verify:

```shell
ls -lh UP000005640_9606.fasta
```

---

**Create Default Comet Parameters**

```shell
cd /data/batch1/search
comet -p
```

Check comet.params.new contents. Navigate with up/down arrows. To exit press Ctrl+C.

---

**Set database path and mode inside comet.params.new file.**

```shell
sed -i "s|^database_name =.*|database_name = data/database/UP000005640_9606.fasta|" comet.params.new
sed -i "s|^decoy_search =.*|decoy_search = 1|" comet.params.new
sed -i "s|^isotope_error =.*|isotope_error = 3|" comet.params.new 
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


```

---

**Search All Fractions Automatically**

```shell
for file in /data/batch1/mzml/*.mzML; do comet -Pcomet.params.new "$file"; done
```

Prepare for TMT Quantification

Create the required libra\_condition.xml file:

```shell
cat <<EOF > batch1/search/libra_condition.xml
<?xml version="1.0" encoding="UTF-8"?>
<SUMmOnCondition description="TMT-10plex-AD-PD-Brain-Tissue">
  <fragmentMasses>
    <reagent mz="126.1277"/>
    <reagent mz="127.1248"/>
    <reagent mz="127.1311"/>
    <reagent mz="128.1281"/>
    <reagent mz="128.1344"/>
    <reagent mz="129.1315"/>
    <reagent mz="129.1378"/>
    <reagent mz="130.1348"/>
    <reagent mz="130.1411"/>
    <reagent mz="131.1382"/>
  </fragmentMasses>
  <massTolerance value="0.001"/>
  <centroiding type="2" iterations="1"/>
  <normalization type="1"/>
  <targetMs level="3"/>
  <reporterFromMS3 value="1"/>
  <output type="1"/>
  <quantitationFile name="quantitation.tsv"/>
  <minimumThreshhold value="0"/>
</SUMmOnCondition>
EOF

```

```shell
xinteract \
-N batch1/results/interact.pep.xml\
-L batch1/search/libra_condition.xml \
-Op \
batch1/mzml/*.pep.xml

```

```shell
ProteinProphet /data/batch1/results/interact.pep.xml /data/batch1/results/interact.prot.xml

```

