function predTime =aoTimePrediction(stripInfo,sysPara,maxMovieLength)
% According to the current strip's movement, predict the time to stimulus
%
% Syntax:
%    predTime = aoTimePrediction(stripInfo,sysPara,maxMovieLength)
%
% Description:
%    Time prediction, so that we can drive the stimulus laser of SOM
%
% Inputs:
%    stripInfo          - Registration information for each strip in each
%                         frame in the input desinMovies
%    sysPara            - system parameters
%    maxMovieLength     - maximum frame number
% Outputs:
%    predTime           - Computed time for stimulus delivery.
%
% Optional key/value pairs:
%    
% See also:
%

% History:
%   04/10/18  tyh

% Strips numbers for target dilieray
nStrips = 1;

% Main loop
for frameIdx=2:maxMovieLength
    
    if (stripInfo(frameIdx).frameAvailableFlag == 1)
        %initialize the time counter
        stripIdx = 1;
        
        %strip loop
        while (nStrips>0)
            
            %Get the current strip position
            curStripx = stripInfo(frameIdx,stripIdx).dx+stripIdx+sysPara.shrinkSize;
            curStripy = stripInfo(frameIdx,stripIdx).dy+1+sysPara.shrinkSize;
            
            %Calculate the time from current strip to target line
            timewholeLinesToStimulus = (sysPara.stimulusPositionx-curStripx)...
                *sysPara.timePerLine;
            
            %Calculate the time from line start to stimulus target point
            timePartialLineToStimulus = sysPara.stimulusPositiony*sysPara.pixTime...
                +sysPara.hrFrontPorch*sysPara.pixTime;
            
            % if the current strip arrive the line of the stimulus, stop this frame and go to next frame
            if (timewholeLinesToStimulus == 0)
                break;
            else
                %Add the above time to get the prediction time. 
                predTime(stripIdx,frameIdx) = timewholeLinesToStimulus+timePartialLineToStimulus;
            end
            
            %counter add 1
            stripIdx = stripIdx+1;
            
            
        end
    end
    
end


end



