function movie = aoemReadMoveForPlayback(movieFileName,emulatorParams)
% Read in a movie acquired on the real AOSLO for us to play back
%
% Syntax:
%    movie = aoemReadMoveForPlayback(movieFileName,emulatorParams)
% Description:
%    Read in a previously acquired movie that we have stored, and put it
%    into a form to play back.
%
% Get the input movie. Right now we just use one frame for test
% Inputs:
%    movieFileName    - the name of the movie  
%    emulatorParams    - emulator parameters
% 
% Outputs:
%    movie      - one x N array  
% Optional key/value pairs:
%    None.
%
% See also:
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.

video = VideoReader(movieFileName); 
nFrames = video.NumberOfFrames;   %frame number
H = video.Height;     
W = video.Width;      
%Rate = video.FrameRate;
% Preallocate movie structure.
mov(1:nFrames) = struct('cdata',zeros(H,W,3,'uint8'),'colormap',[]);
mov(2).cdata = read(video,2);
P = mov(2).cdata;
%our scan array is emulatorParams.vt_pixels * emulatorParams.hr_pixels, active image is in the
%middle (emulatorParams.vt_active_pixels * emulatorParams.hr_active_pixels)
active_col_start = emulatorParams.hr_sync_pixels+emulatorParams.hr_back_porch_pixels+1;
active_col_end = emulatorParams.hr_sync_pixels+emulatorParams.hr_back_porch_pixels+emulatorParams.hr_active_pixels;
active_row_start = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+1;
active_row_end = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+emulatorParams.vt_active_pixels;

movie_frame_array = zeros(emulatorParams.vt_pixels,emulatorParams.hr_pixels);
temp_x=1;
temp_y=1;
for i = active_row_start : active_row_end
    for j = active_col_start : active_col_end
        
        movie_frame_array(i,j) = P(temp_x,temp_y);
        temp_y = temp_y+1;
    end
    temp_x = temp_x +1;
    temp_y = 1;
end

movie_frame_seq = reshape(movie_frame_array',1,emulatorParams.vt_pixels * emulatorParams.hr_pixels);
movie = movie_frame_seq*2^5;