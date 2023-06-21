# Automated skeletal phenotyping for 2D landmark-based measurements

This repo contains the code/scripts for the method presented in “Developing an automated skeletal phenotyping pipeline to leverage biobank-level medical imaging databases” by Cataldo-Ramirez et al. (2023). See Cataldo-Ramirez et al. (2023) for a detailed discussion and recommended use of this automated phenotyping pipeline. 

**Objective/Purpose:** To automate the extraction of skeletal measurements from biobank-level samples of whole body DXA images.

**Dependant software and packages:**
Advanced Normalization Tools (Avants, Tustison, and Song, 2009; Avants, Johnson, and Tustison, 2015): https://github.com/ANTsX/ANTs
MATLAB: https://www.mathworks.com/
MATLAB add-ons:
dicm2nii: https://github.com/xiangruili/dicm2nii
Elliptic fourier for shape analysis: https://www.mathworks.com/matlabcentral/fileexchange/32800-elliptic-fourier-for-shape-analysis
shape: https://www.maths.nottingham.ac.uk/plp/pmzspp/shape.php

**Optional software and packages:**
ITK-SNAP: http://www.itksnap.org/pmwiki/pmwiki.php
R packages:
factoextra: https://CRAN.R-project.org/package=factoextra
FactoMineR: https://cran.r-project.org/web/packages/FactoMineR/index.html
ImageJ: https://imagej.nih.gov/ij/download.html


# Pipeline Overview
The automated phenotyping pipeline can be broken down into four main sections, described in more detail below:
1. Image pre-processing
2. Atlas selection and manual landmarking
3. Advanced Normalization Tools image registration and landmark propagation
4. Post-propagation quality control



**Image pre-processing (1)**

File conversion (DICOM to NIfTI): “*fileconv.m*”
Requires *dicm2nii* add-on package
Image normalization (background color and contrast matching): “*normalize.m*”
After converting images to .nii, select an image and manually modify the contrast and brightness in your image editor of choice. The image should be adjusted to minimize soft tissue visibility and maximize bone visibility. See Cataldo-Ramirez et al., 2023, Fig. 4 for an example. Save this image as a “*contrastatlas.nii*” file in the working directory for use with “normalize.m”.
Initial review (grid output preprocessed images): “*gridout.m*”

Outputs .png figure(s) with up to 100 images (per figure) in a 10 x 10 grid. Can be used to quickly review images after preprocessing. 

**Atlas selection and manual landmarking (2)**

Body outline extraction (binarize and outline) and shape quantification (EFA): “*shapevar.m*”
Requires MATLAB add-on “*Elliptic fourier for shape analysis*”
. It’s recommended to plot the PC scores at this point to identify outliers that may be incorrectly driving the first two axes of variation, and either remove or redo the outline extraction process on them. This can happen when the wrong outline is extracted, reflecting a shape inconsistent with the general human form.

Outputs “*ForPCAhcoef.txt*” file (the input needed for the PCA)
Shape variance quantification (PCA and hierarchical clustering) and atlas selection (identifying images to manually landmark)
Use the harmonic coefficients as input for a principal component analysis and perform hierarchical clustering on the resulting PC scores. Visualize the clusters to identify images that represent cluster means and edges (these will be your atlases– start with a selection of 3 to 4 images per cluster). 

We used R packages *FactoMineR* and *factoextra* to identify clusters using the first 3 PCs. Cluster visualization can be created using the *fvizcluster()* function and the more typical individuals of each cluster can be found by extracting $desc.ind from the *HCPC()* function output.
Manual landmarking (selecting skeletal measurements of interest and exporting image segmentation files)
Landmark the atlases in your preferred image processing software, and save each image-landmark set in .nii.gz format (i.e., the landmarks should be a segmentation layer). We used ITK-SNAP as it is already integrated for use with ANTs.

**Advanced Normalization Tools image registration and landmark propagation (3)**
Scripts: “*modifiedANTs.sh*” and “*modifiedANTs.py*”

