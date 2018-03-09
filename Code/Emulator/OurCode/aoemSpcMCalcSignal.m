function signal = aoemSpcMCalcSignal (len, shape, loops, gainP,noSync,dac_maxFS,dac_minFS)
% generate different shapes signals: rectangel, triangel, sawtooth.
%
% Syntax:
%    signal = aoemSpcMCalcSignal (len, shape, loops, gainP,noSync)
% Description:
%    we create the signals for Hsync and Vsync 
%
% Inputs:
%    len                - signal total length.
%    shape              - signal shape
%                         1 : rectangel
%                         2 : invert rectangel
%                         3 : triangel
%                         
%    loops              - signal cycle under the length
%    gainP              - adjust the signal gain for special application
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
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.
%**************************************************************************

% NEED TO PASS WIDTH OF PULSE FOR CASE 2


    
     signal = zeros (1, len);
% ----- calculate resolution -----
    
     scale = dac_maxFS * gainP / 100;
     % ----- calculate waveform -----
     block = len / loops;
     blockHalf = block / 2;
     sineXScale = 2 * pi / len * loops;
     span = dac_maxFS - 0;
     
% keep for sawtooth signal    
%      outputVolt=3;
%      baseVoltForSawtooth=2;
%      baseVolt=outputVolt-baseVoltForSawtooth;
%      
%      span1 = span*baseVoltForSawtooth/outputVolt;
%      span2=span*baseVolt/outputVolt;
     
     %%%%%%%%%%%%%%%%%
     for i=1 : len
    
        posInBlock = mod (i, block);
        
        switch shape
            
            % ----- rectangle -----
            case 1
                if posInBlock < noSync%blockHalf %%/1000/2
                    signal (1, i) = 0; %dac_minFS;
                else
                    signal (1, i) = dac_maxFS;
                end
    
            % ----- rectangle -----
            case 2
                if posInBlock < noSync%blockHalf %%/1000/2
                    signal (1, i) = dac_maxFS;
                else
                    signal (1, i) = 0; %dac_minFS;
                end
            
           % ----- triangel -----
           case 3
               if posInBlock < blockHalf
                   signal (1, i) = dac_minFS + posInBlock * span / blockHalf;
              else
                   signal (1, i) = dac_maxFS - (posInBlock - blockHalf) * span / blockHalf;
              end     
         
          % ----- sawtooth -----
%           case 4      
%             if posInBlock < noSync
%                 signal (1, i) = fix(dac_minFS + span2 + posInBlock * span1/noSync);
%             else
%                 signal (1, i) = fix(dac_minFS + span2 + span1 - (posInBlock-noSync+1) * span1/(len-noSync));
%             end
          end    
    end
    
   
