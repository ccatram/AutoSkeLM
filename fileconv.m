%Image preprocessing step 1
%Inputs: all dicom files in directory & subdirectories
%Outputs: .nii image files

%Authors: Timothy D. Weaver & Chelsea Cataldo-Ramirez

%to run, save script in working directory 
%in matlab command window, navigate to directory & type
%run("fileconv.m")

%read in all dcm files from current directory
%extract file & header info
dicomlist = dir(fullfile(pwd,'*.dcm'));
for cnt = 1 : numel(dicomlist)
    info{cnt} = dicominfo(fullfile(pwd,dicomlist(cnt).name));
    I{cnt} = dicomread(fullfile(pwd,dicomlist(cnt).name));
end

%convert all files in directory to nifti format-- this converts EVERYTHING,
%even files in subdirectories
inDIR = fullfile(pwd);
outDIR = fullfile(pwd);
dicm2nii(inDIR,outDIR,0)

%flip all nifti images (read, flip, write)
niftilist = dir(fullfile(pwd, '*.nii'));
for cnt = 1 : numel(niftilist)
    nTemp = niftiread(niftilist(cnt).name);
    nTemp2 = fliplr(nTemp);
    niftiwrite(nTemp2,niftilist(cnt).name);
end
