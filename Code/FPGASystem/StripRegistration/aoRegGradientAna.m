function aoRegGradientAna(mv)
% Do movement vector's gradient analysis
%
% Syntax:
%     aoRegGradientAna(mv)
%
% Description:
%    want to know the eye movement's feature, early draft
%
% Inputs:
%    mv                 - eye's movement, after registration.
%

% History:
%   30/04/18  tyh

%get the mv length
len = length(mv);

%gradient between mv
for i = 1:len-1
    g(i)=mv(i+1)-mv(i);
end

%figure the gradient to find the movement feature
figure;plot(g)
