function [movieData,hrData,vtData] = aoemGenerateSignal(emulatorParams,sampling_clk_frequency,memSize)
% Load the time series of emulation data onto the card and get it ready to go.
%
% Syntax:
%    status = aoemGenerateSignal(  )
%
% Description:
%    We work by first loading the data onto the D/A card's onboard memory
%    and then later giving it a go signal to ship it out.  This routine
%    does the loading.
%
% Inputs:
%    nOutputChannels    - Number of AOSLO outputs being emulated.
%                         Typically three if there is one imaging channel,
%                         since we will have h sync, v sync, and pixels.
%                         But could be more in the future.
%    sampling_clk_frequency - How fast are we running the board.
% 
% Outputs:
%    status      - Boolean.  True means success, false means failure of
%                  some sort.
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
    %[success, cardInfo, Dat_Ch0] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 2, 1, 100);
    hrData = aoemSpcMCalcSignal(memSize, 2, 924, 100,20);
        
   % ----- ch1 = vertical sync
    vtData = aoemSpcMCalcSignal(memSize, 2, 1, 100,25000);
        
   % ----- ch2 = movie waveform -----
    movieFileName = 'D:\tyh\david\DAcard\CD_SPCM_Copy\Examples\matlab\examples\TestH.avi';
    movieData = aoemReadMoveForPlayback(movieFileName,emulatorParams);
        