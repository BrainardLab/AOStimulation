function aoTimingPara = aoTimingParametersGen(varargin)
% Set the timing parameters from the real system
%
% Syntax:
%    aoTimingPara = aoTimingParametersGen
%
% Description:
%    Set timing parameters, which come from our real system.  The
%    parameters are returned in a struct with fields:
%      pixClkFreq - pixel clock frequency (hz)
%
%
% Outputs:
%    pixClkFreq         - AO timing parameters
%    pixTime            - Pixel time in ns
%
%    hrSync             - Number of pixels for horizontal sync pulse
%    hrBackPorch        - Back porch for each line in pixels
%    hrActive           - Active horizontal acqusition in pixels
%    hrFrontPorch       - Front porch for each line in pixels
%    timePerLine        - Time per line in ns
%
%    vtSync             - Number of lines for vertical sync
%    vtBackPorch        - Vertical back porch in lines
%    vtActive           - Number of active vertical lines
%    vtFrontPorch       - Vertical front portch in lines
%
%    timePerFrame       - Time per frame in ns
%
% Optional key/value pairs:
%    'parameterSet'   - Choose non-default set of parameters. String.
%                       Default 'smilow'. Choices:
%                         'smilow'  Parameters for the Smilow AOSLO
%
% See also:
%

% History:
%   05/08/18  tyh

% Parse
p = inputParser;
p.addParameter('parameterSet','smilow',@ischar);
p.parse(varargin{:})

% Choose parameter set
switch (p.Results.parameterSet)
    case 'smilow'
        % AOSLO at Smilow (UPENN) parameters.
        
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
        
    otherwise
        error('Unknown parameter set specified');
end
end