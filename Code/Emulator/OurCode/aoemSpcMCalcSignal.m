function signal = aoemSpcMCalcSignal (len, shape, loops, gainP,noSync,dac_maxFS,dac_minFS)
% Generate different shapes signals: rectangle, triangle, sawtooth.
%
% Syntax:
%    signal = aoemSpcMCalcSignal(len, shape, loops, gainP,noSync)
%
% Description:
%    Create the signals for Hsync and Vsync.
%
%    The arguments dac_maxFS and dac_minFS give the integer value of the
%    maximum and minimun signal output, where the possible range for these
%    values is -8192 to 8191.  The meaning of this range in volts is
%    determined by how the max output is set for each channel.  In
%    addition, these numbers are scaled by the passed parameter gainP and
%    then divided by 100.  So gainP can be thought of as a channel gain
%    expressed as a percentage of the max
%
% Inputs:
%    len                - signal total length.
%    shape              - signal shape
%                           1 : rectangle
%                           2 : inverted rectangle
%                           3 : triangle
%    loops              - Number of waveform cycles that take place during
%                         the total length of the signal. This implicitly
%                         defines the temporal frequency of the waveform.
%    gainP              - Adjust the signal gain signal.  Percentage of max
%                         available.
%    noSync             - synchronous pulse width
%    dac_maxFS          - max full-scale for DA card
%    dac_minFS          - min full-scale for DA card
%
% Outputs:
%    signal             - generated signal
%
% Optional key/value pairs:
%    None.
%
% See also:

% History:
%   02/02/18  tyh, dhb   Wrote header comments.
%   03/xx/18  tyh        Modified version of code provided by manufacturer.

% Allocate space for signal
signal = zeros (1, len);

% ----- calculate resolution -----
scale = dac_maxFS * gainP / 100;

% ----- calculate waveform -----
block = len / loops;
blockHalf = block / 2;
sineXScale = 2 * pi / len * loops;
span = dac_maxFS - 0;

% We have currently commented out the original sawtooth code, but
% if we wanted it back we might need the bit below as well as the
% corresponding code in the switch statement below.
%
% outputVolt=3;
% baseVoltForSawtooth=2;
% baseVolt=outputVolt-baseVoltForSawtooth;
% 
% span1 = span*baseVoltForSawtooth/outputVolt;
% span2=span*baseVolt/outputVolt;

% This loop builds up the signal over time, where time.
for i=1:len
    
    posInBlock = mod(i, block);
    
    % Switch to handle waveform shape specific calculations.
    switch shape       
        case 1
            % ----- rectangle -----
            if posInBlock < noSync%blockHalf %%/1000/2
                signal (1, i) = 0; %dac_minFS;
            else
                signal (1, i) = dac_maxFS;
            end
            
        case 2
            % ----- rectangle -----
            if posInBlock < noSync%blockHalf %%/1000/2
                signal (1, i) = dac_maxFS;
            else
                signal (1, i) = 0; %dac_minFS;
            end
            
        case 3
            % ----- triangle -----
            if posInBlock < blockHalf
                signal (1, i) = dac_minFS + posInBlock * span / blockHalf;
            else
                signal (1, i) = dac_maxFS - (posInBlock - blockHalf) * span / blockHalf;
            end
            
        % case 4
        %     ----- sawtooth -----
        %     if posInBlock < noSync
        %         signal (1, i) = fix(dac_minFS + span2 + posInBlock * span1/noSync);
        %     else
        %         signal (1, i) = fix(dac_minFS + span2 + span1 - (posInBlock-noSync+1) * span1/(len-noSync));
        %     end
    end
end


