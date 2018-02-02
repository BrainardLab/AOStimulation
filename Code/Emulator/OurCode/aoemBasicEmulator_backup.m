% Top level code for basic AO emulation
%
% Description:
%    This program is our evolving emulation code for the AOSLO system.
%  
%    The goal is to set system parameters and then generate hsync, vsync
%    and pixel signals, with the pixels coming from a movie that was
%    acquired on the real system.
%
%    We will know this is working when we can play the emulator back into
%    the AOSLO acquisition system and get back a movie very close to what
%    we started with.
%
%    Note that this program is a work in progress - it does not yet do the
%    above.
%

% History
%   01/xx/18  tyh   Wrote this starting with provided rep_std_single
%                   example code.
%
%                   rep_std_single.m  (c) Spectrum GmbH, 04/2015

%% Clear out workspace
clear;

%% Define parameters

% DA card sampling rate and clock time.  Clock time is in ns.
sampling_clk_frequency = 38.4910 * 10^6;  
dac_maxFS = 8191;
dac_minFS = -8192;

% Emulation parameters
%
% Master clock frequency being emulated, and corrsponding clock time 
% in ns.
emulatorParams.pix_clk_frequency = 38.4910 * 10^6;

emulatorParams.hr_sync_pixels = 15;
emulatorParams.hr_back_porch_pixels = 369;
emulatorParams.hr_active_pixels = 721;
emulatorParams.hr_front_porch_pixels = 1395;
emulatorParams.hr_pixels = emulatorParams.hr_sync_pixels+emulatorParams.hr_back_porch_pixels+emulatorParams.hr_active_pixels+emulatorParams.hr_front_porch_pixels;

emulatorParams.vt_sync_pixels = 10;
emulatorParams.vt_back_porch_pixels = 136;
emulatorParams.vt_active_pixels = 645;
emulatorParams.vt_front_porch_pixels = 133;
emulatorParams.vt_pixels = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+emulatorParams.vt_active_pixels+emulatorParams.vt_front_porch_pixels;

% Output maximum voltage
emulatorParams.outputMillivolts = 3000;

%% Calculate convenient numbers from the parameters

% Clock times in ns
sampling_clk_time = 10^9/sampling_clk_frequency;
pix_clk_time = 10^9/emulatorParams.pix_clk_frequency;

% Times in nanoseconds for horizontal 
hr_sync_ns = emulatorParams.hr_sync_pixels * pix_clk_time;
hr_back_porch_ns = emulatorParams.hr_back_porch_pixels * pix_clk_time;
hr_active_ns = emulatorParams.hr_active_pixels * pix_clk_time;
hr_front_porch_ns = emulatorParams.hr_front_porch_pixels * pix_clk_time;
hr_line_ns = hr_sync_ns + hr_back_porch_ns + hr_active_ns + hr_front_porch_ns;
%hr_clk_fre = 1 / hr_clk;

% Our emulator runs at a particular overall clock rate, which means that we
% may not be able to exactly emulate all of the specified numbers of
% pixels.  Here we compute how close we actually come to the desired
% values, using "points" as the variable name rather than "pixels" to
% indicate what we're doing.  If we set the emulation frequency equal to
% the clock frequency, then things should come out OK.
hr_sync_points = fix(hr_sync_ns / sampling_clk_time);
hr_back_porch_points = fix(hr_back_porch_ns / sampling_clk_time);
hr_active_points = fix(hr_active_ns / sampling_clk_time);
hr_front_porch_points = fix(hr_front_porch_ns / sampling_clk_time);
hr_line_points = hr_sync_points + hr_back_porch_points + hr_active_points + hr_front_porch_points;

% Times in nanosceonds for vertical
vt_sync_ns = emulatorParams.vt_sync_pixels * hr_line_ns;
vt_back_porch_ns = emulatorParams.vt_back_porch_pixels * hr_line_ns;
vt_active_ns = emulatorParams.vt_active_pixels * hr_line_ns;
vt_front_porch_ns = emulatorParams.vt_front_porch_pixels * hr_line_ns;
vt_clk_ns = vt_sync_ns + vt_back_porch_ns + vt_active_ns + vt_front_porch_ns;
%vt_clk_fre = 1 / vt_clk;

% Again, get our approximation given overall sampling clock rate.
vt_sync_points = fix(vt_sync_ns / sampling_clk_time);
vt_back_porch_points = fix(vt_back_porch_ns / sampling_clk_time);
vt_active_points = fix(vt_active_ns / sampling_clk_time);
vt_front_porch_points = fix(vt_front_porch_ns / sampling_clk_time);
vt_len_points = vt_sync_points + vt_back_porch_points + vt_active_points + vt_front_porch_points;

% Get the input movie. Right now we just use one frame for test
video = VideoReader('D:\tyh\david\DAcard\CD_SPCM_Copy\Examples\matlab\examples\TestH.avi');
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
active_col_end = emulatorParams.hr_sync_pixels+emulatorParams.hr_back_porch_pixels+emulatorParams.hr_active_pixels
active_row_start = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+1;
active_row_end = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+emulatorParams.vt_active_pixels

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
movie_frame_seq = movie_frame_seq*2^5;
%% Helper maps to use label names for registers and errors
mRegs = spcMCreateRegMap ();
mErrors = spcMCreateErrorMap ();

