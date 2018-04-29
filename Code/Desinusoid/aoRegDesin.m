function [desinMovies] = aoRegDesin(desinMatrix,rawMovies,maxMovieLength)
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
%    desinMatrix        - original desinsoid array.
%    rawMovies          - raw movies.
%    maxMovieLength     - maximum frame number
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
[s1,s2] = size(desinMatrix);

%Initial the array
desinArray1=zeros(s1,s2);

% Loop line by line
for i=1:s1
    
    %Sort the current line
    [sortVaule sortIdx] = sort(desinMatrix(i,:));
    
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
    desinArray1(i,selectP0Idx) = desinMatrix(i,selectP0Idx);
    desinArray1(i,selectP1Idx) = desinMatrix(i,selectP1Idx);
    desinArray1(i,selectP2Idx) = desinMatrix(i,selectP2Idx);
    desinArray1(i,selectP3Idx) = desinMatrix(i,selectP3Idx);
    desinArray1(i,selectP4Idx) = desinMatrix(i,selectP4Idx);
    desinArray1(i,selectP5Idx) = desinMatrix(i,selectP5Idx);   
end

%frame loop
for frameIdx=1:maxMovieLength
    %Get the current raw image to desinsoid    
    rawImage = double(rawMovies(frameIdx).cdata);
    
    %For test, get the desinsoid movie by the original array
    oriDesinImage = uint8(fix(rawImage * desinMatrix'));
    
    %Get the desinsoid movie by the simplified array
    newDesinImage = uint8(fix(rawImage * desinArray1'));
    
    %
    desinMovies(:,:,frameIdx) = newDesinImage;
    
    %Get the different result by the two array
    diffMax = max(max(newDesinImage-oriDesinImage));
    diffMin = min(min(newDesinImage-oriDesinImage));
    
    %show the result
    fprintf('diff from two array max=%d, min=%d\n',diffMax,diffMin);
    
end


%% Figure out times from the matrix
%
% Set up a linear fictional signal ramp in the raw input
% domain.  We know that the raw pixel samples happen at
% equally spaced times (just not equally spaced positions).
%
% Later we will put in real signal times based on calculating
% them from the system timing parameters.  Now they are just
% made up.
testSlope = 10;
testTimes = (0:(size(desinMatrix,2)-1))';
testSignal = 10*testTimes;

% Desinusoid the signal ramp.  This gives us
% a desinusoided ramp that is very close to linear.
testSignalDesin = desinMatrix*testSignal;

% We want to find the time at which the fictional input
% signal is as close as possible to the value for each
% desinusoided sample.  Because we constructed the fictional
% signal to be monotonically increasing, we can also construct
% a version of it on a much more finely sample time axis (in
% the input time space).
%
% Create that finely sampled input signal
% Interpolate to find the time of each desinusoided
% sample.  Note that the total time base corresponds
% to that of the sampled input signal
nFineSamples = 100000;
fineTestTimes = linspace(0,(size(desinMatrix,2)-1),nFineSamples);
fineTestSignal = testSlope*fineTestTimes;

% For each desinusoided signal value, find the time at which
% the finely sampled input signal had the same value.  This
% gives us the time corresponding to the desinusoided sample.
for ii = 1:length(testSignalDesin)
    [~,fineIndex] = min(abs(fineTestSignal-testSignalDesin(ii)));
    testDesinTimes(ii) = fineTestTimes(fineIndex);
    
    [~,nearestRawIndex(ii)] = min(abs(testTimes-testDesinTimes(ii)));
end

% Make a plot on a common time axis
figure; clf; hold on
plot(testTimes,testSignal,'r','LineWidth',4);
plot(testDesinTimes,testSignalDesin,'go','MarkerSize',2,'MarkerFaceColor','g');   

% Let's make sure our calculation is consistent with the sinusoidal
% behavior of the scan.  The spatial position of each desinuosided
% sample is proporitional to the time at which it was acquired.  So plot
% the desinsoided sample times against the sample numbers
figure; clf; 
plot(1:length(testDesinTimes),testDesinTimes,'go','MarkerSize',2,'MarkerFaceColor','g');
subplot(1,2,2); hold on

figure; clf; hold on
plot(testDesinTimes,testTimes(nearestRawIndex),'go','MarkerSize',2,'MarkerFaceColor','g'); 
plot([0 800],[0 800]);

% Nearest neighbor desinusoiding
%frame loop
for frameIdx=1:maxMovieLength
    %Get the current raw image to desinsoid    
    rawImage = double(rawMovies(frameIdx).cdata);
    
    %For test, get the desinsoid movie by the original array
    oriDesinImage = uint8(fix(rawImage * desinMatrix'));
    
    %Get the desinsoid movie by the simplified array
    for kk = 1:size(rawImage,1)
        nearestDesinImage(kk,:) = uint8(fix(rawImage(kk,nearestRawIndex)));
    end
    
    %
    nearestDesinMovies(:,:,frameIdx) = nearestDesinImage;
    
    figure; clf; 
    subplot(1,2,1);
    imshow(oriDesinImage);
    subplot(1,2,2);
    imshow(nearestDesinImage)
    
    %Get the different result by the two array
    diffMaxNearest = max(max(nearestDesinImage-oriDesinImage));
    diffMinNearest = min(min(nearestDesinImage-oriDesinImage));
    
    %show the result
    fprintf('diff from two array (nearest) max=%d, min=%d\n',diffMaxNearest,diffMinNearest); 
end

disp hellow






