%Binarize, Outline, EFA (& optional PCA in MATLAB)
%input pre-rocessed .nii files
%output binarized.nii images (optional), chaincode.txt for each image, 
%harmonic coefficient array "ForPCA_hcoef.txt"

%Authors: Chelsea Cataldo-Ramirez & Timothy D. Weaver


%Create & save binarized .nii files:
fnames = dir(fullfile(pwd, '*.nii')); % get list of nifti filenames
for cnt = 1 : numel(fnames) % for each filename in the list
    V = niftiread(fnames(cnt).name); % read in image to adjust
    V(V>10) = 250;%convert pixel values over 10 to white
    [fpath, name, ext] = fileparts(fnames(cnt).name); % get filename parts
    niftiwrite(V, strcat(name, '_bin', ext)); % save adjusted file
end

%Create & save chain codes to .txt files:
fnames = dir(fullfile(pwd, '*bin.nii'));
for cnt = 1 : numel(fnames)
    I = niftiread(fnames(cnt).name);
    B = bwboundaries(I,8,'noholes'); %obtain shape boundaries
    O = B(1,:); %obtain the first outline in B (if image is preprocessed correctly, this will be the full-body outline)
    Bv = cell2mat(O); %convert to single column vector
    CC = chaincode(Bv, true); %create chain code
    CC2 = CC.code;
    [fpath, name, ext] = fileparts(fnames(cnt).name);
    writematrix(CC2, strcat(name, '_ccode', '.txt')); %save chain code as associated .txt file for each image
end

%Write harmonic coefficients to array:
numh = 40; %pick value that captures limb positioning but smooths imaging artifacts
cclist = dir(fullfile(pwd,'*ccode.txt'));%read in chain codes
numr = numel(cclist);
hcoef = zeros(numr,4*numh); %create array to house harmonic coefficients
for cnt = 1 : numel(cclist)
    ccode = readmatrix(fullfile(pwd,cclist(cnt).name));
        for c=1:numh
            O = calc_harmonic_coefficients(ccode',c); %calculate the harmonic coefficients
            p = 4*(c-1)+1;
            hcoef(cnt,p:(p+3))=O;
        end
end

%Calculate DC components (represent size) & store in list:
%cclist = dir(fullfile(pwd, '*_ccode.txt')); %un-comment this line if running separately from above code
dcList = zeros(numr,2);
for cnt = 1 : numel(cclist)
    I = load(cclist(cnt).name);
    CC = I';
    [A0, C0] = calc_dc_components(CC);
    dcList(cnt,1) = A0;
    dcList(cnt,2) = C0;
end

%Append dcList to hcoef:
ForPCA = [dcList hcoef];

%PCA
%Save ForPCA output:
writematrix(ForPCA,'ForPCA_hcoef.txt');

%Run PCA in MatLab (optional):
%[coeff,score,latent,tsquared,explained,mu] = pca(ForPCA);
