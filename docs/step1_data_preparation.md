PXD007160 Reanalysis Protocol. Step 1
1. Initial Setup
Create Project Directory in WSL
Create the project structure inside your Linux home directory.

Example for Batch 1: (change /batch{n}/ according to your batch)
mkdir -p ~/projects/PXD007160/batch1/{raw,mzml,search,results,database}
Expected structure:
batch4/
├── raw/
├── mzml/
├── search/
├── results/
└── database/

Verify: (change /batch{n}/ according to your batch)
ls -R ~/projects/PXD007160/batch1

2. Download RAW Files for Your Assigned Batch Only
The RAW files are available from PRIDE:
https://www.ebi.ac.uk/pride/archive/projects/PXD007160
Each teammate should download only the 21 RAW files belonging to their assigned batch.
Examples:
Assigned Batch
RAW File Pattern
anteriorcingulategyrus_batch1
anteriorcingulategyrus_batch1_fraction*.raw
anteriorcingulategyrus_batch2
anteriorcingulategyrus_batch2_fraction*.raw
anteriorcingulategyrus_batch3
anteriorcingulategyrus_batch3_fraction*.raw
anteriorcingulategyrus_batch4
anteriorcingulategyrus_batch4_fraction*.raw
anteriorcingulategyrus_batch5
anteriorcingulategyrus_batch5_fraction*.raw
frontalcortex_batch1
frontalcortex_batch1_fraction*.raw
frontalcortex_batch2
frontalcortex_batch2_fraction*.raw
frontalcortex_batch3
frontalcortex_batch3_fraction*.raw
frontalcortex_batch4
frontalcortex_batch4_fraction*.raw
frontalcortex_batch5
frontalcortex_batch5_fraction*.raw


Download Using WSL
Move to the RAW directory for your assigned batch.

Example for Batch 1 (change /batch{n}/ according to your batch):
cd ~/projects/PXD007160/batch1/raw

Start the download process with the following command.

Example for frontalcortex Batch 1 (change /batch{n}/ according to your batch):
batch="frontalcortex_batch1"; base="https://ftp.pride.ebi.ac.uk/pride/data/archive/2018/02/PXD007160"; for i in $(seq -w 1 21); do filename="${batch}_fraction${i}.raw"; echo "Downloading: $filename"; wget -c "$base/$filename"; done

3. Verify Download
Remain in WSL: (change /batch{n}/ according to your batch)
cd ~/projects/PXD007160/batch1/raw

Count RAW files:
ls *.raw | wc -l
Expected:
21

List files:
ls
Example:
frontalcortex_batch1_fraction1.raw
frontalcortex _batch1_fraction2.raw
...
frontalcortex _batch1_fraction21.raw

Check file sizes:
ls -lh *.raw

Verify that all files have reasonable sizes and none are unexpectedly small.

4. Convert RAW Files to mzML
Install ProteoWizard
Use the following URL to download:
https://proteowizard.sourceforge.io/download.html

Install ProteoWizard with default settings.

Open Windows PowerShell and find the folder with msconvert.exe
Look for the ProteoWizrd location 
cmd /c "dir C:\msconvert.exe /s /b"
Example output:
"C:\Users\Роксолана\AppData\Local\Apps\ProteoWizard 3.0.26154.b2d4072 64-bit\msconvert.exe" 

Check if program is active 
"C:\Users\Роксолана\AppData\Local\Apps\ProteoWizard 3.0.26154.b2d4072 64-bit\msconvert.exe"  --help

5. Determine Paths for files and folders inside wsl
For the RAW directory:
wslpath -w ~/projects/PXD007160/batch1/raw

For the mzML output directory:
wslpath -w ~/projects/PXD007160/batch1/mzml

Example outputs:
\\wsl.localhost\Ubuntu\home\rokdem\projects\PXD007160\batch1\raw
\\wsl.localhost\Ubuntu\home\rokdem\projects\PXD007160\batch1\mzml

Copy these paths somewhere convenient because they will be used during conversion.

6. Automated Command-Line Conversion 

Open a new PowerShell window.

Create Temporary Windows Directories (I used disk D as it has more space on my laptop)

$winRawDir = "D:\Temp_PXD007160\raw"
$winMzmlDir = "D:\Temp_PXD007160\mzml"
New-Item -ItemType Directory -Force -Path $winRawDir
New-Item -ItemType Directory -Force -Path $winMzmlDir

Copy RAW Files from WSL to Windows
Copy-Item `
    -Path "\\wsl.localhost\Ubuntu\home\<YOUR_WSL_USERNAME>\projects\PXD007160\batch1\raw\*.raw" `
    -Destination $winRawDir

Verify:
Get-ChildItem $winRawDir
Expected:
21 RAW files

Specify your ProteoWizard path
$msconvertExe = "C:\Users\username\AppData\Local\Apps\ProteoWizard 3.0.xxxxx\msconvert.exe"

Verify 
& $msconvertExe –help

Convert RAW Files to mzML
Write-Host "Starting batch conversion..."
Get-ChildItem -Path $winRawDir -Filter *.raw | ForEach-Object {
    Write-Host "Converting $($_.Name)"
    & $msconvertExe $_.FullName `
        --mzML `
        --zlib `
        --filter "peakPicking true 1-3" `
        --filter "titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState>" `
        -o $winMzmlDir
    Write-Host "Finished $($_.Name)"
}
Write-Host "All conversions completed."

Copy mzML Files Back to WSL
$wslMzmlDir = "\\wsl.localhost\Ubuntu\home\<YOUR_WSL_USERNAME>\projects\PXD007160\batch1\mzml"
Move-Item `
    -Path "$winMzmlDir\*.mzML" `
    -Destination $wslMzmlDir

7. Verify Conversion
Open WSL:
cd ~/projects/PXD007160/batch1/mzml

Count mzML files:
ls *.mzML | wc -l
Expected:
21

Check file sizes:
ls -lh *.mzML

Verify that:
All expected mzML files are present.
No mzML file is zero bytes.
File sizes are consistent with the corresponding RAW files.

