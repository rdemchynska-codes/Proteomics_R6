**PXD007160 Reanalysis Protocol**

**0\. Connecting to the Project Files**

**Open WSL and navigate to the directory where you want to store the project.**

```shell
mkdir -p ~/projects 
cd ~/projects
git clone https://github.com/rdemchynska-codes/Proteomics_R6.git 
cd Proteomics_R6

```

**Verify the files were downloaded:**

```shell
ls
```

**You should see folders such as:**

**batch1/**

**batch2/**

**batch3/**

**docs/**

**scripts/**

**database/**

**README.md**

**1\. Initial Setup**

Open WSL

```shell
cd scripts
./prepare_data.sh 1
```

Number is a batch number you are working with.

---

**2\. Convert RAW Files to mzML**

1. **Install ProteoWizard**  
   1. **Use the following URL to download:**

   [**https://proteowizard.sourceforge.io/download.html**](https://proteowizard.sourceforge.io/download.html)

   2. **Install ProteoWizard with default settings.**

   

2. **Open Windows PowerShell and find the folder with** *msconvert.exe*

```shell
Get-ChildItem -Path "$env:ProgramFiles\ProteoWizard*", "$env:LOCALAPPDATA\ProteoWizard*" -Filter "msconvert.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

Click Ctrl+C when you see the path to save time.

Example output:

*"C:\\Users\\Роксолана\\AppData\\Local\\Apps\\ProteoWizard 3.0.26154.b2d4072 64-bit\\msconvert.exe"* 

*Save your real output*

**Determine Paths for files and folders inside wsl**

Open WSL

**For the RAW directory:**

```shell
wslpath -w ~/projects/PXD007160/batch1/raw
```

**For the mzML output directory:**

```shell
wslpath -w ~/projects/PXD007160/batch1/mzml
```

**Example outputs:**

***\\\\wsl.localhost\\Ubuntu\\home\\rokdem\\projects\\PXD007160\\batch1\\raw***

***\\\\wsl.localhost\\Ubuntu\\home\\rokdem\\projects\\PXD007160\\batch1\\mzml***

**Save your real output.**

**Automated Command-Line Conversion** 

**Open a new PowerShell window.**

**Enter YOUR pathways**

```shell
$msconvertExe = "C:\Program Files\ProteoWizard\ProteoWizard 3.0.26160.4d20525\msconvert.exe"
$wslRawDir = "\\wsl.localhost\Ubuntu\home\rokdem\projects\PXD007160\batch1\raw" 
$wslMzmlDir = "\\wsl.localhost\Ubuntu\home\rokdem\projects\PXD007160\batch1\mzml"
```

**Create Temporary Windows Directories (I used disk D as it has more space on my laptop)**

```shell
$winRawDir = "D:\Temp_PXD007160\batch1\raw"
$winMzmlDir = "D:\Temp_PXD007160\batch1\mzml"
New-Item -ItemType Directory -Force -Path $winRawDir
New-Item -ItemType Directory -Force -Path $winMzmlDir
```

**Copy RAW Files from WSL to Windows**

```shell
Copy-Item `
    -Path "\\wsl.localhost\Ubuntu\home\rokdem\projects\PXD007160\batch1\raw\*.raw" `
    -Destination $winRawDir
```

**Verify:**

```shell
Get-ChildItem $winRawDir
```

**Expected:**

21 RAW files

**Convert RAW Files to mzML**

```shell
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

```

**Copy mzML Files Back to WSL**

```shell
Move-Item `
    -Path "$winMzmlDir\*.mzML" `
    -Destination $wslMzmlDir

```

---

**3\. Protein Identification Using TPP \+ Comet+Libra**

```shell
cd
docker run -it --rm \
-u 0 \
-v ~/projects/PXD007160:/data \
biocontainers/tpp:v5.2_cv1 bash
```

Inside the docker

```shell
cd scripts
./run_tpp_pipeline_quantification.sh 1

```

Number is a batch number you are working with.

