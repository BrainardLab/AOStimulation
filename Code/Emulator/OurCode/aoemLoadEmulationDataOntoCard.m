function status = aoemLoadEmulationDataOntoCard(  )
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
%    nOutputChannels    - Number of AOSLO outputs being emulated.
%                         Typically three if there is one imaging channel,
%                         since we will have h sync, v sync, and pixels.
%                         But could be more in the future.
%    sampling_clk_frequency - How fast are we running the board.
% 
% Outputs:
%    status      - Boolean.  True means success, false means failure of
%                  some sort.
%
% Optional key/value pairs:
%    None.
%
% See also:
%

% History:
%   02/02/18  tyh, dhb   Wrote header comments.
