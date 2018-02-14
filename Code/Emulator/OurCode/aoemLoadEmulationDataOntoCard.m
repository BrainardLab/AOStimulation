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
%    cardInfo    -    DA card information
%    emulatorParams    -    emulator parameters
%    sampling_clk_frequency - How fast are we running the board.
%    memSize    -    memsize for sampling one frame data
% 
% Outputs:
%    status      - Boolean.  True means success, false means failure of
%                  some sort.
%    cardInfo    -  DA card information
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
else
    status = 0;
end
end
