function [movieData,hrData,vtData] = aoemGenerateSignal(movieFileName,emulatorParams,sampleParas,memSize,dac_maxFS,dac_minFS)
% Create the data seqence for movie, horizontal, vertical.
%
% Syntax:
%    [movieData,hrData,vtData] = aoemGenerateSignal(movieFileName,emulatorParams,sampleParas,memSize,dac_maxFS,dac_minFS)
%
% Description:
%    we create signal to emulate the real signals from oscilloscope and
%    timing parameters.
%
% Inputs:
%    movieFileNane      - Full path to movie that we'll emulate.
%    emulatorParams     - Emulator parameters
%    sampleParas        - Sampling points for Hsync / Vsync
%    memSize            - Memory for sampling one frame data
%    dac_maxFS          - max full-scale for DA card
%    dac_minFS          - min full-scale for DA card
%
% Outputs:
%    movieData          - Movie data
%    hrData             - Horizontal sync signal
%    vtData             - Vertical sync signal
%
% Optional key/value pairs:
%    None.
%
% See also: aoemBasicEmulator, aoemCalMemsize, aoeimInitializeCardForEmulation,
%    aoemLoadEmulationDataOntoCard.

% History:
%   02/02/18  tyh, dhb   Wrote header comments.

% Note below that the second argument to aoemScMCalcSignal specifies
% the shape of the waveform.
% shape: 1 : rectangle
%        2 : invert rectangle
%        3 : triangle

% ----- ch0 = horizontal sync
nPulseWidth = fix(memSize / emulatorParams.vt_pixels / 2);
hrData = aoemSpcMCalcSignal(memSize, 2, emulatorParams.vt_pixels, 100,nPulseWidth,dac_maxFS,dac_minFS);

% ----- ch1 = vertical sync
nPulseWidth = (sampleParas.vt_sync_points+sampleParas.vt_back_porch_points) / 2;
vtData = aoemSpcMCalcSignal(memSize, 1, 1, 100,nPulseWidth,dac_maxFS,dac_minFS);

% ----- ch2 = movie waveform -----
movieData = aoemReadMovieForPlayback(movieFileName,emulatorParams,sampleParas);
