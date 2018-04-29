% Top level code for testing basic AO registration algorithm
%
% Description:
%    This program is to verify the registration algorithm so that we can
%    transfer it to our FPGA platform.
%
%    This program includes desinusoider and registration. later we will do
%    fix-point analysis.
%

% History
%   03/14/18  tyh   

%% Clear out workspace
clear; close all; tic;

%% Define working directories
%
% This counts on the preferences set up in the local
% hook file.  The local hook file is in the Configuration
% directory of the project, and will automatically be invoked
% by the tbUseProject('AOStimulation'), if you use ToolboxToolbox.
%
% If you don't use ToolboxToolbox, then run the template local
% hook by hand each time you want to work on this project.
movieBaseDir = getpref(theApproach,'MovieBaseDir');
outputBaseDir = getpref(theApproach,'OutputBaseDir');  

%% Define input directory and corresponding files
%
% Available files
%   NC_11002_20160405_OD_confocal_0116_desinusoided
%   NC_11002_20160405_OD_confocal_0136_desinusoided
%   NC_11002_20160405_OD_confocal_0128_desinusoided
%   NC_11002_20160405_OD_confocal_0133_desinusoided
%   NC_11002_20160405_OD_confocal_0124_desinusoided
testName = 'NC_11002_20160405_OD_confocal_0116';
movieDir = fullfile(movieBaseDir,testName);
rawMovieFile = fullfile(movieDir,[testName '.avi']);
desinusoidedMovieFile = fullfile(movieDir,[testName '_desinusoided.avi']);
referenceImageFile = fullfile(movieBaseDir,'');
desinArrayFile = fullfile(movieDir,'desinusoid_matrix.mat');

% desinsoid array file
desinArrayFile = 'vertical_fringes_desinusoid_matrix.mat';

%% Choices
similarityMethod = 'NCC1';

% Which frame or frames to analyze. 0 means
% all frames.
whichFrame = 0;

% Truncate movie at most this length. 0 means
% do the whole movie.
maxMovieLength = 4;

% Strip increment information
%
% lineIncrement old lines are removed from the top of
% the previous strip and lineIncrement new lines are added to the bottom.
lineIncrement = 1;

%% System parameters
%
% stripSize - vertical size of registration strip in rows
% blockSize - size of square blocks in reference image that
%             we'll align incoming data to.
sysPara.stripSize = 8;
sysPara.blockSize = 8;

% Shrink image to search the necessary part, it may help improve the 
% similarity and reduce the computation cost.
sysPara.shrinkSize = 150;

% the threshold of similarity 
sysPara.similarityThrBig = 0.7;
sysPara.similarityThrSmall = 0.5;

% When strips search similairy is less than sysPara.similarityThrSmall,
% the counter plus 1. If the next sysPara.maxStripsAbnormalCount strips 
% are less than sysPara.similarityThrSmall, we discard current frame.
sysPara.maxStripsAbnormalCount=2;

% Define search range. This limits the
% amount of searching that we have to do.
sysPara.searchRangeBigx = 140;
sysPara.searchRangeBigy = 140;
sysPara.searchRangeSmallx = 16;
sysPara.searchRangeSmally = 16;

%define the stimulus position
sysPara.stimulusPositionx=210;
sysPara.stimulusPositiony=360;

%timing parameters for the AOSLO
%clock frequency
sysPara.pixClkFreq = 20 * 10^6;
sysPara.pixTime = 10^9/sysPara.pixClkFreq;

%horizontal paramters in pixels
sysPara.hrSync = 8;
sysPara.hrBackPorch = 115;
sysPara.hrActive = 512;
sysPara.hrFrontPorch = 664;

%time for very line (unit ns)
sysPara.timePerLine = (sysPara.hrSync + sysPara.hrBackPorch...
                      +sysPara.hrActive+sysPara.hrFrontPorch)...
                      *sysPara.pixTime;
                  

%vertical / frame parameters in lines.
sysPara.vtSync = 10;
sysPara.vtBackPorch = 30;
sysPara.vtActive = 512;
sysPara.vtFrontPorch = 228;
%time for very frame (unit ns)
sysPara.timePerFrame = (sysPara.vtSync + sysPara.vtBackPorch...
                      +sysPara.vtActive+sysPara.vtFrontPorch)...
                      *sysPara.timePerLine;


%% Desinusoider parameters. Not yet used.
desinArray = [];

%% Image data parameters.
%
% We'll test with a movie, and use one of its frames as the reference image
% for now.  Later, we may explicitly have a pre-computed reference image.

% Quick and dirty way to tell Hong and David's computers apart.  Will move
% to ToolboxToolbox someday for this. 
% test avi :

%% Step 1: Read the movie and ref image
[refImage,rawMovies,imagePara] = aoRegDataIn(desinusoidedMovieFile,referenceImageFile,maxMovieLength);
actualMovieLength = maxMovieLength;

%% Step 2
% Desinusoiding. 
load(desinArrayFile);
desinMovies = aoRegDesin(vertical_fringes_desinusoid_matrix,rawMovies,maxMovieLength);

%Currently set the first frame as ref image
refImage = desinMovies(:,:,1);

%Set the image size
[imagePara.H,imagePara.W] = size(refImage);

%% Step 3
%
% Do registration

% Method 1: No overlap between strips
%[regImage,status]=aoRegStrip(refImage,desinMovies,sysPara,imagePara);

% Method 2: Incremental line by line registration.
[stripInfo,registeredMovie,status] = aoRegStripOverlappingOneLine(refImage,desinMovies,sysPara,imagePara, ...
    'SimilarityMethod',similarityMethod,'WhichFrame',whichFrame,'LineIncrement',lineIncrement);

