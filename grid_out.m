%Inputs: all .nii files in directory
%Outputs: grid image (up to 100 per file), "1.png", "2.png", etc...

%Authors: Timothy D. Weaver, Chelsea Cataldo-Ramirez

% list files
num = 100;
dirList = dir(fullfile(pwd,'*_hm.nii'));%change per naming conventions
numI = numel(dirList);

% create 10x10 image plot to use in manual review
loops = ceil(numI/100);
for i=1:loops
    loopshift = (i-1)*num;
    if ((numI-loopshift) < 100)
        loopend = numI;
    else
        loopend = loopshift + 100;
    end
    for j=(loopshift +1):loopend
        imgs{j-loopshift,:}=niftiread(dirList(j).name);
        f=figure(i);
        subplot(10,10,j-loopshift)
        imshow(imgs{j-loopshift,:});
        set(gca,'xtick',[],'ytick',[]);
        title(dirList(j).name,'FontSize',6, 'Interpreter', 'none');
    end
    clear imgs
    f.Position=[10 10 1700 1000];
    saveas(f,num2str(i),'png');
end
