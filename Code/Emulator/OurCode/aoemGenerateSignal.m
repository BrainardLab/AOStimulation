function [movieData,hrData,vtData] = aoemGenerateSignal(emulatorParams,sampling_clk_frequency,memSize)
% Create the data seqence for movie, horizontal, vertical.
%
% Syntax:
%    [movieData,hrData,vtData] = aoemGenerateSignal(emulatorParams,sampling_clk_frequency,memSize)
%
% Description:
%    we create signal to emulate the real signals from oscilloscope and
%    timing parateres.
%
% Inputs:
%    emulatorParams    -    emulator parameters
%    sampling_clk_frequency - How fast are we running the board.
%    memSize    -    memsize for sampling one frame data
% 
% Outputs:
%    movieData      - movie data
%    hrData    -  horizontal sync signal
%    vtData    -  vertical sync signal
%
% Optional key/value pairs:
%    None.
%
% See also:
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.

    % ----- analog data -----

    % ***** calculate waveforms *****

    
    % ----- ch0 = horizontal sync
    nPulseWidth = memSize / emulatorParams.vt_pixels / 2;
    hrData = aoemSpcMCalcSignal(memSize, 2, emulatorParams.vt_pixels, 100,nPulseWidth);
        
   % ----- ch1 = vertical sync
    %%from the measurement, 5ms pulse width for vertical
    nPulseWidth = (emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels)*emulatorParams.hr_pixels / 2;
    vtData = aoemSpcMCalcSignal(memSize, 1, 1, 100,nPulseWidth);
        
   % ----- ch2 = movie waveform -----
    movieFileName = 'D:\tyh\david\DAcard\CD_SPCM_Copy\Examples\matlab\examples\TestH.avi';
    movieData = aoemReadMoveForPlayback(movieFileName,emulatorParams);
        