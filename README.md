# incubatoR

## Description:

This repository is containing the code used in "Improving the screening annotation level of pesticide metabolites with combined high-throughput in-vitro incubation and automated LC-HRMS data processing" for reproducibility. 

Main task are to identify metabolic transformation products in a LC-HRMS2 dataset of in-parallel incubated xenobiotic compounds by applying statistical tools as well as mass defect filtering and extraction of the respective mass spectra for spectal library generation.

An example dataset has been  deposited to the EMBL-EBI MetaboLights database39 (DOI: 10.1093/nar/gkz1019, PMID:31691833) with the identifier MTBLS2402 and is accessible directly at https://www.ebi.ac.uk/metabolights/MTBLS2402.

The code was modified to run on a entOS7 high performance computation (HPC) cluster based on the R language (v 3.6.1) and wrapped in bash shell commands for parallel processing and job submission using the unix shell job sheduler command `qsub`.

## Sample Nomenclature: 

The sample set should contain measurements of incubated replicates of each compound, a reference standard solution, negative controls and injection/ sample peparation blanks. 

The **incubated sample names** contain a string identifing the different xenobiotic compounds used for incubation (e.g. Terbuthylazine) followed by a `_R` and a numeric value idenfing the replicate (e.g. XX_Terbuthylazine_R1.mzML). 

The **reference standard solution names** contain the name of the xenobiotic compound followed by a sting identifing to be a reference standard solution (e.g. XX_Terbuthylazine_clean.mzML)

The **negative controls** contain a string intentifing to be a negative control (e.g. XX_NC.mzML)

**Sample extraction blanks** and **Injection blanks** should also be identified by a unique string (e.g. XX_Blank1.mzML)

## Order of calculation steps:

Follwing calculation steps are provided:

 1. Peaklist generation (XCMS and CAMERA []) by xx.R (xx.sh for parallel job submission)
      INPUT:
      OUTPUT:
 2. Calculation of the statistical comparisson by xx.R (xx.sh for parallel job submission)
      INPUT:
      OUTPUT:
 3. Filtering of non-metabolic features by several cut-off values and plotting for manual evaluation by xx.R (xx.sh for parallel job submission)
      INPUT:
      OUTPUT:
 4. EIC extraction of the suspected metabolite features xx.R (xx.sh for parallel job submission)
      INPUT:
      OUTPUT:
 5. MSMS extraction an spectral purity evaluation (implementation of MSpurity []) by xx.R (xx.sh for parallel job submission)
      INPUT:
      OUTPUT:
 6. Molecular formula annotation (implementation of GenForm []) by xx.R (xx.sh for parallel job submission)
      INPUT:
      OUTPUT:
 
