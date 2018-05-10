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
clear; close all;

%% Start timing
tic;
   
%% Name the project.
theProject = 'AOStimulation';

%% What to do
registerMethods = {'StripOverlappingOneLine'};
similarityMethods = {'NCC', 'NCC1'};
%similarityMethods = {'NCC'};
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
outputBaseDir = fullfile(getpref(theProject,'OutputBaseDir'),'Registration');

% Change the output to Dropbox
outputBaseDir = fullfile('C:\Users\yhtian\Dropbox (Aguirre-Brainard Lab)\AOFN_Data\AOFPGATestData\TestOutput','Registration');

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
refImageName = 'referenceImage';
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
maxMovieLength = 120;

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

% Timing parameters for the AOSLO
sysPara.aoTimingPara = aoTimingParametersGen;

%% Step 1: Read the desinusoided movie
[desinMovie,imagePara] = aoReadMovie(desinusoidedMovieFile,maxMovieLength);
[nouse1,nouse2,actualMovieLength] = size(desinMovie);

%% Step 2: Get reference image and set image size
if (isempty(refImageName))
    refImage = desinMovie(:,:,1);
else
    refImageLoaded = load(fullfile(movieDir,refImageName));
    refImage = refImageLoaded.refImage;
    clear refImageLoaded;
end
[tempH,tempW] = size(refImage);
if (tempH ~= imagePara.H)
    error('Ref image height not equal to movie height');
end
if (tempW ~= imagePara.W)
    error('Ref image width not equal to movie width');
end

%% Loop over methods
%
% These are specified in cell arrays registerMethods and similarityMethods.
if (COMPUTE)
    for registerIndex = 1:length(registerMethods)
        for similarityIndex = 1:length(similarityMethods)
            
            % Get method
            registerMethod = registerMethods{registerIndex};
            similarityMethod = similarityMethods{similarityIndex};
            outputName = sprintf('%s_%s',registerMethod,similarityMethod);
            outputDir = fullfile(outputBaseDir,testDirectoryName,outputName);
            if (~exist(outputDir,'dir'))
                mkdir(outputDir);
            end
            
            % Do registration
            switch (registerMethod)
                case 'StripOverlappingOneLine'
                    % Incremental line by line registration.
                    [stripInfo,registeredMovie,status] = aoRegStripOverlappingOneLine(refImage,desinMovie,sysPara,imagePara, ...
                        'SimilarityMethod',similarityMethod,'WhichFrame',whichFrame,'LineIncrement',lineIncrement);
                case 'Strip'
                    %[regImage,status]=aoRegStrip(refImage,desinMovies,sysPara,imagePara);
                    error('Either update or delete aoRegStrip');
                otherwise
                    error('Unknown registration method specified');
            end
            
            % Save the output of this method.  Name tracks which similarity method is
            % used.  Could add more parameters to name if there are key parameters we
            % want to vary and record output for.
            save(fullfile(outputDir,'testRegisterData'),'stripInfo','actualMovieLength',...
                'registeredMovie','refImage','similarityMethod','desinMovie',...
                'sysPara','imagePara');
        end
    end
end

%% Analyze
for registerIndex = 1:length(registerMethods)
    for similarityIndex = 1:length(similarityMethods)
        
        % Get methods and load the data
        registerMethod = registerMethods{registerIndex};
        similarityMethod = similarityMethods{similarityIndex};
        outputName = sprintf('%s_%s',registerMethod,similarityMethod);
        outputDir = fullfile(outputBaseDir,testDirectoryName,outputName);
        theData = load(fullfile(outputDir,'testRegisterData.mat'));
        
        % Analyze
        aoAnalyzeRegisterData(theData,outputDir);
        
        %% Step 3: compute the time to stimulus position
        %predTime = aoTimePrediction(stripInfo,sysPara,maxMovieLength);
    
    end
end

%% Calculate and report how long this took
t=toc;
fprintf('Running tests took %d seconds\n', t);
