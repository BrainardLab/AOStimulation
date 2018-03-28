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
%system parameters
sysPara.stripSize = 8;
sysPara.blockSize = 8;

sysPara.ROIx = 16;
sysPara.ROIy = 16;
%desinusoider parameters
desinArray = [];
%image data parameters
MovieFile = 'D:\tyh\david\registration\mymatlab\data\NC_11002_20160405_OD_confocal_0116_desinusoided.avi';
refImageFile = "";
%step 1 read the movie and ref image
[refImage,desinMovies,imagePara] = aoRegDataIn(MovieFile,refImageFile);
%step 2 do desinusoider
%[desinMovies] = aoRegDesin(desinArray,rawMovies);
%step 3 do registration
%strip registration
%way 1: non overlap
%[regImage,status]=aoRegStrip(refImage,desinMovies,sysPara,imagePara);
%way 2: overlapping aoRegStripOverlapping
[regImage,status]=aoRegStripOverlappingOneLine(refImage,desinMovies,sysPara,imagePara);
%way 3: block registration
%[regImage,status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara);
%output result



