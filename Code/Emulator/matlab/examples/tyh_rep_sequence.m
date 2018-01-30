%**************************************************************************
%
% tyh_rep_sequence.m                              yinghong tian, 01/2018
%
%**************************************************************************
%
% AOSLO generator cards. 
% three signal generate 
%  
% channel 0: horizontal sync
% channel 1: vertical   sync
% channel 2: movie signal
%**************************************************************************
clear all;
%parameter


sampling_clk_frequency = 50 * 10^6;  %% DA card sampling rate

pix_clk_frequency = 38.4910 * 10^6;

hr_sync = 15 / pix_clk_frequency;
hr_back_porch = 369 / pix_clk_frequency;
hr_active = 721 / pix_clk_frequency;
hr_front_porch = 1395 / pix_clk_frequency;

hr_clk = hr_sync + hr_back_porch + hr_active + hr_front_porch;
hr_clk_fre = 1 / hr_clk;

hr_sync_ponits = fix(hr_sync * sampling_clk_frequency);
hr_back_porch_ponits = fix(hr_back_porch * sampling_clk_frequency);
hr_active_ponits = fix(hr_active * sampling_clk_frequency);
hr_front_porch_ponits = fix(hr_front_porch * sampling_clk_frequency);

hr_len = hr_sync_ponits + hr_back_porch_ponits + hr_active_ponits + hr_front_porch_ponits;

vt_sync = 10 / hr_clk_fre;
vt_back_porch = 136 / hr_clk_fre;
vt_active = 645 / hr_clk_fre;
vt_front_porch = 133 / hr_clk_fre;

vt_clk = vt_sync + vt_back_porch + vt_active + vt_front_porch;
vt_clk_fre = 1 / vt_clk;

vt_sync_ponits = fix(vt_sync * sampling_clk_frequency);
vt_back_porch_ponits = fix(vt_back_porch * sampling_clk_frequency);
vt_active_ponits = fix(vt_active * sampling_clk_frequency);
vt_front_porch_ponits = fix(vt_front_porch * sampling_clk_frequency);

vt_len = vt_sync_ponits + vt_back_porch_ponits + vt_active_ponits + vt_front_porch_ponits;
% helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

% ***** init card and store infos in cardInfo struct *****
[success, cardInfo] = spcMInitCardByIdx (0);

if (success == true)
    % ----- print info about the board -----
    cardInfoText = spcMPrintCardInfo (cardInfo);
    fprintf (cardInfoText);
else
    spcMErrorMessageStdOut (cardInfo, 'Error: Could not open card\n', true);
    return;
end

% ----- check whether we support this card type in the example -----
if (cardInfo.cardFunction ~= mRegs('SPCM_TYPE_AO'))
    spcMErrorMessageStdOut (cardInfo, 'Error: Card function not supported by this example\n', false);
    return;
end

% ----- check if Sequence Mode is installed -----
if (bitand (cardInfo.featureMap, mRegs('SPCM_FEAT_SEQUENCE')) == 0)
    spcMErrorMessageStdOut (cardInfo, 'Error: Sequence Mode Option not installed. Example was done especially for this option!\n', false);
    return;
else
    fprintf ('\n Sequence Mode ........ installed.');
end

% ----- set the samplerate and internal PLL, no clock output -----
[success, cardInfo] = spcMSetupClockPLL (cardInfo, sampling_clk_frequency, 0);  % clock output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupClockPLL:\n\t', true);
    return;
end
fprintf ('\n ..... Sampling rate set to %.1f MHz\n', cardInfo.setSamplerate / 1000000);

% ----- set software trigger, no trigger output -----
[success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
    return;
end

% ----- program all output channels to +/- 1 V with no offset and no filter -----
for i=0 : cardInfo.maxChannels-1  
    [success, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, 1000, 0, 0, mRegs('SPCM_STOPLVL_ZERO'), 0, 0); % doubleOut = disabled, differential = disabled
    if (success == false)
        spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
        return;
    end
end

% ----- setup sequence mode, 1 channel, 4 segments, start segment 0 -----
[success, cardInfo] = spcMSetupModeRepSequence (cardInfo, 0, 1, 1, 0);
if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRepSequence:\n\t', true);
    return;
end

% ----- set segment rectangel -----
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_WRITESEGMENT'), 0);
error = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_SEQMODE_SEGMENTSIZE'), 4096);

% create rectangel waveform
%tyh_spcMCalcSignal (cardInfo, len, shape, loops, gainP,time_sync,time_back_porch,time_active,time_front_porch)
%[success, cardInfo, Signal] = spcMCalcSignal (cardInfo, 4096, 2, 1, 100);

[success, cardInfo, Signal] = tyh_spcMCalcSignal (cardInfo, hr_len, 2, 1, 100,hr_sync_ponits,hr_back_porch_ponits,hr_active_ponits,hr_front_porch_ponits);

if (success == false)
    spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
    return;
end
errorCode = spcm_dwSetData (cardInfo.hDrv, 0, hr_len, 1, 0, Signal);


%----- set sequence steps -----
%                               step, nextStep, segment, loops, condition (0 => End loop always, 1 => End loop on trigger, 2 => End sequence)
spcMSetupSequenceStep (cardInfo,   0,        1,       0, 20000, 0);
spcMSetupSequenceStep (cardInfo,   1,        2,       0, 50000, 0);
spcMSetupSequenceStep (cardInfo,   2,        3,       0, 20000, 0);
spcMSetupSequenceStep (cardInfo,   3,        4,       0, 50000, 0);
spcMSetupSequenceStep (cardInfo,   4,        5,       0, 20000, 0);
spcMSetupSequenceStep (cardInfo,   5,        0,       0, 50000, 2);

% ----- set command flags -----
commandMask = bitor (mRegs('M2CMD_CARD_START'), mRegs('M2CMD_CARD_ENABLETRIGGER'));
commandMask = bitor (commandMask, mRegs('M2CMD_CARD_WAITREADY'));

errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), commandMask);
if (errorCode ~= 0)
    
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    
    if errorCode == mErrors('ERR_TIMEOUT')
        errorCode = spcm_dwSetParam_i32 (cardInfo.hDrv, mRegs('SPC_M2CMD'), mRegs('M2CMD_CARD_STOP'));
        fprintf (' OK\n ................... replay stopped\n');

    else
        spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetParam_i32:\n\t', true);
        return;
    end
end

fprintf (' ...................... replay done\n');

% ***** close card *****
spcMCloseCard (cardInfo);

xx=0;
