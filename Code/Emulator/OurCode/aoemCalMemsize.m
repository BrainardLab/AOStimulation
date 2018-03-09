function [memSize,sampleParas] = aoemCalMemsize(emulatorParams,sampling_clk_frequency)
% Calculate the DA card memery size for sampling points.
%
% Syntax:
%    [memSize,sampleParas] = aoemCalMemsize(emulatorParams,sampling_clk_frequency)
%
% Description:
%    According to the emulator parameters, the function calcuates the pixel
%    time, and then gets the sampling points.  This results in a total
%    memory size that we need to allocate to hold all the samples.
%
% Inputs:
%    emulatorParams    - emulator parameters
%    sampling_clk_frequency - How fast are we running the board.
% 
% Outputs:
%    memSize      - sampling memery size
%    sampleParas  - sampling points for Hsync / Vsync
%
% Optional key/value pairs:
%    None.
%
% See also: aoemBasicEmulator, aoeimInitializeCardForEmulation,
%    aoemGenerateSignal, aoemLoadEmulationDataOntoCard.
%

% History:
%   02/02/18  tyh, dhb   Wrote header comments.


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
sampleParas.hr_sync_points = fix(hr_sync_ns / sampling_clk_time);
sampleParas.hr_back_porch_points = fix(hr_back_porch_ns / sampling_clk_time);
sampleParas.hr_active_points = fix(hr_active_ns / sampling_clk_time);
sampleParas.hr_front_porch_points = fix(hr_front_porch_ns / sampling_clk_time);
sampleParas.hr_line_points = sampleParas.hr_sync_points + sampleParas.hr_back_porch_points + sampleParas.hr_active_points + sampleParas.hr_front_porch_points;

% Times in nanosceonds for vertical
vt_sync_ns = emulatorParams.vt_sync_pixels * hr_line_ns;
vt_back_porch_ns = emulatorParams.vt_back_porch_pixels * hr_line_ns;
vt_active_ns = emulatorParams.vt_active_pixels * hr_line_ns;
vt_front_porch_ns = emulatorParams.vt_front_porch_pixels * hr_line_ns;
vt_clk_ns = vt_sync_ns + vt_back_porch_ns + vt_active_ns + vt_front_porch_ns;
%vt_clk_fre = 1 / vt_clk;

% Again, get our approximation given overall sampling clock rate.
sampleParas.vt_sync_points = fix(vt_sync_ns / sampling_clk_time);
sampleParas.vt_back_porch_points = fix(vt_back_porch_ns / sampling_clk_time);
sampleParas.vt_active_points = fix(vt_active_ns / sampling_clk_time);
sampleParas.vt_front_porch_points = fix(vt_front_porch_ns / sampling_clk_time);
sampleParas.vt_len_points = sampleParas.vt_sync_points + sampleParas.vt_back_porch_points + sampleParas.vt_active_points + sampleParas.vt_front_porch_points;

% Get memory size from number of lines and pixels
%
% Note that we only store one line per vertical pixel, so we
% use emulatorParams.vt_pixels here. 
memSize = sampleParas.hr_line_points*emulatorParams.vt_pixels;
        