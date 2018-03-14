function movie = aoemReadMovieForPlayback(movieFileName,emulatorParams,sampleParas,varargin)
% Read in a movie acquired on the real AOSLO for us to play back
%
% Syntax:
%    movie = aoemReadMovieForPlayback(movieFileName,emulatorParams,sampleParas)
%
% Description:
%    Read in a previously acquired movie that we have stored, and put it
%    into a form to play back.
%
%    Right now we just use one frame for testing, so this reads a movie and not
%    an image. The image should be in a format that imread can handle.
%
% Inputs:
%    movieFileNane      - Full path to movie that we'll emulate.
%    emulatorParams     - Emulator parameters
%    sampleParas        - Sampling points.
%
% Outputs:
%    movie              - One frame of a "movie", converted into a time series
%                         row vector.
%
% Optional key/value pairs:
%    'inputType'        - What type of input will be read.  String.  Default,
%                        'image'.  Options:
%                           'image'   - Read an image, treat this as one frame.
%                           'movie'   - Read a movie.  Pass back multiple frames.
%                                       Not yet implemented.
%    'verbose'          - Boolean. True means print out information, false
%                         means run silent. Default true.
%
% See also:

% History:
%   02/02/18  tyh, dhb   Wrote header comments.

% Parse inputs
p = inputParser;
p.KeepUnmatched = false;
p.addRequired('movieFileName',@isstring);
p.addRequired('emulatorParams',@isstruct);
p.addRequired('sampleParas',@isstruct);
p.addParameter('inputType','image', @isstring);
p.addParameter('verbose',true, @islogical);
p.parse('movieFileName','emulatorParams','sampleParas',varargin{:});

%% Read in the frames
switch (p.Results.inputType)
    case 'movie'
        error('Movies not yet implemented');
        % Codelet we may want when we actually read a movie
        %
        % video = VideoReader(movieFileName);
        % nFrames = video.NumberOfFrames;   %frame number
        % H = video.Height;
        % W = video.Width;
        % %%%Rate = video.FrameRate;
        % %%% Preallocate movie structure.
        % mov(1:nFrames) = struct('cdata',zeros(H,W,3,'uint8'),'colormap',[]);
        % mov(2).cdata = read(video,2);
        % P = mov(2).cdata;
        
    case 'image'
        % Read in an image.  It must be at least as large as emulated height and
        % width. If it is bigger, it is cropped.
        H = emulatorParams.height;
        W = emulatorParams.width;
        P = imread(movieFileName);
        P = rgb2gray(P);
        P = P(1:H,1:W);
        if (p.Results.verbose)
            imshow(P);
        end
    otherwise
        error('Unknown input type passed');
end

%%%%%%%%%%%%%%%%%%
% HONG - Please add some high level comments that say what is happening in
% each following block of code.
%%%%%%%%%%%%%%%%%%

%our scan array is emulatorParams.vt_pixels * emulatorParams.hr_pixels, active image is in the
%middle (emulatorParams.vt_active_pixels * emulatorParams.hr_active_pixels)
% active_col_start = emulatorParams.hr_sync_pixels+emulatorParams.hr_back_porch_pixels+1;
% active_col_end = emulatorParams.hr_sync_pixels+emulatorParams.hr_back_porch_pixels+emulatorParams.hr_active_pixels;
% active_row_start = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+1;
% active_row_end = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+emulatorParams.vt_active_pixels;
active_col_start = sampleParas.hr_sync_points+sampleParas.hr_back_porch_points+1;
active_col_end = sampleParas.hr_sync_points+sampleParas.hr_back_porch_points+sampleParas.hr_active_points;
active_row_start = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+1;
active_row_end = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+emulatorParams.vt_active_pixels;


movie_frame_array = zeros(emulatorParams.vt_pixels,sampleParas.hr_line_points);
temp_x=1;
temp_y=1;
%col_offset1 = 420;  %first edge
col_offset1 = 0; %610; %first edge,610 is good.
col_offset = 1615; %second edge
half_line =fix((active_col_end - active_col_start)/2) ;
for i = active_row_start : active_row_end
    
    %for j = active_col_start+420 : (active_col_start+420+360-1)
    %for j = active_col_start+col_offset : (active_col_start+col_offset+360-1) %%???????
    %for j = active_col_start+col_offset1 : (active_col_start+col_offset1+half_line-1)
    for j = active_col_start : active_col_end
        %temp_y1=min(1+2*(temp_y-1),W);  %2 downsampling
        %temp_x1 = min(1+2*(temp_x-1),H); %2 downsampling
        temp_y1 = min(temp_y,W);
        temp_x1 = min(temp_x,H);
        movie_frame_array(i,j) = 200; % P(temp_x1,temp_y1);
        temp_y = temp_y+1;
    end
    temp_y = 1;
    
    %         for j = active_col_start+1610 : (active_col_start+1610+440-1)
    %             temp_y1=min(1+2*(temp_y-1),W);
    %             temp_x1 = min(1+2*(temp_x-1),H);
    %             movie_frame_array(i,j) = P(temp_x1,temp_y1);
    %             temp_y = temp_y+1;
    %         end
    %            temp_y = 1;
    
    temp_x = temp_x +1;
    
end

%movie_frame_array = 200 * ones(emulatorParams.vt_pixels,sampleParas.hr_line_points);

movie_frame_seq = reshape(movie_frame_array',1,emulatorParams.vt_pixels * sampleParas.hr_line_points);
movie = movie_frame_seq*2^5;