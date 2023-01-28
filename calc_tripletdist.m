% calc_tripletdist
%
% Code developed by T.D. Weaver and C. Cataldo-Ramirez
%
% Calculates the average Euclidean distance between a triplet of landmark
% configurations. The landmarks are assumed to be stored in flattened form
% in config_landmarks, with a row for each configuration. The distance is
% returned in dist.

function [dist] = calc_tripletdist(config_landmarks)

pairs = [1,2;1,3;2,3];
npairs = 3;

dist = 0;
for i=1:npairs
    dist = dist + norm(config_landmarks(pairs(i,1),:)- ...
        config_landmarks(pairs(i,2),:));
end
dist = dist/npairs;

end