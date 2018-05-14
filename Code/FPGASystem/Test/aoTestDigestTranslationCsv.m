% Test our routine for reading a translation csv file.
%
% Description:
%    The Demotion software does strip registration, and it is possible
%    to get information about what it has done.  We can read that
%    information from a csv file, which we store in the same directory
%    as the input and aligned movies.
%
%    This program tests our ability to read and make sense of the 
%    csv file.
%
% See also: aoDigestTranslationCsv
%

% History:
%  05/10/18 tyh        Started on this.
%  05/11/18 tyh, dhb   Moved into its own test script.

%% Name the project.
theProject = 'AOStimulation';

%% Get pointer to to movie base directory, where things live.
% This is set up by tbUseProject('AOStimulation');
movieBaseDir = getpref(theProject,'MovieBaseDir');

%% Read input movie file, and the corresponding demotion output
% Define input directory and corresponding files
%
% Available files
%   NC_11002_20160405_OD_confocal_0116, ref_83_lps_8_lbss_8_sr_n_143_cropped_1
testDirectoryName = 'NC_11002_20160405_OD_confocal_0116';
alignedMovieSuffix = 'ref_83_lps_8_lbss_8_sr_n_143_cropped_1';

% Read aligned movie
movieDir = fullfile(movieBaseDir,testDirectoryName);

% Read aligned movie
[alignedMovie,alignedMovieParams] = aoReadMovie(fullfile(movieDir,[testDirectoryName '_' alignedMovieSuffix '.avi']),2);

% Read translation csv file
translationCsvFile = fullfile(movieDir,[testDirectoryName '_' alignedMovieSuffix '_transforms.csv']);
[rawData,eyePositionX,eyePositionY] = aoDigestTranslationCsv(translationCsvFile);

% Get the size of the movie
[s1,s2,s3] = size(alignedMovie);

% Pick up one frame
imagePick = alignedMovie(:,:,1);

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

%% 
frameData = rawData(2:end,:);
[h,w] = size(frameData);
if (rem(h,3) ~= 0)
    error('Something unexpected in csv file format');
end
nFrames = h/3;

% Sort to the frames
for ii=1:nFrames
    
    % Get frame index from the data
    frameIdx = frameData(1+(ii-1)*3,1);
    
    % Get the base move
    globalMove(1+fix(ii/3)) = frameData(1+(ii-1)*3,2);
    
    % Get the displacement
    xDisplacement = frameData(2+(ii-1)*3,2:end);
    yDisplacement = frameData(3+(ii-1)*3,2:end) + globalMove(1+fix(ii/3));
    
    % Sort the frames
    xDisplacementFrame(:,frameIdx) = xDisplacement;
    yDisplacementFrame(:,frameIdx) = yDisplacement;
    
end

% Analyze the CSV result
%numberOfFrame = nFrames;
numberOfFrame = 1;
maxImageRows = w -1;

% Vasualize the result
figure;hold on

% Frame loop for x-direction displacment
for ii=1:numberOfFrame
    
    % Plot
    if (mod(ii,2)==0)
        plot(1+(ii-1)*maxImageRows:ii*maxImageRows,xDisplacementFrame(:,ii),'ro','MarkerSize',2,'MarkerFaceColor','r');
    else
        plot(1+(ii-1)*maxImageRows:ii*maxImageRows,xDisplacementFrame(:,ii),'go','MarkerSize',2,'MarkerFaceColor','g');
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
for ii=1:numberOfFrame
    
    % Plot
    if (mod(ii,2)==0)
        plot(1+(ii-1)*maxImageRows:ii*maxImageRows,yDisplacementFrame(:,ii),'ro','MarkerSize',2,'MarkerFaceColor','r');
    else
        plot(1+(ii-1)*maxImageRows:ii*maxImageRows,yDisplacementFrame(:,ii),'go','MarkerSize',2,'MarkerFaceColor','g');
    end
    
    % Limit y axis
    ylim([-150 150]);
end
ylabel('Displacement')
xlabel('line number');
title(sprintf('row(y) displacement'));
hold off
