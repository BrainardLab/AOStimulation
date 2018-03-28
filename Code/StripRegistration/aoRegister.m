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
clear; close all;

%% System parameters
%
% stripSize - vertical size of registration strip in rows
% blockSize - size of square blocks in reference image that
%             we'll align incoming data to.
sysPara.stripSize = 8;
sysPara.blockSize = 8;

% Define where we think the block might be. This limits the
% amount of searching that we have to do.
sysPara.ROIx = 16;
sysPara.ROIy = 16;

%% Desinusoider parameters. Not yet used.
desinArray = [];

%% Image data parameters.
%
% We'll test with a movie, and use one of its frames as the reference image
% for now.  Later, we may explicitly have a pre-computed reference image.

% Quick and dirty way to tell Hong and David's computers apart.  Will move
% to ToolboxToolbox someday for this.
if (ispc)
    movieFile = 'D:\tyh\david\registration\mymatlab\data\NC_11002_20160405_OD_confocal_0116_desinusoided.avi';
    refImageFile = "";
else
    movieFile = '/Volumes/Users1/Dropbox (Aguirre-Brainard Lab)/AOFN_data/AOFPGATestData/TestMovies/NC_11002_20160405_OD_confocal_0116_desinusoided.avi';
    refImageFile = "";
end

%% Step 1
% Read the movie and ref image
[refImage,desinMovies,imagePara] = aoRegDataIn(movieFile,refImageFile);
desinMovies = desinMovies(1);

%% Step 2
% Desinusoiding. Not yet implemented
%[desinMovies] = aoRegDesin(desinArray,rawMovies);

% Step 3
% Do registration

% Method 1: No overlap between strips
%strip registration
%way 1: non overlap
%[regImage,status]=aoRegStrip(refImage,desinMovies,sysPara,imagePara);

% Method 2: Incremental line by line registration.
%way 2: overlapping aoRegStripOverlapping
[regImage,status]=aoRegStripOverlappingOneLine(refImage,desinMovies,sysPara,imagePara);

% Method 3: block registration
%[regImage,status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara);


%% Analyze results
%output result



