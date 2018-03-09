function [status,cardInfo] = aoemStartEmulate(cardInfo,mRegs,emulationDuration_ms)
% Start the card after it is ready to go.
%
% Syntax:
%    [status,cardInfo] = aoemStartEmulate(cardInfo,mRegs,emulationDuration_ms)
%
% Description:
%    start the card and output signal. it is softwre trigger method.
%
% Inputs:
%    cardInfo             - Structure with DA card information  
%    mRegs                - Structure with label names for registers
%    emulationDuration_ms - stop time
% Outputs:
%    status             - Boolean.  True means success, false means failure of
%                         some sort.
%    cardInfo             - updated Structure with DA card information  
%
% Optional key/value pairs:
%    None.
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), emulationDuration_ms);
if (errorCode ~= 0)
    [status, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
else
    status = 1;
end

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));

errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    
    [status, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    
    if errorCode == 263  % 263 = ERR_TIMEOUT 
        errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));
        fprintf (' OK\n ................... replay stopped\n');
        status = 1; 
    else
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
else
    status = 1;    
end

fprintf (' ...................... replay done\n');