% calc_combs
%
% Code developed by T.D. Weaver and C. Cataldo-Ramirez
%
% Calculates all possible combinations of 3 for n items and returns these
% triplets in randomized order in combsidx and the total number of 
% combinations in ncombs. The variable combsidx is a ncombs x 3 matrix.
% 
% This code is based on a discussion on "Matlab Answers" about
% "produce all combinations of n choose k in binary", particularly the
% comment by John D'Errico.
%

function [combsidx,ncombs] = calc_combs(n)

k=3;
combs=dec2bin(0:2^n-1)-'0';
combs(sum(combs')~=k,:)=[];
combs=combs(randperm(size(combs,1)),:);
ncombs=size(combs,1);
for i=1:ncombs
    combsidx(i,:)=find(combs(i,:));
end

end