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
clear; close all;tic;

%% Choices
similarityMethod = 'NCC';

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

% Define where we think the block might be. This limits the
% amount of searching that we have to do.
sysPara.searchRangeBigx = 140;
sysPara.searchRangeBigy = 140;
sysPara.searchRangeSmallx = 16;
sysPara.searchRangeSmally = 16;

%% Desinusoider parameters. Not yet used.
desinArray = [];

%% Image data parameters.
%
% We'll test with a movie, and use one of its frames as the reference image
% for now.  Later, we may explicitly have a pre-computed reference image.

% Quick and dirty way to tell Hong and David's computers apart.  Will move
% to ToolboxToolbox someday for this. 
% test avi :
% NC_11002_20160405_OD_confocal_0116_desinusoided.avi
% NC_11002_20160405_OD_confocal_0124_desinusoided.avi
if (ispc)
    movieFile = '.\data\NC_11002_20160405_OD_confocal_0116_desinusoided.avi';
    refImageFile = "";
else
    movieFile = '/Volumes/Users1/Dropbox (Aguirre-Brainard Lab)/AOFN_data/AOFPGATestData/TestMovies/NC_11002_20160405_OD_confocal_0116_desinusoided.avi';
    refImageFile = "";
end

%% Step 1
% Read the movie and ref image
[refImage,desinMovies,imagePara] = aoRegDataIn(movieFile,refImageFile,maxMovieLength);
if (maxMovieLength > 0 & length(desinMovies) > maxMovieLength)
    desinMovies = desinMovies(1:maxMovieLength);
end
actualMovieLength = length(desinMovies);

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
[stripInfo,registeredMovie,status] = aoRegStripOverlappingOneLine(refImage,desinMovies,sysPara,imagePara, ...
    'SimilarityMethod',similarityMethod,'WhichFrame',whichFrame,'LineIncrement',lineIncrement);

% Method 3: block registration
%[regImage,status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara);


%% Analyze results
% figure; imshow(refImage);
% keep refImage center area for better comparison .
centerWidth = imagePara.W-2*sysPara.shrinkSize;
centerHeight = imagePara.H-2*sysPara.shrinkSize;
refImage1 = uint8((zeros(imagePara.H,imagePara.W)));
refImage1((sysPara.shrinkSize+1):(sysPara.shrinkSize+centerHeight)...
         ,(sysPara.shrinkSize+1):(sysPara.shrinkSize+centerWidth) ...
         ) = refImage((sysPara.shrinkSize+1):(sysPara.shrinkSize+centerHeight) ...
         ,(sysPara.shrinkSize+1):(sysPara.shrinkSize+centerWidth) ...
         );
 % Make plots showing movement for each frame we analyzed
 for ii = 1:actualMovieLength
     % Get movement data for this frame
     dxValues = [stripInfo(ii,:).dx];
     dyValues = [stripInfo(ii,:).dy];
     
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
     %imshow(desinMovies(ii).cdata);
     imshow(refImage)
     title(sprintf('ref frame %d',1));
     subplot(1,2,2);
     imshow(registeredMovie(:,:,ii));
     title(sprintf('Registered frame %d',ii));

 end

t=toc;
fprintf('cpu time is %d', t);
