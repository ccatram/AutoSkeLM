% choose_propagations_subset
%
% Code developed by T.D. Weaver and C. Cataldo-Ramirez
%
% This code is run for the "Post-propagation Quality Control" step 
% described in "Developing an automated skeletal phenotyping pipeline to
% leverage biobank-level medical imaging databases". The goal is to choose
% a subset of three propagations that are consistent with each other and
% average these three propagations for all of the individuals in the
% sample.
%
% Shape analysis functions written by Simon Preston are used to perform the
% Generalized Procrustes Analysis (GPA):
% https://www.maths.nottingham.ac.uk/plp/pmzspp/shape.php
%

clear all

% Adding the directory where shape analysis function M-files (written by 
% Simon Preston) are found to the path, so these functions can be called
gmrootdir = ...
    '[REPLACE WITH DIRECTORY WHERE SHAPE ANALYSIS FUNCTION M-FILES ARE FOUND]';
oldpath = addpath(gmrootdir);

% Moving to the directory where the automated phenotyping M-files are
% found, so these functions can be called without adding the folder to the
% path
cd '[REPLACE WITH DIRECTORY WHERE AUTOMATED PHENOTYPING M-FILES ARE FOUND]'

% Set directories (atlas landmark files, propagated landmark files, output)
atlasrootdir = ...
    '[REPLACE WITH DIRECTORY WHERE ATLAS LANDMARK FILES ARE FOUND]';
proprootdir = ...
    '[REPLACE WITH DIRECTORY WHERE PROPAGATED LANDMARK FILES ARE FOUND]';
outputrootdir = ...
    '[REPLACE WITH DIRECTORY WHERE OUTPUT FILES SHOULD BE SAVED]';    

% Set cutoffs for determining if landmark propagations should be used
triplet_dist_cut = 25; % avg pairwise distance has to be lower
atlas_mean_dist_cut = 0.0035; % configs have to be less than this far away

% Whether or not to write output to files
write_output = 1; % zero means don't write output

% Create a table of all of the atlas csv files in the path
fprintf('CREATING LIST OF ATLAS FILES...\n');
filelist = dir(fullfile(atlasrootdir,'*.csv*'));
num_atlas = length(filelist); % number of atlases
atlas_table = struct2table(filelist);

