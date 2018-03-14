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
%    This is a very basic emulator that just takes one frame and sends it
%    out over and over again.  Once we have this working we will move on to
%    playback an entire movie.
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
%
% Usually we would make this match the pixel clock frequency that
% we are emulating, just to keep the timing simple and lined up.
sampling_clk_frequency = 38.4910 * 10^6; 

% DA card output parameters. 14-bit DAC, double precision(possible range
% is -8192 to 8191)
dac_maxFS = 8191;
dac_minFS = 0;
nOutputChannels = 4;

% How long to emulate for
emulationDuration_ms = 10000;

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

% From the measurement at AOSLO, this is a 5ms pulse width for vertical
% sync pulse.
emulatorParams.vt_sync_pixels = 10;
emulatorParams.vt_back_porch_pixels = 136;
emulatorParams.vt_active_pixels = 645;
emulatorParams.vt_front_porch_pixels = 133;
emulatorParams.vt_pixels = emulatorParams.vt_sync_pixels+emulatorParams.vt_back_porch_pixels+emulatorParams.vt_active_pixels+emulatorParams.vt_front_porch_pixels;

% Output maximum voltage
%
% Each vector corresponds to channels 0, 1, 2, and 3 on the board, in
% order.
emulatorParams.outputMillivolts = [2000 3000 100 3000];
emulatorParams.outputOffsetvolts = [0 0 0 0];

% Emulator image resolution
emulatorParams.height = 645;
emulatorParams.width = 721;

% Source for movie that we will emulate
% test images include image1 and movies
movieFileName = 'D:\tyh\david\DAcard\CD_SPCM_Copy\Examples\matlab\examples\image1.jpg';

%% Figure out sampling params and amount of memory needed for emulation.
[memSize,sampleParas] = aoemCalMemsize(emulatorParams,sampling_clk_frequency);

%% Initialize the card
[status,cardInfo,mRegs] = aoemInitializeCardForEmulation(nOutputChannels,emulatorParams,sampling_clk_frequency,memSize,emulationDuration_ms);
if (~status)
    error('Card initialization returns failure status');
end

%% Get the movie data to emulate
[movieData,hrData,vtData] = aoemGenerateSignal(movieFileName,emulatorParams,sampleParas,memSize,dac_maxFS,dac_minFS);

%% Load in the emulator data
% 
% The cardInfo structure is modified so that it now contains all of the
% information needed to run the emulation.  It can do so, because the
% actual movie data has been loaded onto the card.
[status,cardInfo] = aoemLoadEmulationDataOntoCard(movieData,hrData,vtData,cardInfo,emulatorParams,sampleParas,memSize);
if (~status)
    error('Data load onto card returns failure status');
end

%% Start and emulate for specified duration.
[status,cardInfo] = aoemStartEmulate(cardInfo,mRegs,emulationDuration_ms);
if (~status)
    error('start card returns failure status');
end

%% Close up card
status = aoemCloseCard(cardInfo);
if (~status)
    error('Card close returns failure status');
end
  