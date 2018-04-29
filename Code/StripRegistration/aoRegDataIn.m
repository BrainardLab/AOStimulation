function [rawMovies,imagePara] = aoRegDataIn(movieFile,maxMovieLength)
% Read in a movie acquired to do registration
%
% Syntax:
%    [rawMovies] = aoRegDataIn(movieFile,maxMovieLength)
%
% Description:
%    Read in a previously acquired movie and refernce frame that we have
%    stored.
%
%    But, reference frame part not yet implemented.  Just returns frame 1
%    of the movie as the reference frame.
%
%    And currently just returns first 4 frames of the movie.
%
% Inputs:
%    movieFile        - Full path to movie that we'll process.
%    maxMovieLength   - maximum frame number
%
% Outputs:
%    rawMovies        - Movies for futher processing
%    imagePara        - Image parameters, such as size, frame number, and
%                       so on
%
% Optional key/value pairs:
%    None.
%
% See also:
%

% History:
%   03/14/18  tyh

% Read avi file
video = VideoReader(movieFile);

% Get image parameters
imagePara.nFrames = maxMovieLength;
imagePara.H = video.Height;
imagePara.W = video.Width;

% Transfer image data into rawMovies, for simple test parpare 20 frame. the whole frame should be imagePara.nFrames
rawMovies(1:video.NumberOfFrames) = struct('cdata',zeros(imagePara.H,imagePara.W,3,'uint8'),'colormap',[]);
for i = 1:maxMovieLength
    rawMovies(i).cdata = read(video,i);
end




