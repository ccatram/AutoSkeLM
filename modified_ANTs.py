#this script is dependent on the Advanced Normalization Tools framework
#see https://github.com/ANTsX/ANTs for unmodified ANTs
###
#Primary author: David Haddad
###

import os

'''
Make sure to Modify the ants path and then run it in your terminal
export ANTSPATH=/mnt/c/Research/bin
export PATH=${ANTSPATH}:$PATH
'''

# Extracts name of file from .nii or .nii.gz files
def getName (filename, format):
    text=""
    if format == ".nii":
        # Steps of splitting String for .nii
        # 1. DXA_Images_3Z_VQ_FK_2P_Bio_hm.nii
        # 2. 3Z_VQ_FK_2P_Bio_hm.nii
        # 3. 3Z_VQ_FK_2P
        text= filename.split("DXA_Images_")[1]
        text=text.split(format)[0]
        if "Bio" in text:
            text=text.split("_Bio")[0]
        elif "hm" in text:
            # Steps of splitting string for .nii.gz
            # 3Z_VQ_FK_2P.nii.gz
            # 3Z_VQ_FK_2P
            text=text.split("_hm")[0]
    else:
        text=filename.split(format)[0]
    return text

# Set Directories
WKDIR=os.getcwd()
DATADIR=os.path.join(WKDIR+"/Images_nii/")
DIRNIIGZ=os.path.join(WKDIR+"/Images_nii_gz/")
OUTDIR=os.path.join(WKDIR+ "/Out1")
MANUALDIR = os.path.join(WKDIR, "manual_landmark_csv1/")

if not os.path.isdir( os.path.join(WKDIR, "manual_landmark_csv1/")):
    os.mkdir(MANUALDIR)

# Iterate over nii.gz images to create manual landmark csv's
for fixed in os.listdir(DIRNIIGZ):
    fixedName = getName(fixed,'.nii.gz')
    fixedFolderName = "Fixed_" + fixedName
    if not os.path.isfile(MANUALDIR+fixedName+"manual.csv"):
        createManualCsv = f'''ImageMath 2 {MANUALDIR}{fixedName}manual.csv LabelStats {DIRNIIGZ}{fixedName}.nii.gz {DIRNIIGZ}{fixedName}.nii.gz
        '''
        os.system(createManualCsv)

# example of dictionary values
# 3Z_VQ_FK_2P: DXA_Images_3Z_VQ_FK_2P_Bio_hm.nii

nii_dict={}
# getting all nii files names in dictionary
for fixed in os.listdir(DIRNIIGZ):
    fixedName = getName(fixed,'.nii.gz')
    for moving in os.listdir(DATADIR):
        movingName=getName(moving,'.nii')
        if movingName not in nii_dict:
            nii_dict[movingName]=moving

# Iterate over Fixed Images (whatever is in nii.gz folder)
for fixed in os.listdir(DIRNIIGZ):
    fixedName = getName(fixed,'.nii.gz')
    fixedFolderName = "Fixed_" + fixedName
    # Create Folder for Fixed in Path
    if not os.path.isdir(os.path.join(WKDIR, "Out1/" + fixedFolderName)):
        os.mkdir(os.path.join(WKDIR, "Out1/" + fixedFolderName))

    # Iterate over Moving Images (whatever is in nii folder)
    for moving in os.listdir(DATADIR):
        movingName=getName(moving,'.nii')
        movingFolderName="Moving_"+movingName
        if fixedName not in movingName:
            # Create Moving Folder Inside of Fixed Folder
            if not os.path.isdir(os.path.join(WKDIR, "Out1/" + fixedFolderName + "/"+ movingFolderName)):
                os.mkdir(os.path.join(WKDIR, "Out1/" + fixedFolderName + "/"+ movingFolderName))

            OUTDIR=str(WKDIR) + "/Out1/" + fixedFolderName + "/"+ movingFolderName + '/'

            outputnii=fixedFolderName  + "_"+ movingFolderName
            outputWarped=outputnii+"_Warped"

            # Ants Registration Command that will be called
            antsCommand=f'''antsRegistration \
            --dimensionality 2 \
            --float 0 \
            --output [{OUTDIR}{outputnii}.nii,{OUTDIR}{outputWarped}.nii.gz] \
            --interpolation Linear \
            --initial-moving-transform [{DATADIR}{nii_dict[fixedName]},{DATADIR}{moving},1] \
            --transform Rigid[0.1] \
            --metric MI[{DATADIR}{nii_dict[fixedName]},{DATADIR}{moving},1,32,Regular,0.25] \
            --convergence [1000x500x250x100,1e-6,10] \
            --shrink-factors 8x4x2x1 \
            --smoothing-sigmas 3x2x1x0mm \
            --transform Affine[0.1] \
            --metric MI[{DATADIR}{nii_dict[fixedName]},{DATADIR}{moving},1,32,Regular,0.5] \
            --convergence [1000x500x250x100,1e-6,10] \
            --shrink-factors 8x4x2x1 \
            --smoothing-sigmas 3x2x1x0mm \
            --transform SyN[0.25,3,0] \
            --metric CC[{DATADIR}{nii_dict[fixedName]},{DATADIR}{moving},1,10] \
            --convergence [100x70x50x20, 1e-6,10] \
            --shrink-factors 8x4x2x1 \
            --smoothing-sigmas 3x2x1x0mm \
            antsApplyTransformsToPoints -d 2 -i {MANUALDIR}{fixedName}manual.csv -o {OUTDIR}prop{outputnii}.csv -t {OUTDIR}{outputnii}.nii1Warp.nii.gz -t {OUTDIR}{outputnii}.nii0GenericAffine.mat
            '''

            os.system(antsCommand)
            print(movingName,fixedName)

        else:
            continue

            
