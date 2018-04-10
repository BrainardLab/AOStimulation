function theSimilarity = aoRegMatch(searchStrip,curStrip,varargin)
% Calculate the similarity of two arrays
%
% Syntax:
%    theSimilarity = aoRegMatch(searchStrip,curStrip)
%
% Description:
%    Compute similarity between two images of the same size.
%
%    We have three ways of computing similarity
%       'SAD': Sum of absolute differences
%       'SSAD': Sum of squared differences
%       'NCC': Cross-correlation
%
% Inputs:
%    searchStrip        - Matched array.
%    curStrip           - Current array.
%
% Outputs:
%    theSimilarity      - Computed similarity.
%
% Optional key/value pairs:
%    'SimilarityMethod' - String, specify similarity method (default
%                         'NCC').
%
% See also:
%

% History:
%   03/14/18  tyh
%   03/29/18  tyh, dhb  Comments.

% Parse
p = inputParser;
p.addParameter('SimilarityMethod','NCC',@ischar)
p.parse(varargin{:});

% Adjust input data type
searchStrip=double(searchStrip);
curStrip = double(curStrip);

% Compute similarity
switch (p.Results.SimilarityMethod)
    case 'NCC'
        % Cross correlation
        searchStrip = searchStrip - mean2(searchStrip);
        curStrip = curStrip - mean2(curStrip);
        suma=sum(sum(searchStrip.*searchStrip));
        sumb=sum(sum(curStrip.*curStrip));
        if (suma == 0 || sumb == 0)
            theSimilarity = 0;
        else
            theSimilarity = sum(sum(searchStrip.*curStrip))/sqrt(suma*sumb);
        end
    
    case 'NCC1'
        % Cross correlation's normalization
        searchStrip = searchStrip - mean2(searchStrip);
        curStrip = curStrip - mean2(curStrip);
        %reduce computation complexity by let pixel=0/1.
        [s1,s2] = size(searchStrip);
        for i=1:s1
            for j=1:s2
                if (searchStrip(i,j)<0)
                    searchStrip(i,j)=0;
                else
                    searchStrip(i,j)=1;
                end
                if (curStrip(i,j)<0)
                    curStrip(i,j)=0;
                else
                    curStrip(i,j)=1;
                end
            end
            
        end
        
        %calculate cross correlation
        suma=sum(sum(searchStrip.*searchStrip));
        sumb=sum(sum(curStrip.*curStrip));
        if (suma == 0 || sumb == 0)
            theSimilarity = 0;
        else
            theSimilarity = sum(sum(searchStrip.*curStrip))/sqrt(suma*sumb);
        end
        
    case 'sad'
        % Sum of absolute differences. Might be faster in hardware.
        error('SAD method not yet implemented');
        
        % Get the strip size
        % [s1,s2] = size(searchStrip);
        % for i=1:s1
        %     for j=1:s2
        %         theSimilarity = theSimilarity + abs(searchStrip(i,j)-curStrip(i,j));
        %     end
        % end
        %
        % Normalize similarity to be in a reasonalbe numberical range
        % normalizingFactor = 2^8;
        % theSimilarity = theSimilarity/normalizingFactor;
        
    case 'ssad'
        % Sum of squared absolute differences
        error('SSAD method not yet implemented');
        
    otherwise
        error('Unknow similarity method specified');
end