% Read in atlas landmark data
fprintf('READING IN ATLAS DATA...\n');
for i=1:num_atlas
    name = atlas_table{i,'name'}; % getting file name
    fname = strcat(atlasrootdir,name); % adding path
    fname = fname{1};
    
    % reading in and storing landmarks
    landmarksl = readmatrix(fname,'NumHeaderLines',1);
    landmarksl = landmarksl(:,1:2);
    landmarks = landmarksl;
    atlas_o_landmarks(i,:) = reshape(landmarks',1,[]);
end

num_coord = size(atlas_o_landmarks,2); % number of variables (coordinates)
num_land = num_coord/2; % number of landmarks

% Calculating Procrustes mean for the atlases
fprintf('CALCULATING ATLAS MEAN...\n');
for i=1:num_atlas
    atlas_rlandmarks(:,:,i) = reshape(atlas_o_landmarks(i,:),2,num_land);
end
[atlas_p_rlandmarks,perr] = GPA(atlas_rlandmarks,true);
atlas_p_mean = reshape(mean(atlas_p_rlandmarks,3),1,[]);

% Calculate Procrustes distance of individual atlases to Procrustes mean of
% the atlases
fprintf('CALCULATING ATLAS PROCRUSTES DISTANCES...\n');
for i=1:num_atlas
    cref = reshape(atlas_p_mean,2,num_land)';
    ctar = reshape(atlas_o_landmarks(i,:),2,num_land)';
    atlas_pdist(i) = procrustes(cref,ctar,'Reflection',false);
end

% Calculate triplet distance for all triplets of the atlases
%
fprintf('CALCULATING ATLAS TRIPLET DISTANCES...\n');
acombct = 0;
for i=1:num_atlas
    for j=i+1:num_atlas
        for k=j+1:num_atlas
            acombct = acombct+1;
            acombs(acombct,:) = [i j k];
        end
    end
end
ancombs = size(acombs,1);
for i=1:ancombs
    atripletD(i) = calc_tripletdist(atlas_o_landmarks(acombs(i,:),:));
end

% Create a table of all of the propagated csv files in the path
fprintf('CREATING LIST OF PROPAGATED FILES...\n');
filelist = dir(fullfile(proprootdir,'*.csv*'));
num_configs = length(filelist); % number of propagated landmark files
prop_table = struct2table(filelist);

% Read in propagated landmark data
fprintf('READING IN PROPAGATED DATA (%d files)...\n',num_configs);
for i=1:num_configs
    name = prop_table{i,'name'}; % getting file name
    fname = strcat(proprootdir,name); % adding path
    fname = fname{1};
    
    % reading in and storing landmarks
    landmarksl = readmatrix(fname,'NumHeaderLines',1);
    landmarksl = landmarksl(:,1:2);
    landmarks = landmarksl;
    config_o_landmarks(i,:) = reshape(landmarks',1,[]);
    
    % storing labels
    fixmovnames = split(regexprep(regexprep(regexprep(name, ...
        'propfixed_',''),'moving',''),'.csv',''),"__");
    fix_labels(i,:) = fixmovnames(1); % atlas name
    mov_labels(i,:) = fixmovnames(2); % propagated-to image name
    fprintf('%d ',i);
    if mod(i,10) == 0
        fprintf('\n');
    end
end

% Sorting configs by propagated-to (moving) image name
fprintf('SORTING PROPAGATED DATA...\n');
[s_mov_labels,si] = sort(mov_labels);
s_fix_labels = fix_labels(si);
s_config_o_landmarks = config_o_landmarks(si,:);

% Calculate Procrustes distances to mean of the atlases
fprintf('CALCULATING PROCRUSTES DISTANCES TO ATLAS MEAN...\n');
for i=1:num_configs
    cref = reshape(atlas_p_mean,2,num_land)';
    ctar = reshape(s_config_o_landmarks(i,:),2,num_land)';
    s_pdist(i) = procrustes(cref,ctar,'Reflection',false);
end

% Assigning groups by moving image
fprintf('ASSIGNING GROUPS OF PROPAGATED CONFIGURATIONS...\n');
[gnum,gname] = findgroups(s_mov_labels);
num_grps = max(gnum); % number of groups (moving image sets)

% Two-step QC of propagations by moving image
fprintf('TWO-STEP QC OF PROPAGATIONS...\n');
flags = strings(num_grps,1); % initializing passed (not passed) flags
for i=1:num_grps
    gidx = ismember(gnum,i);
    g_config_landmarks_all = s_config_o_landmarks(gidx,:);
    g_fix_labels_all = s_fix_labels(gidx,:);
    g_pdist = s_pdist(gidx);
    gnprop(i) = sum(gidx); % number of propagations for the group
    gpassct(i) = 0;
    for j=1:gnprop(i)
        if g_pdist(j) < atlas_mean_dist_cut && ...
                min(g_config_landmarks_all(j,:)) > 0
            gpassct(i) = gpassct(i)+1;
            gpassidx(gpassct(i)) = j; % indices of configs to use further
        end
    end
    gtripletD(i) = 999;
    gbesttripletD(i) = gtripletD(i);
    if gpassct(i) > 2 % was first QC step passed?
        gpassidx = gpassidx(1:gpassct(i));
        gconfig_landmarks = g_config_landmarks_all(gpassidx,:);
        gfix_labels = g_fix_labels_all(gpassidx,:);
        [gcombs,gncombs] = calc_combs(gpassct(i));
        gcombct(i)=0;
        while (gtripletD(i) >= triplet_dist_cut) && ...
                (gcombct(i) < gncombs)
            gcombct(i) = gcombct(i)+1;
            gtripletD(i) = ...
                calc_tripletdist(gconfig_landmarks(...
                gcombs(gcombct(i),:),:));
            if gtripletD(i) < gbesttripletD(i)
                gbesttripletD(i) = gtripletD(i);
            end
        end
        if i == 1 % create pickedatlas table
            pickedatlastable = table(gname(i), ...
                gfix_labels(gcombs(gcombct(i),:))','VariableNames', ...
                {'Moving Image','Picked Atlases'});
        else % otherwise, append rows to existing pickedatlastable
            pickedatlastable = [pickedatlastable; table(gname(i), ...
            gfix_labels(gcombs(gcombct(i),:))','VariableNames', ...
            {'Moving Image','Picked Atlases'})];
        end
        if gtripletD(i) < triplet_dist_cut % was second QC step passed?
            flags(i) = 'yes';
            flagsbool(i) = 1;
            % Save mean of accepted triplet in "propAvg_moving ..." files
            meanconfig = mean(gconfig_landmarks(gcombs(gcombct(i),:),:));
            outname = strcat(outputrootdir,'propAvg_moving_', ...
                char(gname(i)),'.csv');
            split_land = reshape(meanconfig,2,num_land)';
            x = split_land(:,1);
            y = split_land(:,2);
            z = zeros(num_land,1);
            t = zeros(num_land,1);
            label = (1:num_land)';
            mass = (1:num_land)';
            volume = ones(num_land,1); % note: overwrites function 'volume'
            count = ones(num_land,1); % note: overwrites function 'count'
            outtable = table(x,y,z,t,label,mass,volume,count);
            if write_output
                writetable(outtable,outname);
            end
        else
            flags(i) = 'no';
            flagsbool(i) = 0;
        end
    else
        flags(i) = 'no';
        flagsbool(i) = 0;
    end
    fprintf('%d ',i);
    if mod(i,10) == 0
        fprintf('\n');
    end
end
flagsbool = logical(flagsbool);
fprintf('\n');

% Output flags and other information to files
%
% summary.csv contains some summary information about the QC steps: the 
% number of propagations to start with, the number of propagations that
% passed the first QC step, the average Euclidean distance for the best
% triplet (or the triplet that was used if the second QC step was passed),
% and whether or not both QC steps were passed for the individual 
% (moving image).
%
% picked_atlases.csv contains for each individual (moving image) that
% passed the QC steps the labels for the three atlases that were selected
% and used to calculate the average.

if write_output
    fprintf('SAVING INFO...\n');
    moving_image = gname;
    number_of_propagations = gnprop';
    accepted_propagations = gpassct';
    best_triplet_distance = gbesttripletD';
    passed = flags;
    f_table = table(moving_image,number_of_propagations, ...
        accepted_propagations,best_triplet_distance,passed);
    f_outname = strcat(outputrootdir,'summary.csv');
    writetable(f_table,f_outname);
    pickedatlastable = pickedatlastable(flagsbool',:); % remove failures
    f_outname = strcat(outputrootdir,'picked_atlases.csv');
    writetable(pickedatlastable,f_outname);
end

% Setting path back to what it was before
path(oldpath);
