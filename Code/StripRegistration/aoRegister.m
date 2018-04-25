%% Top level code for basic AO registration algorithm
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


%Test case control
testCase.desinusoid = 1;
testCase.control = 0;
testcase.registration = 0;

%% Define working directories
%
% This differentiates David and Hong's computers.
if (ispc)
    movieBaseDir = '.\data\';
    if (testCase.desinusoid==1 )
        outputBaseDir = '.\data\TestOutput\desinusoid';
    elseif (testcase.registration==1)
        outputBaseDir = '.\data\TestOutput\registration';
    else
        outputBaseDir = '.\data\TestOutput\control';
    end
    refImageFile = "";
else
    movieBaseDir  = '/Volumes/Users1/Dropbox (Aguirre-Brainard Lab)/AOFN_data/AOFPGATestData/TestMovies';
    outputBaseDir = '/Volumes/Users1/Dropbox (Aguirre-Brainard Lab)/AOFN_data/AOFPGATestData/TestOutput';
end

%% Define movie file
%
% Available files
% NC_11002_20160405_OD_confocal_0116_desinusoided.avi
% NC_11002_20160405_OD_confocal_0136_desinusoided.avi
% NC_11002_20160405_OD_confocal_0128_desinusoided.avi
% NC_11002_20160405_OD_confocal_0133_desinusoided.avi
% NC_11002_20160405_OD_confocal_0124_desinusoided.avi
if (testCase.desinusoid == 1)
    movieFile = fullfile(movieBaseDir,...
        ['NC_11002_20160405_OD_confocal_0133\' 'NC_11002_20160405_OD_confocal_0133.avi']);
else
    movieFile = fullfile(movieBaseDir,...
        ['NC_11002_20160405_OD_confocal_0133\' 'NC_11002_20160405_OD_confocal_0133_desinusoided.avi']);
end
%refer image file
refImageFile = fullfile(movieBaseDir,'');

% desinsoid array file
desinArrayFile = 'vertical_fringes_desinusoid_matrix.mat';

%% Choices
similarityMethod = 'NCC1';

% Which frame or frames to analyze. 0 means
% all frames.
whichFrame = 0;

% Truncate movie at most this length. 0 means
% do the whole movie.
maxMovieLength = 2;

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
[refImage,desinMovies,imagePara] = aoRegDataIn(movieFile,refImageFile,maxMovieLength);
actualMovieLength = maxMovieLength;

%% Step 2
% Desinusoiding. 
if (testCase.desinusoid == 1)
load(desinArrayFile);
[diffMax,diffMin,linePixelTimeTable,desinMovies,simpleDesinMovies] = aoRegDesin(vertical_fringes_desinusoid_matrix,desinMovies,maxMovieLength);
end

%Test case: desinusoid
for testIdx = 1:2
    
    %Select test movie, the second iteration is for simplified desinsoid
    %matrix
    if (testIdx==2)
       desinMovies = simpleDesinMovies;
    end
    
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
    
    % Method 3: block registration
    %[regImage,status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara);
    
    %% Step 3: compute the time to stimulus position
    if (testCase.desinusoid == 0)
        predTime = aoTimePrediction(stripInfo,sysPara,maxMovieLength,linePixelTimeTable);
    else
        predTime = 0;
    end
    
    % Save the output of this method.  Name tracks which similarity method is
    % used.  Could add more parameters to name if there are key parameters we
    % want to vary and record output for.
    outputDir = fullfile(outputBaseDir,datestr(clock,30));
    if (~exist(outputDir,'dir'))
        mkdir(outputDir);
    end
    save(fullfile(outputDir,'testResults'),'stripInfo','registeredMovie','refImage','similarityMethod','desinMovies','sysPara','imagePara','diffMax','diffMin','predTime');
       
end

%% Test results output
% output file
outputFile = fullfile(outputBaseDir,[datestr(clock,30) '.txt']);
fid=fopen(outputFile,'w');
fprintf(fid,'similarityMethod = %s \n ',similarityMethod);
fprintf(fid,'maxMovieLength = %d \n ',maxMovieLength);
fprintf(fid,'lineIncrement = %d \n ',lineIncrement);
fprintf(fid,'sysPara.stripSize = %d \n ',sysPara.stripSize);
fprintf(fid,'sysPara.blockSize = %d \n ',sysPara.blockSize);
fprintf(fid,'sysPara.shrinkSize = %d \n ',sysPara.shrinkSize);
fprintf(fid,'sysPara.similarityThrBig = %d \n ',sysPara.similarityThrBig);
fprintf(fid,'sysPara.similarityThrSmall = %d \n ',sysPara.similarityThrSmall);
fprintf(fid,'sysPara.maxStripsAbnormalCount = %d \n ',sysPara.maxStripsAbnormalCount);
fprintf(fid,'sysPara.searchRangeBigx = %d \n ',sysPara.searchRangeBigx);
fprintf(fid,'sysPara.searchRangeBigy = %d \n ',sysPara.searchRangeBigy);
fprintf(fid,'sysPara.searchRangeSmallx = %d \n ',sysPara.searchRangeSmallx);
fprintf(fid,'sysPara.searchRangeSmally = %d \n ',sysPara.searchRangeSmally);
fprintf(fid,'sysPara.stimulusPositionx = %d \n ',sysPara.stimulusPositionx);
fprintf(fid,'sysPara.stimulusPositiony = %d \n ',sysPara.stimulusPositiony);
fclose(fid)


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
