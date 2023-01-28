#!/usr/bin/env bash
#this script is dependent on the Advanced Normalization Tools framework
#see https://github.com/ANTsX/ANTs for unmodified ANTs
###
#Primary author: David Haddad
#edited by C. Cataldo-Ramirez
###

# to run script in linux subsystem for windows, type below into terminal:
# bash ./modified_ANTs.sh

# use these 2 exports for and change path if
# ANTs registration location is not found
export ANTSPATH=/mnt/d/Research/bin
export PATH=${ANTSPATH}:$PATH

export WKDIR=$PWD/
export DATADIR=${WKDIR}Images_nii/
export DIRNIIGZ=${WKDIR}Images_nii_gz/
export OUTDIR=${WKDIR}Out/

# current directory (WKDIR) must contain:
# Images_nii/ folder (containing all .nii files) = DATADIR
# Images_nii_gz/ folder (containing all .nii.gz atlas image files) = DIRNIIGZ
# Out/ folder (will be the output directory) = OUTDIR


# Loop through currect directory and print out names of files
fixedCount=0
movingCount=0
fixedName=""
movingName=""

cd Images_nii

mkdir -p ${WKDIR}/manual_landmark_csv

export MANUALDIR=${WKDIR}/manual_landmark_csv/

# Check all the image nii files and sets fixed (atlas) image
for fixedImage in *; do
  movingCount=0
  isFixedGood=0
  isFixedSmall=0
  isFixedBio=0
  isfixedManualCreated=0
  manualName=""
  # get output fixed image without .nii
  # if name of file contains DXA_Images then get the name after
  fixedName=""
  if [[ $fixedImage =~ DXA_Images_(.*)_Bio_hm_small\.nii$ ]];
    then
    fixedName=${BASH_REMATCH[1]}
    isFixedGood=1
    isFixedSmall=1
  elif [[ $fixedImage =~ DXA_Images_(.*)_Bio_hm\.nii$ ]];
    then
    fixedName=${BASH_REMATCH[1]}
    isFixedBio=1
    isFixedGood=1
  elif [[ $fixedImage =~ DXA_Images_(.*)_hm_small\.nii$ ]];
    then
    fixedName=${BASH_REMATCH[1]}
    isFixedGood=1
    isFixedSmall=1
  elif [[ $fixedImage =~ DXA_Images_(.*)_hm\.nii$ ]];
    then
    fixedName=${BASH_REMATCH[1]}
    isFixedGood=1
  elif [[ $fixedImage =~ DXA_Images_(.*)_Bio\.nii$ ]];
    then
    fixedName=${BASH_REMATCH[1]}
    isFixedGood=1
  # otherwise get the name of the everything before .nii
  elif [[ $fixedImage =~ (.*)\.nii$ ]];
    then
    fixedName=${BASH_REMATCH[1]}
    isFixedGood=1
  else
    echo "Incorrect Fixed Image File: $fixedImage"
    echo ""
    isFixedGood=0
    fixedCount=$((fixedCount+1))
    continue
  fi

  # iterate through moving images in the images folder
  # inside the loop, we check to make sure moving and fixed
  # images are not the same
  for movingImage in *;  do
    isMovingGood=0
    isMovingSmall=0
    isMovingBio=0
    isfixedDirectoryCreated=0
    movingName=""

    if [ $movingCount -ne $fixedCount ];then
      if [[ $movingImage =~ DXA_Images_(.*)_Bio_hm_small\.nii$ ]];
        then
        movingName=${BASH_REMATCH[1]}
        isMovingGood=1
        isMovingSmall=1
      elif [[ $movingImage =~ DXA_Images_(.*)_Bio_hm\.nii$ ]];
        then
        movingName=${BASH_REMATCH[1]}
        isMovingBio=1
        isMovingGood=1
      elif [[ $movingImage =~ DXA_Images_(.*)_hm_small\.nii$ ]];
        then
        movingName=${BASH_REMATCH[1]}
        isMovingGood=1
        isMovingSmall=1
      elif [[ $movingImage =~ DXA_Images_(.*)_hm\.nii$ ]];
        then
        movingName=${BASH_REMATCH[1]}
        isMovingGood=1
      elif [[ $movingImage =~ (.*)\.nii$ ]];
        then
        movingName=${BASH_REMATCH[1]}
        isMovingGood=1
      else
        echo "Incorrect Moving Image File: $movingImage"
        echo ""
        movingCount=$((movingCount+1))
        isMovingGood=0
        continue
      fi

      # check to see if both fixed image and moving images are valid
      # then create fixed image folders and run ANTs registration in them
      if [ $isMovingGood -eq 1 ] && [ $isFixedGood -eq 1 ];then

        outputName="fixed_"
        outputName+="$fixedName"
        manualName="$fixedName"
        if [ $isFixedSmall -eq 1 ]; then
          outputName+="_small"
          manualName+="_small"
        elif [ $isFixedBio -eq 1 ]; then
          outputName+="_Bio"
          manualName+="_Bio"

        fi
        FixedFolderName="$outputName"
        outputName+="_moving_"
        outputName+="$movingName"

        MovingFolderName="moving_"
        MovingFolderName+="$movingName"

        if [ $isMovingSmall -eq 1 ]; then
          outputName+="_small"
          MovingFolderName+="_small"
        elif [ $isMovingBio -eq 1 ]; then
          outputName+="_Bio"
          MovingFolderName+="_Bio"
        fi

        outputnii="$outputName"
        outputWarped="$outputnii"
        outputWarped+="_Warped"

        echo "-------------------------------"
        echo $outputWarped

        # Create fixed folder and create a moving image subfolder 
        # for each moving image to house output files
        if [ $isfixedManualCreated -eq 0 ];then
          isfixedManualCreated=1
          ImageMath 2 ${MANUALDIR}${manualName}manual.csv LabelStats ${DIRNIIGZ}${fixedName}.nii.gz ${DIRNIIGZ}${fixedName}.nii.gz
          echo ${DIRNIIGZ}${fixedName}
        fi
        FILE=${MANUALDIR}${manualName}manual.csv
        if test -f "$FILE"; then
            echo "$FILE exists."
        else
            echo "$FILE does not exist."
            continue
        fi

        # Create fixed folder and moving image subfolders 
        if [ $isfixedDirectoryCreated -eq 0 ];then
          mkdir -p ${WKDIR}Out/$FixedFolderName
          isfixedDirectoryCreated=1
          OUTDIR=${WKDIR}Out/$FixedFolderName
        fi
        mkdir -p  $OUTDIR/$MovingFolderName
        OUTDIR=$OUTDIR/$MovingFolderName/


        antsRegistration \
        --dimensionality 2 \
        --float 0 \
        --output [${OUTDIR}${outputnii}.nii,${OUTDIR}${outputWarped}.nii.gz] \
        --interpolation Linear \
        --initial-moving-transform [${DATADIR}${fixedImage},${DATADIR}${movingImage},1] \
        --transform Rigid[0.1] \
        --metric MI[${DATADIR}${fixedImage},${DATADIR}${movingImage},1,32,Regular,0.25] \
        --convergence [1000x500x250x100,1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0mm \
        --transform Affine[0.1] \
        --metric MI[${DATADIR}${fixedImage},${DATADIR}${movingImage},1,32,Regular,0.5] \
        --convergence [1000x500x250x100,1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0mm \
        --transform SyN[0.25,3,0] \
        --metric CC[${DATADIR}${fixedImage},${DATADIR}${movingImage},1,10] \
        --convergence [100x70x50x20, 1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0mm \

        antsApplyTransformsToPoints -d 2 -i ${MANUALDIR}${manualName}manual.csv -o ${OUTDIR}prop${outputnii}.csv -t ${OUTDIR}${outputnii}.nii1Warp.nii.gz -t ${OUTDIR}${outputnii}.nii0GenericAffine.mat


        echo "Completed ANTs Registration"
        echo "-------------------------------"
        echo ""
      fi

    fi
    movingCount=$((movingCount+1))
  done

  # move to next fixed image and reset moving index
  fixedCount=$((fixedCount+1))
done