File naming conventions: Current file naming conventions are based on the default output of UKB .dcm file header info extracted by the MATLAB add-on *dicm2nii*. Modify this section for use with your naming conventions.

Directory structure: The working directory where the script is run must contain an /Images_nii folder (containing all .nii files), an /Images_nii_gz folder (containing all .nii.gz atlas image files), and an /Out folder (that will act as the output directory).

Inputs:
Pre-processed .nii file for each image in dataset
.nii.gz file for each manually landmarked atlas image

Outputs:
A folder for each atlas image containing subfolders for the output of each moving image
Moving image subfolders containing:
Warp and inverse-warp .nii.gz files (used in the ANTs registration and landmark propagation call)
Warped.nii.gz file for visualizing the deformations
Propagated landmark coordinate .csv file


**Post-propagation quality control (4)**

Script: “*choosepropagationssubset.m*”, which calls functions defined in “*calccentsize.m*”, “*calccombs.m*”, and “*calctripletdist.m*”, and the GPA function of the “*shape*” add-on to Matlab (see above).

File naming conventions: The files containing the propagated landmark coordinates are assumed to have filenames of the form “propfixed_” followed by the fixed image name followed by “_moving_” followed by the moving image name (e.g., “propfixed_EX_4M_PL_E1_moving_T3_ST_12_34”); and be .csv files with the coordinate data structured as output by ANTs in the previous step.

Directory structure: Five directories need to be specified in the script: 1) where the shape analysis function m-files are found; 2) where the “calc_centsize.m”, “calc_combs.m”, and “calc_tripletdist.m” files are found; 3) where the atlas landmark files are found; 4) where the moving image propagated landmark files are found; and 5) where the output should be saved.

Inputs:
Multiple propagated landmark coordinate .csv files for each moving image (e.g., 10 different propagations for each moving image)
Landmark coordinate .csv files for the atlases

Outputs:
Mean (average) landmark coordinates for the propagated landmarks from three different atlases for all of the moving images that pass the QC steps. These coordinates are saved in files with names starting with “propAvg_moving_”.
“summary.csv” file containing information about the QC



*Scripts will be updated for efficiency and generalizability in the future.*



# Citations:
Avants, B. B., Johnson, H. J., & Tustison, N. J. (2015). Neuroinformatics and the insight toolkit. Frontiers in Neuroinformatics, 9, 5. 

Avants, B. B., Tustison, N., & Song, G. (2009). Advanced normalization tools (ANTS). Insight j, 2(365), 1-35.

Cataldo-Ramirez, C. C., Haddad, D., Amenta, N., & Weaver, T. D. (2023). Developing an automated skeletal phenotyping pipeline to leverage biobank-level medical imaging databases. American Journal of Biological Anthropology, 181(3), 413–425. https://doi.org/10.1002/ajpa.24736

Kassambara A, Mundt F (2020). _factoextra: Extract and Visualize the Results of Multivariate Data Analyses_. R package version 1.0.7, <https://CRAN.R-project.org/package=factoextra>. 

Lê, S., Josse, J., Husson, F. (2008). “FactoMineR: A Package for Multivariate Analysis.” Journal of Statistical Software, 25(1), 1–18. doi:10.18637/jss.v025.i01.

Li, Xiangrui (2022). xiangruili/dicm2nii (https://github.com/xiangruili/dicm2nii), GitHub. Retrieved September 5, 2022.

Manurung, Auralius (2022). Elliptic fourier for shape analysis (https://www.mathworks.com/matlabcentral/fileexchange/32800-elliptic-fourier-for-shape-analysis), MATLAB Central File Exchange. Retrieved September 7, 2022.

MATLAB. (2022a). Natick, Massachusetts: The MathWorks Inc.

R Core Team (2022). R: A language and environment for statistical computing. R Foundation for
Statistical Computing, Vienna, Austria. URL https://www.R-project.org/.

Schneider, C. A., Rasband, W. S., & Eliceiri, K. W. (2012). NIH Image to ImageJ: 25 years of image analysis. Nature Methods, 9(7), 671–675. doi:10.1038/nmeth.2089

