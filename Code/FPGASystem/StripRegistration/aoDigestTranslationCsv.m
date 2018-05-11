%function aoDigestTranslationCsv(translationCsvFile)
% Read in a magic file that gives the alignment info from Alf's alignment
%
% Syntax:
%
% Description:
%    Alf's demotion software produces output that gives the row by row
%    estimates of shift.  Rob wrote a program that reads the python .dmp
%    file and produces a summary file of the translations.  We then read
%    this file in and process it to get the estimated eye position shifts
%    for each row in each frame.
%
% Inputs:
%    translationCsvFile       - String.  Filename of translation csf file.
%
% Outputs:
%
% Optional key/value pairs:
%
% See also:
%

% History:
%   05/09/18  dhb, rc, tyh  Started on it.

%% Name the project.
theProject = 'AOStimulation';

% hook by hand each time you want to work on this project.
movieBaseDir = getpref(theProject,'MovieBaseDir');

% Read file
%% Define input directory and corresponding files
%
% Available files
%   NC_11002_20160405_OD_confocal_0116
%   NC_11002_20160405_OD_confocal_0136
%   NC_11002_20160405_OD_confocal_0128
%   NC_11002_20160405_OD_confocal_0133
%   NC_11002_20160405_OD_confocal_0124
testDirectoryName = 'NC_11002_20160405_OD_confocal_0116';
movieDir = fullfile(movieBaseDir,testDirectoryName);

% Read ALF's output movie
movieFile = fullfile(movieDir,'NC_11002_20160405_OD_confocal_0116_ref_83_lps_8_lbss_8_sr_n_143_cropped_1.avi');

[theMovie,movieParams] = aoReadMovie(movieFile,0);

% Get the size of the movie
[s1,s2,s3] = size(theMovie);

% Pick up one frame
imagePick = theMovie(:,:,1);

% Find the valid image size
flagFirst = 0;
for i=2:s1
    for j=2:s2
        if (imagePick(i,j)>0 && (flagFirst == 0))
            firstPoint = [i,j];
            flagFirst = 1;
        end
        if (imagePick(i,j)>0)
            lastPoint = [i,j];
            
        end
    end
end

imageSize = lastPoint - firstPoint;

% Define the CSV file 
csvFile = fullfile(movieDir,'NC_11002_20160405_OD_confocal_0116_ref_83_lps_8_lbss_8_transforms.csv');

% Read the CSV file
csvData1 = csvread(csvFile);

% Pick up the frames
csvData = csvData1(5:end,:);

% Size the data
[h,w] = size(csvData);
w=w-1;

% Get the total number of frame in the data
nFrame = h/3;

% Sort  the frame in order to compare with our methods
% Frame loop
for i=1:nFrame
    
    % Get the frame index
    frameIdx = csvData(1+(i-1)*3,1);
    
    % Get the base move
    globalMove(1+fix(i/3)) = csvData(1+(i-1)*3,2);
    
    % Get the displacement
    xDisplacement = csvData(2+(i-1)*3,2:end);
    yDisplacement = globalMove(1+fix(i/3)) + csvData(3+(i-1)*3,2:end);
    
    % Sort the frames
    xDisplacementFrame(:,frameIdx) = xDisplacement;
    yDisplacementFrame(:,frameIdx) = yDisplacement;
    
end

% Analyze the CSV result
numberOfFrame = nFrame;
%numberOfFrame = 1;

% Vasualize the result
figure;hold on

% Frame loop for x-direction displacment
for i=1:numberOfFrame
    
    % Plot
    if (mod(i,2)==0)
        plot(1+(i-1)*w:i*w,xDisplacementFrame(:,i),'ro','MarkerSize',2,'MarkerFaceColor','r');
    else
        plot(1+(i-1)*w:i*w,xDisplacementFrame(:,i),'go','MarkerSize',2,'MarkerFaceColor','g');
    end
    
    % Limit y axis
    ylim([-150 150]);
end
ylabel('Displacement')
xlabel('line number');
title(sprintf('col(x) displacement'));
hold off

%
figure;hold on

% Frame loop for y-direction
for i=1:numberOfFrame
    
    % Plot
    if (mod(i,2)==0)
        plot(1+(i-1)*w:i*w,yDisplacementFrame(:,i),'ro','MarkerSize',2,'MarkerFaceColor','r');
    else
        plot(1+(i-1)*w:i*w,yDisplacementFrame(:,i),'go','MarkerSize',2,'MarkerFaceColor','g');
    end
    
    % Limit y axis
    ylim([-150 150]);
end
ylabel('Displacement')
xlabel('line number');
title(sprintf('row(y) displacement'));
hold off
