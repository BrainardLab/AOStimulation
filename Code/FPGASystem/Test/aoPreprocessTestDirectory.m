% Preprocess information in a test directory
%
% Description:
%    Preprocess the information in a test directory, to save time and
%    simplify the test program itself.
%
%    This script:
%       i) Extracts the reference frame and saves it in a .mat file, so we
%       can get that data later.
%
% See also:
%

% History
%   05/08/18  dhb, tyh  Wrote it.

%% Clear out workspace
clear; close all;

%% Name the project.
theProject = 'AOStimulation';

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

%% Define input directory and corresponding files
%
% Available files
%   NC_11002_20160405_OD_confocal_0116, reference frame is 83
%   NC_11002_20160405_OD_confocal_0136
%   NC_11002_20160405_OD_confocal_0128
%   NC_11002_20160405_OD_confocal_0133
%   NC_11002_20160405_OD_confocal_0124
testDirectoryName = 'NC_11002_20160405_OD_confocal_0116';
referenceFrame = 83;

refImageName = 'referenceImage';
movieDir = fullfile(movieBaseDir,testDirectoryName);
desinusoidedMovieFile = fullfile(movieDir,[testDirectoryName '_desinusoided.avi']);
refImageFile = fullfile(movieDir,refImageName);

%% Read the desinusoided movie
[desinMovie,imagePara] = aoReadMovie(desinusoidedMovieFile,0);
[nouse1,nouse2,actualMovieLength] = size(desinMovie);

%% Pull out and save reference image
refImage = desinMovie(:,:,referenceFrame);
save(refImageFile,'refImage');
