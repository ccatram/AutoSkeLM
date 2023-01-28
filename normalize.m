%Image preprocessing step 2
%Inputs: all .nii files in directory; contrast_atlas2.nii (the image you'd
    %like to use to guide the histogram matching step)
%Outputs: *_hm.nii images with black backgrounds & consistent contrast

%Authors: Timothy D. Weaver & Chelsea Cataldo-Ramirez

%to run, save script in working directory 
%in matlab command window, navigate to directory & type
%run("normalize.m")

fnames = dir(fullfile(pwd, '*.nii')); % get list of nifti filenames
T = niftiread('contrast_atlas2.nii'); % read in adjusted image
    for cnt = 1 : numel(fnames) % for each filename in the list
        V = niftiread(fnames(cnt).name); % read in image to adjust
        if V(5,5) > 0 % check if the background is white
            mask = grayconnected(V, 5, 5);
            Vblack = V .* uint8(~mask);
            Vm = imhistmatch(Vblack, T);
        else
            Vm = imhistmatch(V, T);
        end
        [fpath, name, ext] = fileparts(fnames(cnt).name); % get filename parts
        niftiwrite(Vm, strcat(name, '_hm', ext)); % save adjusted file
    end