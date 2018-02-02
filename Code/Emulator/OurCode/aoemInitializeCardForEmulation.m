function status = aoemInitializeCardForEmulation(nOutputChannels,sampling_clk_frequency,...    )
% Initialize the D/A card to be ready to go for our emulator
%
% Syntax:
%    status = aoemInitializeCardForEmulation(    )
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
