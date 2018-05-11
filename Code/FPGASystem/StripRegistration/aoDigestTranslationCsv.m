function [eyePositionX,eyePositionY] = aoDigestTranslationCsv(translationCsvFile)
% Read in a magic file that gives the alignment info from Alf's alignment
%
% Syntax:
%    [eyePositionX,eyePositionY] = aoDigestTranslationCsv(translationCsvFile)
%
% Description:
%    Alf's demotion software produces output that gives the row by row
%    estimates of shift.  Rob wrote a program that reads the python .dmp
%    file and produces a summary file of the translations.  We then read
%    this file in and process it to get the estimated eye position shifts
%    for each row in each frame.
%
% Inputs:
%    translationCsvFile       - String.  Full path to translation csv file
%
% Outputs:
%
% Optional key/value pairs:
%
% See also:
%

% History:
%   05/09/18  dhb, rc, tyh  Started on it.

% Examples:
%{
    theTestFile = '/NC_11002_20160405_OD_confocal_0116/NC_11002_20160405_OD_confocal_0116_ref_83_lps_8_lbss_8_sr_n_143_cropped_1_transforms.csv');
    aoDigestTranslationCsv(theTestFile);
%}

%% Define the CSV file
csvFile = fullfile(translationCsvFile);

%% Read the CSV file
rawData = csvread(csvFile);

%% Get size of aligned movie workspace
alignedMovieRows = rawData(1,2);
alignedMovieCols = rawData(1,4);

%% Get frame by frame data.
% Comes in groups of three lines per frame
%
% Each column of the data is about one row in the input image.
% Not all rows are aligned, though, and actual number varies
% frame by frame.
frameNumberData = rawData(2:end,1);
frameData = rawData(2:end,2:end);
[h,w] = size(frameData);
if (rem(h,3) ~= 0)
    error('Something unexpected in csv file format');
end
nFrames = h/3;
maxImageRows = w;

%% Sort  the frames in order to compare with our methods
%
% Frame loop
for ii = 1:nFrames
    % Get index into the first row for the frame
    frameStartRowIndex = 1+(ii-1)*3;
    frameNumber = frameNumberData(frameStartRowIndex);
    
    % Toss out zeros at end of each row
    theFrameYGlobalOffsetData = frameData(frameStartRowIndex,:);
    temp = theFrameYGlobalOffsetData(end);
    while (temp == 0)
        theFrameYGlobalOffsetData = theFrameYGlobalOffsetData(1:end-1);
        temp = theFrameYGlobalOffsetData(end);
    end
    nAlignedLines = length(theFrameYGlobalOffsetData);
    theFrameXOffsetData = frameData(frameStartRowIndex+1,1:nAlignedLines);
    theFrameYOffsetData = frameData(frameStartRowIndex+2,1:nAlignedLines);
    
    % Check that they really are sequential for each frame
    if (any(diff(theFrameYGlobalOffsetData) ~= 1))
        fprintf('A line is skipeed for frame %d\n',ii);
    end
    
    % Get eye position for every aligned line
    previousGlobalOffset = theFrameYGlobalOffsetData(1)-1;
    currentLine = 1;
    for jj = 1:nAlignedLines
        currentGlobalOffset = theFrameYGlobalOffsetData(jj);
        while (currentGlobalOffset < previousGlobalOffset + 1)
            eyePositionY(ii,currentLine) = NaN;
            eyePositionX(ii,currentLine) = NaN;
            currentLine = currentLine + 1;
            currentGlobalOffset = currentGlobalOffset + 1;
            fprintf('Skipping a line\n');
        end
        
        eyePositionY(ii,currentLine) = theFrameYOffsetData(jj) - currentGlobalOffset;
        eyePositionX(ii,currentLine) = theFrameXOffsetData(jj);
        previousGlobalOffset = currentGlobalOffset;
    end
end

