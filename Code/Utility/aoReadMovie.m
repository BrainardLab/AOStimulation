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
%    And currently just returns first 4 frames of the movie.
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
video = VideoReader(movieFile);

% Get image parameters corresponding to the movie frames
movieParams.nFrames = maxMovieLength;
movieParams.H = video.Height;
movieParams.W = video.Width;

% Transfer video data into rawMovies
theMovie(1:movieParams.nFrames) = struct('cdata',zeros(movieParams.H,movieParams.W,'uint8'));
for i = 1:maxMovieLength
    theMovie(i).cdata = readFrame(video);
end




