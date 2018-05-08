% Top level code for testing basic AO registration algorithms
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

%% Name the project.
theProject = 'AOStimulation';

%% What to do
registerMethods = {'StripOverlappingOneLine'};
similarityMethod = 'NCC';
desinMovieMethods = {'Origin' 'simplification'};
COMPUTE = true;

%% Define working directories
%
% This counts on the preferences set up in the local
% hook file.  The local hook file is in the Configuration
% directory of the project, and will automatically be invoked
% by the tbUseProject('AOStimulation'), if you use ToolboxToolbox.
%
% If you don't use ToolboxToolbox, then run the template local
% hook by hand each time you want to work on this project.
movieBaseDir = getpref(theProject,'MovieBaseDir');
outputBaseDir = fullfile(getpref(theProject,'OutputBaseDir'),'deSinsoid');
if (~exist(outputBaseDir,'dir'))
    mkdir(outputBaseDir);
end

%% Define input directory and corresponding files
%
% Available files
%   NC_11002_20160405_OD_confocal_0116
%   NC_11002_20160405_OD_confocal_0136
%   NC_11002_20160405_OD_confocal_0128
%   NC_11002_20160405_OD_confocal_0133
%   NC_11002_20160405_OD_confocal_0124
testDirectoryName = 'NC_11002_20160405_OD_confocal_0116';
refImageName = '';
movieDir = fullfile(movieBaseDir,testDirectoryName);
rawMovieFile = fullfile(movieDir,[testDirectoryName '.avi']);
desinusoidedMovieFile = fullfile(movieDir,[testDirectoryName '_desinusoided.avi']);
referenceImageFile = fullfile(movieBaseDir,refImageName);
desinTransformFile = fullfile(movieDir,'desinusoid_matrix.mat');

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
% the counter increments. If the next sysPara.maxStripsAbnormalCount strips
% are less than sysPara.similarityThrSmall, we discard current frame.
sysPara.maxStripsAbnormalCount=2;

% Define search range. This limits the amount of searching that we have to
% do.
sysPara.searchRangeBigx = 140;
sysPara.searchRangeBigy = 140;
sysPara.searchRangeSmallx = 16;
sysPara.searchRangeSmally = 16;

% Define the stimulus position
sysPara.stimulusPositionx=210;
sysPara.stimulusPositiony=360;

% Timing parameters for the AOSLO clock frequency
sysPara.pixClkFreq = 20 * 10^6;
sysPara.pixTime = 10^9/sysPara.pixClkFreq;

% Horizontal scan paramters in pixels
sysPara.hrSync = 8;
sysPara.hrBackPorch = 115;
sysPara.hrActive = 512;
sysPara.hrFrontPorch = 664;

% Time per horizational line (unit ns)
sysPara.timePerLine = (sysPara.hrSync + sysPara.hrBackPorch...
    +sysPara.hrActive+sysPara.hrFrontPorch)...
    *sysPara.pixTime;


% Vertical / frame parameters in lines.
sysPara.vtSync = 10;
sysPara.vtBackPorch = 30;
sysPara.vtActive = 512;
sysPara.vtFrontPorch = 228;

% Time for vertical frame (unit ns)
sysPara.timePerFrame = (sysPara.vtSync + sysPara.vtBackPorch...
    +sysPara.vtActive+sysPara.vtFrontPorch)...
    *sysPara.timePerLine;

%% Step 1: Read the desinusoided movie
[rawMovie,imagePara] = aoReadMovie(rawMovieFile,maxMovieLength);
[nouse1,nouse2,actualMovieLength] = size(rawMovie);

%% Desinusoid verification
load(desinTransformFile);
[diffMax,diffMin,linePixelTimeTable,desinMovie,simpleDesinMovie] = aoDesinusoidVerification(vertical_fringes_desinusoid_matrix,rawMovie,maxMovieLength);


%Test different simliarity methods
%Initial
simi = [];

%Test loop. Currently, two methods are compared.
if (COMPUTE)
    for desinIndex = 1:length(desinMovieMethods)
        
        % Get methods
        desinMovieMethod = desinMovieMethods{desinIndex};
        outputName = sprintf('%s_%s',desinMovieMethod);
        outputDir = fullfile(outputBaseDir,testDirectoryName,outputName);
        if (~exist(outputDir,'dir'))
            mkdir(outputDir);
        end
        
        % Select test movie, the second iteration is for simplified desinsoid matrix
        if (desinIndex==2)
            desinMovie = simpleDesinMovie;
        end
        %% Step 2: Get reference image and set image size
        if (isempty(refImageName))
            refImage = desinMovie(:,:,1);
        else
            error('Need to write code to read a real reference image');
        end
        %Set the image size
        [imagePara.H,imagePara.W] = size(refImage);
        
        % Get methods
        [stripInfo,registeredMovie,status] = aoRegStripOverlappingOneLine(refImage,desinMovie,sysPara,imagePara, ...
            'SimilarityMethod',similarityMethod,'WhichFrame',whichFrame,'LineIncrement',lineIncrement);
        
        % Save the output of this method.  Name tracks which similarity method is
        % used.  Could add more parameters to name if there are key parameters we
        % want to vary and record output for.
        save(fullfile(outputDir,'testDesinData'),'stripInfo','actualMovieLength',...
            'registeredMovie','refImage','similarityMethod','desinMovie',...
            'sysPara','imagePara','desinMovieMethod','diffMax','diffMin','linePixelTimeTable');
    end
    
end

%% Analyze
for desinIndex = 1:length(desinMovieMethods)
           
        % Get methods and load the data
        desinMethod = desinMovieMethods{desinIndex};
        outputName = sprintf('%s_%s',desinMethod);
        outputDir = fullfile(outputBaseDir,testDirectoryName,outputName);
        theData = load(fullfile(outputDir,'testDesinData.mat'));
        
        % Analyze
        aoAnalyzeDesinData(theData,outputDir);
         
        %% Step 3: compute the time to stimulus position
        %predTime = aoTimePrediction(stripInfo,sysPara,maxMovieLength);
           
end

%calculate the runtime
t=toc;
fprintf('cpu time is %d', t);
