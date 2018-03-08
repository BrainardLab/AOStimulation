function [status,cardInfo,mRegs] = aoemInitializeCardForEmulation(nOutputChannels,emulatorParams,sampling_clk_frequency,memSize,timeout_ms)
% Initialize the D/A card to be ready to go for our emulator
%
% Syntax:
%    [status,cardInfo,mRegs] = aoemInitializeCardForEmulation(    )
%
% Description:
%    Handle all the little things we need to do to get the card ready to
%    emulate the AOSLO. 
%
% Inputs:
%    nOutputChannels    - Number of AOSLO outputs being emulated.
%                         Typically three if there is one imaging channel,
%                         since we will have h sync, v sync, and pixels.
%                         But could be more in the future.
%    emulatorParams    - emulator parameters
%    sampling_clk_frequency    -    How fast are we running the board.
%    memSize     -    memsize for sampling one frame data
%    timeout_ms    -    when timeout card stop
% Outputs:
%    status      - Boolean.  True means success, false means failure of
%                  some sort.
%    cardInfo    - DA card information  
%    mRegs - label names for registers
% Optional key/value pairs:
%    None.
%
% See also:
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.


%% Helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

%% Init card and store infos in cardInfo struct
[status, cardInfo] = spcMInitCardByIdx (0);
if (status == true)
    % ----- print info about the board -----
    cardInfoText = spcMPrintCardInfo (cardInfo);
    fprintf (cardInfoText);
else
    spcMErrorMessageStdOut (cardInfo, 'Error: Could not open card\n', true);
    return;
end

%% Check whether we support this card type 
if ((cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AO')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DO')) & (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_DIO')))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

%% Set replay mode to continuous. Could also choose singleshot (1) or single
% restart (3).
replayMode = 2;
if (replayMode < 1) | (replayMode > 3) 
    spcMCloseCard (cardInfo);
    return;
end

%% Do card settings

samplerate = sampling_clk_frequency;

% Set the samplerate and internal PLL, no clock output 
[status, cardInfo] = spcMSetupClockPLL (cardInfo, samplerate, 0);  % clock output : enable = 1, disable = 0
if (status == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n ..... Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% Set channel mask for max channels
if cardInfo.maxChannels == 64
    chMaskH = hex2dec ('FFFFFFFF');
    chMaskL = hex2dec ('FFFFFFFF');
else
    chMaskH = 0;
    chMaskL = bitshift (1, cardInfo.maxChannels) - 1;
end

% Handle desired replay mode
switch replayMode
    
    case 1
        % ----- singleshot replay -----
        [status, cardInfo] = spcMSetupModeRepStdSingle (cardInfo, chMaskH, chMaskL, memSize);
        if (status == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
            return;
        end
        fprintf (' .............. Set singleshot mode\n');
        
        % ----- set software trigger, no trigger output -----
        [status, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
        if (status == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' ............. Set software trigger\n');
        
    case 2
        % ----- endless continuous mode -----
        [status, cardInfo] = spcMSetupModeRepStdLoops (cardInfo, chMaskH, chMaskL, memSize, 0);
        if (status == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
            return;
        end
        fprintf (' .............. Set continuous mode\n');
        
        % ----- set software trigger, no trigger output -----
        [status, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
        if (status == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);

            return;
        end
        fprintf (' ............. Set software trigger\n Wait for timeout (%d sec) .....', timeout_ms / 1000);

    case 3
        % ----- single restart (one signal on every trigger edge) -----
        [status, cardInfo] = spcMSetupModeRepStdSingleRestart (cardInfo, chMaskH, chMaskL, memSize, 0);
        if (status == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' .......... Set single restart mode\n');
        
        % ----- set extern trigger, positive edge -----
        [status, cardInfo] = spcMSetupTrigExternal (cardInfo, mRegs('SPC_TM_POS'), 1, 0, 1, 0);
        if (status == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' ............... Set extern trigger\n Wait for timeout (%d sec) .....', timeout_ms / 1000);
end

% ----- type dependent card setup -----
switch cardInfo.cardFunction

    % ----- analog generator card setup -----
    case mRegs('SPCM_TYPE_AO')
        % ----- program all output channels to +/- 1 V with no offset and no filter -----
        for i=0 : cardInfo.maxChannels-1  
            [status, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, emulatorParams.outputMillivolts(i+1), emulatorParams.outputOffsetvolts(i+1), 0, 16, 0, 0); % 16 = SPCM_STOPLVL_ZERO, doubleOut = disabled, differential = disabled
            if (status == false)
                spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
                return;
            end
        end
   
   % ----- digital acquisition card setup -----
   case { mRegs('SPCM_TYPE_DO'), mRegs('SPCM_TYPE_DIO') }
       % ----- set all output channel groups ----- 
       for i=0 : cardInfo.DIO.groups-1                             
           [status, cardInfo] = spcMSetupDigitalOutput (cardInfo, i, mRegs('SPCM_STOPLVL_LOW'), 0, 3300, 0);
       end
end





