function [theMovie,movieParams] = aoReadMovie(movieFile,maxMovieLength)
% Read in a movie
%
% Syntax:
%    [theMovie,movieParams] = aoReadMovie(movieFile,maxMovieLength)
%
% Description:
%    Read in a previously acquired movie and refernce frame that we have
%    stored.
%
%    But, reference frame part not yet implemented.  Just returns frame 1
%    of the movie as the reference frame.
%
% Inputs:
%    movieFile        - Full path to movie that we'll process.
%    maxMovieLength   - maximum frame number
%
% Outputs:
%    theMovie         - Movies for futher processing
%    movieParams      - Movie parameters, such as size of each frame and
%                       number of frames.
%
% Optional key/value pairs:
%    None.
%
% See also:
%

% History:
%   03/14/18  tyh

% Read avi file
videoR = VideoReader(movieFile);

% Get image parameters corresponding to the movie frames
movieParams.H = videoR.Height;
movieParams.W = videoR.Width;

% Transfer video data into rawMovies
nFrames = 1;
while (hasFrame(videoR))
    theMovie(:,:,nFrames) = readFrame(videoR);
    nFrames = nFrames + 1;
    if (maxMovieLength ~= 0 & nFrames > maxMovieLength)
        break;
    end
end
movieParams.nFrames = nFrames-1;





