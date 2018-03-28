function matchResult=aoRegMatch(searchStrip,curStrip)
% calculate the similarity of two array
%
% Syntax:
%    matchResult=aoRegMatch(searchStrip,curStrip)
%
% Description:
%    according to SAD, or SSAD, NCC, get the similarity
%
%
% Inputs:
%    searchStrip        - Matched array.
%    curStrip           - Current array.
% 
% Outputs:
%    matchResult        - match result.
%
% Optional key/value pairs:
%    None.
%
% See also:

% History:
%   03/14/18  tyh

%%-------------------------------------

%adjust data type
searchStrip=double(searchStrip);
curStrip = double(curStrip);
%get the array size
[s1,s2]=size(searchStrip);
matchResult = 0;
%cal the SAD, for easier hardware implementation
% for i=1:s1
%     for j=1:s2
%         matchResult = matchResult + abs(searchStrip(i,j)-curStrip(i,j));
%     end
% end
% matchResult = matchResult/2^8;
a=searchStrip;
b=curStrip;
a = a - mean2(a);
b = b - mean2(b);
suma=sum(sum(a.*a));
sumb=sum(sum(b.*b));
if (suma==0 || sumb==0)
    r=0;
else
    r = sum(sum(a.*b))/sqrt(suma*sumb);
end

matchResult = r;

