% ComputeFrameRate
%
% Read timing parameters, spit out resulting frame rate

% aoTimingPara = aoTimingParametersGen;

% Pixel clock frequency
whichCase = 2;
switch (whichCase)
    case 1
        aoTimingPara.pixClkFreqHz = 20 * 10^6;

        % Horizontal scan paramters in pixels
        aoTimingPara.hrSync = 8;
        aoTimingPara.hrBackPorch = 115;
        aoTimingPara.hrActive = 512;
        aoTimingPara.hrFrontPorch = 664;

        % Vertical / frame parameters in lines.
        aoTimingPara.vtSync = 10;
        aoTimingPara.vtBackPorch = 30;
        aoTimingPara.vtActive = 512;
        aoTimingPara.vtActive = 228;
    case 2
        % Emulator image resolution is 645 high by 721 wide

        % Master clock frequency being emulated
        aoTimingPara.pixClkFreqHz = 38.4910 * 10^6;
        
        aoTimingPara.hrSync = 15;
        aoTimingPara.hrBackPorch = 369;
        aoTimingPara.hrActive = 721;
        aoTimingPara.hrFrontPorch  = 1395;

        % From the measurement at AOSLO, this is a 5ms pulse width for vertical
        % sync pulse.
        aoTimingPara.vtSync = 10;
        aoTimingPara.vtBackPorch = 136;
        aoTimingPara.vtActive = 645;
        aoTimingPara.vtActive = 133;
end

% Compute pixel time from frame rate and check
pixelTimeNsec = (1e9)*1/aoTimingPara.pixClkFreqHz;
fprintf('Pixel time in nsec: %0.2f\n',pixelTimeNsec)

% Compute number of pixels per line and time per line
pixelsPerLine = aoTimingPara.hrSync + aoTimingPara.hrBackPorch + aoTimingPara.hrActive + aoTimingPara.hrFrontPorch;
timePerLineUsec = (1e-3)*pixelTimeNsec*pixelsPerLine;
fprintf('Pixels per line: %d; time per line in usec %0.4f\n',pixelsPerLine,timePerLineUsec);

% Compute number of lines per frame, time per frame, frame rate
linesPerFrame = aoTimingPara.vtSync + aoTimingPara.vtBackPorch + aoTimingPara.vtActive + aoTimingPara.vtFrontPorch;
timePerFrameMsec = (1e-3)*linesPerFrame*timePerLineUsec;
frameRateHz = 1/(1e-3*timePerFrameMsec);
fprintf('Lines per frame %d; time per frame msec %0.6f; frame rate Hz %0.4f\n', ...
    linesPerFrame,timePerFrameMsec,frameRateHz);
