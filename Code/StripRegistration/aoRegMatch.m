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
        %reduce computation complexity by binary pixels. Sort the pixel, set
        % the 128 bigger pixels is 1 and others are 0 in one line.
        % make sure sum of non zero pixels are 1024. 
        % avoid the multiply, sqrt and divide computation.
        % be good for small cone movies.
        [s1,s2] = size(searchStrip);
        for i=1:s1
            pixelLineInSearchStrip=searchStrip(i,:);
            [sortResult searchIdx]=sort(pixelLineInSearchStrip);
            pixelLineIncurStrip=curStrip(i,:);
            [sortResult curIdx]=sort(pixelLineIncurStrip);
            for j=1:s2
                if (j<(s2-127))
                    searchStrip(i,searchIdx(j))=0;
                    curStrip(i,curIdx(j))=0;
                else
                    searchStrip(i,searchIdx(j))=1;
                    curStrip(i,curIdx(j))=1;
                end
            end
            
        end

        %calculate cross correlation
        suma=sum(sum(searchStrip.*searchStrip));
        sumb=sum(sum(curStrip.*curStrip));
        t = sum(sum(searchStrip.*curStrip));
        t1 = max(suma,sumb);
        if (suma == 0 || sumb == 0)
            theSimilarity = 0;
        else
            theSimilarity = t/t1;
        end
    case 'NCC2'
        %Reduce computation complexity by binary pixels. make sure sum of
        % non zero pixels are 1024. Get the edge data of current strips by 
        % Prewitt. Sort the edge data and get the 128 edge point in one
        % line.
        
        %Get the Size
        [s1,s2] = size(searchStrip);
        
        % Use Prewwitt/gradiet to do edge select
        for m=1:s1
            for n=1:s2-4
                curPrewitt(m,n) = abs(curStrip(m,n+3)-curStrip(m,n+1)...
                                    +curStrip(m,n+4)-curStrip(m,n));
                searchPrewitt(m,n) = abs(searchStrip(m,n+3)-searchStrip(m,n+1)...
                                    +searchStrip(m,n+4)-searchStrip(m,n));
            end
        end
        
        % Binarize
        [s1,s2] = size(searchPrewitt);
        for i=1:s1
            pixelLineInSearchStrip=searchPrewitt(i,:);
            [sortResult searchIdx]=sort(pixelLineInSearchStrip);
            pixelLineIncurStrip=curPrewitt(i,:);
            [sortResult curIdx]=sort(pixelLineIncurStrip);
            for j=1:s2
                if (j<(s2-127))
                    searchPrewitt(i,searchIdx(j))=0;
                    curPrewitt(i,curIdx(j))=0;
                else
                    searchPrewitt(i,searchIdx(j))=1;
                    curPrewitt(i,curIdx(j))=1;
                end
            end
            
        end

        %calculate cross correlation
        suma=sum(sum(searchPrewitt.*searchPrewitt));
        sumb=sum(sum(curPrewitt.*curPrewitt));
        t = sum(sum(searchPrewitt.*curPrewitt));
        t1 = max(suma,sumb);
        if (suma == 0 || sumb == 0)
            theSimilarity = 0;
        else
            theSimilarity = t/t1;
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




