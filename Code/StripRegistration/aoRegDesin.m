function [desinMovies] = aoRegDesin(desinArray,rawMovies,maxMovieLength);
% Desinsoid the raw movies
%
% Syntax:
%    [desinMovies] = aoRegDesin(desinArray,rawMovies,maxMovieLength);
%
% Description:
%    Simplify the original desinsoid array by only selecting the max 6 
%    point every line. And the input raw movies multiply the array to
%    get the desinsoid movies.
%
%    We have three ways of computing similarity
%       'SAD': Sum of absolute differences
%       'SSAD': Sum of squared differences
%       'NCC': Cross-correlation
%
% Inputs:
%    desinArray         - original desinsoid array.
%    rawMovies          - raw movies.
%    maxMovieLength   - maximum frame number
%
% Outputs:
%    desinMovies        - desinsoided movides.
%
% Optional key/value pairs:
%    
%
% See also:
%

% History:
%   04/16/18  tyh

% Parse

%Simplify the desinsoid array
%Size of array
[s1,s2] = size(desinArray);

%Initial the array
desinArray1=zeros(s1,s2);

% Loop line by line
for i=1:s1
    
    %Sort the current line
    [sortVaule sortIdx] = sort(desinArray(i,:));
    
    %Define the max/next max value in the line 
    maxIdx = sortIdx(end);
    nextMaxIdx = sortIdx(end-1);
    
    %Judge if the max value and next max value is nearby
    if (abs(maxIdx-nextMaxIdx)~=1)
        sprintf('mismatch in Array line %d',i);
    end
    
    %Set nearby max value's 6 points as the meaningful points
    if (nextMaxIdx>maxIdx)
        selectP0Idx = maxIdx-2;
        selectP1Idx = maxIdx-1;
        selectP2Idx = maxIdx;
        selectP3Idx = nextMaxIdx;
        selectP4Idx = nextMaxIdx+1;
        selectP5Idx = nextMaxIdx+2;
    else
        selectP0Idx = nextMaxIdx-2;
        selectP1Idx = nextMaxIdx-1;
        selectP2Idx = nextMaxIdx;
        selectP3Idx = maxIdx;
        selectP4Idx = maxIdx+1;
        selectP5Idx = maxIdx+2;
    end
    
    %Update the simplified desinsoid array
    desinArray1(i,selectP0Idx) = desinArray(i,selectP0Idx);
    desinArray1(i,selectP1Idx) = desinArray(i,selectP1Idx);
    desinArray1(i,selectP2Idx) = desinArray(i,selectP2Idx);
    desinArray1(i,selectP3Idx) = desinArray(i,selectP3Idx);
    desinArray1(i,selectP4Idx) = desinArray(i,selectP4Idx);
    desinArray1(i,selectP5Idx) = desinArray(i,selectP5Idx);   
end

%frame loop
for frameIdx=1:maxMovieLength
    %Get the current raw image to desinsoid    
    rawImage = double(rawMovies(frameIdx).cdata);
    
    %For test, get the desinsoid movie by the original array
    oriDesinImage = uint8(fix(rawImage * desinArray'));
    
    %Get the desinsoid movie by the simplified array
    newDesinImage = uint8(fix(rawImage * desinArray1'));
    
    %
    desinMovies(:,:,frameIdx) = newDesinImage;
    
    %Get the different result by the two array
    diffMax = max(max(newDesinImage-oriDesinImage));
    diffMin = min(min(newDesinImage-oriDesinImage));
    
    %show the result
    sprintf('diff from two array max=%d, min=%d',diffMax,diffMin);
    
end


