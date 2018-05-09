function aoTimingPara = aoTimingParametersGen ()
% Set the timing parameters from the real system
%
% Syntax:
%    aoTimingPara = aoTimingParametersGen()
%
% Description:
%    Set timing parameters, which come from our real system
%
% Outputs:
%    aoTimingPara     - AO timing parameters
%    
%
% Optional key/value pairs:
%    None.
%
% See also:
%

% History:
%   05/08/18  tyh


% Timing parameters for the AOSLO clock frequency
aoTimingPara.pixClkFreq = 20 * 10^6;
aoTimingPara.pixTime = 10^9/aoTimingPara.pixClkFreq;

% Horizontal scan paramters in pixels
aoTimingPara.hrSync = 8;
aoTimingPara.hrBackPorch = 115;
aoTimingPara.hrActive = 512;
aoTimingPara.hrFrontPorch = 664;

% Time per horizational line (unit ns)
aoTimingPara.timePerLine = (aoTimingPara.hrSync + aoTimingPara.hrBackPorch...
    +aoTimingPara.hrActive+aoTimingPara.hrFrontPorch)...
    *aoTimingPara.pixTime;


% Vertical / frame parameters in lines.
aoTimingPara.vtSync = 10;
aoTimingPara.vtBackPorch = 30;
aoTimingPara.vtActive = 512;
aoTimingPara.vtFrontPorch = 228;

% Time for vertical frame (unit ns)
aoTimingPara.timePerFrame = (aoTimingPara.vtSync + aoTimingPara.vtBackPorch...
    +aoTimingPara.vtActive+aoTimingPara.vtFrontPorch)...
    *aoTimingPara.timePerLine;

end