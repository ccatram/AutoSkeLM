% calc_centsize
%
% Code developed by T.D. Weaver and C. Cataldo-Ramirez
%
% Calculates the centroid size for a configuration of landmarks. The
% landmarks are assumed to be stored in flattened form in config_landmarks.
% The centroid size is returned in csize.

function [csize] = calc_centsize(config_landmarks)

mconfig = mean(config_landmarks);
n = size(config_landmarks,1);

csize = 0;
for i=1:n
    csize = csize+sum((config_landmarks(i,:)-mconfig).^2);    
end
csize = sqrt(csize);

end