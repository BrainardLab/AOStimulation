function cardInfo = aoemStartEmulate(cardInfo,mRegs,timeout_ms)
% Start the card after it is ready to go.
%
% Syntax:
%    cardInfo = aoemStartEmulate(cardInfo,mRegs,timeout_ms)
%
% Description:
%    start the card
%
% Inputs:
%    cardInfo    -    DA card information
%    mRegs - label names for registers
%    timeout_ms - stop time
% Outputs:
%    cardInfo    -    DA card information
%
% Optional key/value pairs:
%    None.
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.
errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_TIMEOUT'), timeout_ms);
if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
    return;
end

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));

errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    
    if errorCode == 263  % 263 = ERR_TIMEOUT 
        errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));
        fprintf (' OK\n ................... replay stopped\n');

    else
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
end

fprintf (' ...................... replay done\n');