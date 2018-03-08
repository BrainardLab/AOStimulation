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
sampling_clk_frequency = 38.4910 * 10^6;   %38.4910
dac_maxFS = 8191;
dac_minFS = -8192;
nOutputChannels = 4;

timeout_ms = 5*1000;  %%120000
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
emulatorParams.outputMillivolts = [2000 3000 100 3000]; % [ch0 ch1 ch2 ch3]
emulatorParams.outputOffsetvolts = [0 0 0 0];  %offset adjust

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[memSize,sampleParas] = aoemCalMemsize(emulatorParams,sampling_clk_frequency);

[status,cardInfo,mRegs] = aoemInitializeCardForEmulation(nOutputChannels,emulatorParams,sampling_clk_frequency,memSize,timeout_ms);

[status,cardInfo] = aoemLoadEmulationDataOntoCard(cardInfo,emulatorParams,sampleParas,memSize);

% ----- we'll start and wait until the card has finished or until a timeout occurs -----
cardInfo = aoemStartEmulate(cardInfo,mRegs,timeout_ms);

% ***** close card *****
aoemCloseCard(cardInfo);
  