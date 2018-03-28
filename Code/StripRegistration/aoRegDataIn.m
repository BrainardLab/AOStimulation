function [refImage,rawMovies,imagePara] = aoRegDataIn(MovieFile,refImageFile)
% Read in a movie acquired to do registration
%
% Syntax:
%    [refImage,rawMovies] = aoRegDataIn(MovieFile,refImageFile)
%
% Description:
%    Read in a previously acquired movie that we have stored
%
%
% Inputs:
%    MovieFile        - Full path to movie that we'll process.
%    refImageFile     - Full path to reference image to be alignmented.
% 
% Outputs:
%    refImage         - Ref frame, used to registration.
%    rawMovies        - Movies for futher processing
%    imagePara        - Image parameters, such as size, frame number, and
%    so on
% Optional key/value pairs:
%    None.
%
% See also:

% History:
%   03/14/18  tyh

%%-------------------------------------
%read avi file
video = VideoReader(MovieFile); 
%get image parameters
imagePara.nFrames = video.NumberOfFrames;   %frame number
imagePara.H = video.Height;     
imagePara.W = video.Width;  
%%%Rate = video.FrameRate;
%%% get the ref image. currently, I pick it ramdonly.
rawMovies(1:imagePara.nFrames) = struct('cdata',zeros(imagePara.H,imagePara.W,3,'uint8'),'colormap',[]);
%transfer image data into rawMovies, for simple test parpare 20 frame. the whole frame should be imagePara.nFrames
for i = 1: 4
rawMovies(i).cdata = read(video,i);
end
refImage = rawMovies(2).cdata;