% Save the output of this method.  Name tracks which similarity method is
% used.  Could add more parameters to name if there are key parameters we
% want to vary and record output for.
outputDir = fullfile(outputBaseDir,sprintf('Incremental_%s',similarityMethod));
if (~exist(outputDir,'dir'))
    mkdir(outputDir);
end
save(fullfile(outputDir,'RegistrationResults',stripInfo,registeredMovie,status,refImage,desinMovies,sysPara,imagePara));


% Method 3: block registration
%[regImage,status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara);

%% Step 3: compute the time to stimulus position
predTime = aoTimePrediction(stripInfo,sysPara,maxMovieLength);

%% Analyze results
%
%  Initialize the total movement dx/dy
dxValuesTotal = [];
dyValuesTotal = [];

%Initialize all frames' similarity
bestSimilarityTotal = [];
     
% Make plots showing movement for each frame we analyzed
for ii = 1:actualMovieLength
    % Get movement data for this frame
    dxValues = [stripInfo(ii,:).dx];
    dxValuesTotal = [dxValuesTotal dxValues];
    dyValues = [stripInfo(ii,:).dy];
    dyValuesTotal = [dyValuesTotal dyValues];
    
    % Plot movement data
    figure; hold on
    plot(1:length(dxValues),dxValues,'ro','MarkerSize',8,'MarkerFaceColor','r');
    plot(1:length(dyValues),dyValues,'bo','MarkerSize',6,'MarkerFaceColor','b');
    ylim([-9*sysPara.searchRangeSmallx 9*sysPara.searchRangeSmallx]);
    ylabel('Displacement (pixels)')
    xlabel('Strip number');
    title(sprintf('Frame %d',ii));
    
    %report the matching result? CC value
    bestSimilarity = [stripInfo(ii,:).result];
    bestSimilarityTotal = [bestSimilarityTotal bestSimilarity];
    figure;
    plot(1:length(bestSimilarity),bestSimilarity,'ro','MarkerSize',6,'MarkerFaceColor','r');
    ylabel('Similarity')
    xlabel('Strip number');
    title(sprintf('Frame %d',ii));
    
    % Report largest strip-by-strip shifts
    maxLineDx = max(abs(diff(dxValues)));
    maxLineDy = max(abs(diff(dyValues)));
    fprintf('Frame %d, maximum dx difference: %d, maximum dy  difference: %d\n',ii,maxLineDx,maxLineDy);
    
    % Show the frame
    figure;
    subplot(1,2,1);
    imshow(refImage)
    title(sprintf('ref frame %d',1));
    subplot(1,2,2);
    imshow(registeredMovie(:,:,ii));
    title(sprintf('Registered frame %d',ii));
    
end

%plot the all frames' dy/dx
frame_length = length(dxValuesTotal)/actualMovieLength;

%figure for displacement
figure;hold on
for ii=1:actualMovieLength
    dxValues=dxValuesTotal(1+(ii-1)*frame_length:ii*frame_length);
    dyValues=dyValuesTotal(1+(ii-1)*frame_length:ii*frame_length);
    if (mod(ii,2)==0)
        plot(1+(ii-1)*frame_length:ii*frame_length,dxValues,'ro','MarkerSize',3,'MarkerFaceColor','r');
        plot(1+(ii-1)*frame_length:ii*frame_length,dyValues,'bo','MarkerSize',3,'MarkerFaceColor','b');
    else
        plot(1+(ii-1)*frame_length:ii*frame_length,dxValues,'go','MarkerSize',3,'MarkerFaceColor','g');
        plot(1+(ii-1)*frame_length:ii*frame_length,dyValues,'yo','MarkerSize',3,'MarkerFaceColor','y');
    end

%         plot(ii,dxValuesTotal(ii),'o','color',[bestSimilarityTotal(ii) 0 0],'MarkerFaceColor',[bestSimilarityTotal(ii) 0 0]);
%         plot(ii,dyValuesTotal(ii),'o','color',[0 0 bestSimilarityTotal(ii)],'MarkerFaceColor',[0 0 bestSimilarityTotal(ii)]);
    
    ylim([-9*sysPara.searchRangeSmallx 9*sysPara.searchRangeSmallx]);
end
ylabel('Displacement (pixels)')
xlabel('Strip number');
title(sprintf('All Frames displacement'));
hold off

% plot all similarity
figure;hold on
for ii=1:actualMovieLength
    bestSimilarity1=bestSimilarityTotal(1+(ii-1)*frame_length:ii*frame_length);
    if (mod(ii,2)==0)
        plot(1+(ii-1)*frame_length:ii*frame_length,bestSimilarity1,'ro','MarkerSize',3,'MarkerFaceColor','r');
    else
        plot(1+(ii-1)*frame_length:ii*frame_length,bestSimilarity1,'go','MarkerSize',3,'MarkerFaceColor','g');
    end
end
ylabel('Similarity')
xlabel('Strip number');
title(sprintf('All Frames Similiary'));
hold off

% Plot prediction time
figure;hold on
for ii=1:actualMovieLength
    if (mod(ii,2)==0)
        plot(predTime(:,ii),'ro','MarkerSize',3,'MarkerFaceColor','r');
    else
        plot(predTime(:,ii),'go','MarkerSize',3,'MarkerFaceColor','g');
    end
end
ylabel('Prediction Time')
xlabel('Strip number');
title(sprintf('Stimulus delivery estimation'));
hold off

%calculate the runtime
t=toc;
fprintf('cpu time is %d', t);