%% Init card and store infos in cardInfo struct
[success, cardInfo] = spcMInitCardByIdx (0);
if (success == true)
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
timeout_ms = 10000;
samplerate = sampling_clk_frequency;

% Set the samplerate and internal PLL, no clock output 
[success, cardInfo] = spcMSetupClockPLL (cardInfo, samplerate, 0);  % clock output : enable = 1, disable = 0
if (success == false)
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
        [success, cardInfo] = spcMSetupModeRepStdSingle (cardInfo, chMaskH, chMaskL, vt_len_points);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
            return;
        end
        fprintf (' .............. Set singleshot mode\n');
        
        % ----- set software trigger, no trigger output -----
        [success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' ............. Set software trigger\n');
        
    case 2
        % ----- endless continuous mode -----
        [success, cardInfo] = spcMSetupModeRepStdLoops (cardInfo, chMaskH, chMaskL, vt_len_points, 0);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupModeRecStdSingle:\n\t', true);
            return;
        end
        fprintf (' .............. Set continuous mode\n');
        
        % ----- set software trigger, no trigger output -----
        [success, cardInfo] = spcMSetupTrigSoftware (cardInfo, 0);  % trigger output : enable = 1, disable = 0
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);

            return;
        end
        fprintf (' ............. Set software trigger\n Wait for timeout (%d sec) .....', timeout_ms / 1000);

    case 3
        % ----- single restart (one signal on every trigger edge) -----
        [success, cardInfo] = spcMSetupModeRepStdSingleRestart (cardInfo, chMaskH, chMaskL, 64 * 1024, 0);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupTrigSoftware:\n\t', true);
            return;
        end
        fprintf (' .......... Set single restart mode\n');
        
        % ----- set extern trigger, positive edge -----
        [success, cardInfo] = spcMSetupTrigExternal (cardInfo, mRegs('SPC_TM_POS'), 1, 0, 1, 0);
        if (success == false)
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
            [success, cardInfo] = spcMSetupAnalogOutputChannel (cardInfo, i, emulatorParams.outputMillivolts, 0, 0, 16, 0, 0); % 16 = SPCM_STOPLVL_ZERO, doubleOut = disabled, differential = disabled
            if (success == false)
                spcMErrorMessageStdOut (cardInfo, 'Error: spcMSetupInputChannel:\n\t', true);
                return;
            end
        end
   
   % ----- digital acquisition card setup -----
   case { mRegs('SPCM_TYPE_DO'), mRegs('SPCM_TYPE_DIO') }
       % ----- set all output channel groups ----- 
       for i=0 : cardInfo.DIO.groups-1                             
           [success, cardInfo] = spcMSetupDigitalOutput (cardInfo, i, mRegs('SPCM_STOPLVL_LOW'), 0, 3300, 0);
       end
end

if cardInfo.cardFunction == mRegs('SPCM_TYPE_AO')

    % ----- analog data -----

    % ***** calculate waveforms *****

    if cardInfo.setChannels >= 1
        % ----- ch0 = sine waveform -----tyh1_spcMCalcSignal
        %[success, cardInfo, Dat_Ch0] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 2, 1, 100);
        cardInfo.setMemsize = vt_len_points;
        [success, cardInfo, Dat_Ch0] = aoemSpcMCalcSignal(cardInfo, cardInfo.setMemsize, 2, 924, 100,20);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    end

    if cardInfo.setChannels >= 2
        % ----- ch1 = rectangle waveform -----
        [success, cardInfo, Dat_Ch1] = aoemSpcMCalcSignal(cardInfo, cardInfo.setMemsize, 2, 1, 100,25000);
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    end

    if cardInfo.setChannels == 4
        % ----- ch2 = triangle waveform -----
        [success, cardInfo, Dat_Ch2] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 3, 1, 100);
        Dat_Ch2 = movie_frame_seq;
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    
        % ----- ch3 = sawtooth waveform -----
        [success, cardInfo, Dat_Ch3] = spcMCalcSignal (cardInfo, cardInfo.setMemsize, 4, 1, 100);
        
        if (success == false)
            spcMErrorMessageStdOut (cardInfo, 'Error: spcMCalcSignal:\n\t', true);
            return;
        end
    end

    switch cardInfo.setChannels
        
        case 1
            % ----- get the whole data for one channel with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, Dat_Ch0);
        case 2
            % ----- get the whole data for two channels with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, Dat_Ch0, Dat_Ch1);
        case 4
            % ----- set data for four channels with offset = 0 ----- 
            errorCode = spcm_dwSetData (cardInfo.hDrv, 0, cardInfo.setMemsize, cardInfo.setChannels, 0, Dat_Ch0, Dat_Ch1, Dat_Ch2, Dat_Ch3);
    end
    
else
 
    % ----- digital data -----
    [success, Data] = spcMCalcDigitalSignal (cardInfo.setMemsize, cardInfo.setChannels);
    
    errorCode = spcm_dwSetRawData (cardInfo.hDrv, 0, length (Data), Data, 1);
end

if (errorCode ~= 0)
    [success, cardInfo] = spcMCheckSetError (errorCode, cardInfo);
    spcMErrorMessageStdOut (cardInfo, 'Error: spcm_dwSetData:\n\t', true);
    return;
end

% ----- we'll start and wait until the card has finished or until a timeout occurs -----
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

% ***** close card *****
spcMCloseCard (cardInfo);
  