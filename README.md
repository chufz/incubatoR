# incubatoR

## Description:

This repository is containing the code used in "Improving the screening annotation level of pesticide metabolites with combined high-throughput in-vitro incubation and automated LC-HRMS data processing" for reproducibility. 

Main task are to identify metabolic transformation products in a LC-HRMS2 dataset of in-parallel incubated xenobiotic compounds by applying statistical tools as well as mass defect filtering and extraction of the respective mass spectra for spectal library generation.

An example dataset has been  deposited to the EMBL-EBI MetaboLights database39 (DOI: 10.1093/nar/gkz1019, PMID:31691833) with the identifier MTBLS2402 and is accessible directly at https://www.ebi.ac.uk/metabolights/MTBLS2402.

The code was modified to run on a entOS7 high performance computation (HPC) cluster based on the R language (v 3.6.1) and wrapped in bash shell commands for parallel processing and job submission using the unix shell job sheduler command `qsub`.

## Sample nomenclature: 

The sample set should contain measurements of incubated replicates of each compound, a reference standard solution, negative controls and injection/ sample peparation blanks. 

The **incubated sample names** contain a string identifing the different xenobiotic compounds used for incubation (e.g. Terbuthylazine) followed by a `_R` and a numeric value idenfing the replicate (e.g. XX_Terbuthylazine_R1.mzML). 

The **reference standard solution names** contain the name of the xenobiotic compound followed by a sting identifing to be a reference standard solution (e.g. `_clean` XX_Terbuthylazine_clean.mzML).

The **negative controls** contain a string intentifing to be a negative control (e.g. XX_NC1.mzML).

**Sample extraction blanks** and **Injection blanks** should also be identified by a unique string (e.g. XX_Blank1.mzML or XX_B.mzML).

Different ionization modes are stored in seperate folders named `Pos` and `Neg`.

## Order of calculation steps:

Follwing calculation steps are provided:

 1. Peaklist generation (XCMS [1] and CAMERA [2]) by `Rscripts/xcms.R` and `Rscripts/camera.R` (`bash/jobsubmit_1xcms.sh` and `bash/jobsubmit_camera.sh` for parallel job submission).
 
      *XCMS:*
      
      **INPUT:** `settings_xcms.yaml`, `class.csv`, `globalvar.sh`
      
      **OUTPUT:** `xcms.RData`
      
      *CAMERA:*
      
      **INPUT:** `settings_camera.yaml`, `xcms.RData`, `globalvar.sh`
      
      **OUTPUT:** `camera.RData`, `metadata.tsv`, `peaklist.tsv`
      
 2. Calculation of the statistical comparisson by `Rscripts/statistics.R` (`bash/jobsubmit_2statistics.sh` for parallel job submission), including the package Rvolcano [3] in case of the application of robust stastistics.
 
      **INPUT:** `compounds.txt`, `metadata.tsv`, `peaklist.tsv`, `parameter_statistic.sh`, `globalvar.sh`
      
      **OUTPUT:** `compound/Stat_compound.RData`
      
 3. Filtering of non-metabolic features by several cut-off values and plotting for manual evaluation by `Rscripts/metabolites.R` (`bash/jobsubmit_3metabolites.sh` for parallel job submission).
 
      **INPUT:** `compounds.txt`, `Stat_compound.RData`, `parent_compound.txt`, `target_compound.txt`, `parameter_filter.sh`, `globalvar.sh`
      
      **OUTPUT:** `compound/Diff_compound.png`, `compound/Volcano_compound.png`, `compound/MDF_compound.png`, `compound/Feature_compound.png`, `compound/Metabolite_compound.txt`
      
 4. EIC extraction of the suspected metabolite features`Rscripts/eic.R` (`bash/jobsubmit_4eic.sh` for parallel job submission), based on MSnBase [4].
 
      **INPUT:** `compounds.txt`, `compound/Metabolite_compound.txt`, `globalvar.sh`
      
      **OUTPUT:** `compound/EIC_metabolite`
      
 5. MSMS extraction an spectral purity evaluation (implementation of MSpurity [5]) by `Rscripts/ddextract.R` (`bash/jobsubmit_5ddextract.sh` for parallel job submission).
 
      **INPUT:** `compounds.txt`, `compound/Metabolite_compound.txt`, `parameter_msms.sh`, `globalvar.sh`
      
      **OUTPUT:** `compound/MSMS/*`
      
 6. Molecular formula annotation - implementation of GenForm [6]  (`bash/jobsubmit_6genform.sh` for parallel job submission).
 
     **INPUT:** `compounds.txt`, `compound/MSMS/*`, `compound/MSMS/*/MS1.txt`, `compound/MSMS/*/FF.txt`, `parameter_genform.sh`, `globalvar.sh`
     
      **OUTPUT:** `compound/MSMS/*/*.out` `compound/MSMS/*/Clean_*.txt`
 
 ### References
 
 [1] Smith, C. A.; Want, E. J.; O’Maille, G.; Abagyan, R.; Siuzdak, G. XCMS: Processing Mass Spectrometry Data for Metabolite Profiling Using Nonlinear Peak Alignment, Matching, and Identification. Anal. Chem. 2006, 78 (3), 779–787. https://doi.org/10.1021/ac051437y.
 
 [2] Hochreiter, S. Bioinformatics Research and Development: First International Conference, BIRD 2007, Berlin, Germany, March 12-14, 2007, Proceedings; Springer Science & Business Media, 2007.
 
 [3] Kumar, N.; Hoque, Md. A.; Sugimoto, M. Robust Volcano Plot: Identification of Differential Metabolites in the Presence of Outliers. BMC Bioinformatics 2018, 19. https://doi.org/10.1186/s12859-018-2117-2.
 
 [4] Gatto, L.; Lilley, K. S. MSnbase-an R/Bioconductor Package for Isobaric Tagged Mass Spectrometry Data Visualization, Processing and Quantitation. Bioinformatics 2012, 28 (2), 288–289. https://doi.org/10.1093/bioinformatics/btr645.
 
 [5] Lawson, T. N.; Weber, R. J. M.; Jones, M. R.; Chetwynd, A. J.; Rodrı́guez-Blanco, G.; Di Guida, R.; Viant, M. R.; Dunn, W. B. MsPurity: Automated Evaluation of Precursor Ion Purity for Mass Spectrometry-Based Fragmentation in Metabolomics. Anal. Chem. 2017, 89 (4), 2432–2439. https://doi.org/10.1021/acs.analchem.6b04358.
 
 [6] Meringer, M.; Reinker, S.; Zhang, J.; Muller, A. MS/MS Data Improves Automated Determination of Molecular Formulas by Mass Spectrometry. MATCH Communications in Mathematical and in Computer Chemistry 2011, 65, 259–290.
