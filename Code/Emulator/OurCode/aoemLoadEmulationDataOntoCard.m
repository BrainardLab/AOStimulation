function [status,cardInfo] = aoemLoadEmulationDataOntoCard(cardInfo,emulatorParams,sampling_clk_frequency,memSize)
% Load the time series of emulation data onto the card and get it ready to go.
%
% Syntax:
%    status = aoemLoadEmulationDataOntoCard(  )
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

    % ***** calculate waveforms *****

    [movieData,hrData,vtData] = aoemGenerateSignal(emulatorParams,sampling_clk_frequency,memSize);
    

    switch cardInfo.setChannels
        
        case 1
            % ----- get the whole data for one channel with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, hrData);
        case 2
            % ----- get the whole data for two channels with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, hrData, vtData);
        case 4
            % ----- set data for four channels with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, hrData, vtData, movieData, movieData);
    end
    
if (errorCode ~= 0)
    [status, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
    return;
end
