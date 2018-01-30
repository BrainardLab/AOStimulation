%**************************************************************************
% AOSLO emulator               yinghong , 01/2018
%**************************************************************************
%**************************************************************************
% tyh_spcMCalcSignal:
% Calculates waveform data 
% shape: 1 : sine
%        2 : rectangel
%        3 : triangel
%        4 : sawtooth
%**************************************************************************

function [success, cardInfo, signal] = tyh_spcMCalcSignal (cardInfo, len, shape, loops, gainP,time_sync,time_back_porch,time_active,time_front_porch)
    
    shape = 2;
    hr_len = time_sync + time_back_porch + time_active + time_front_porch;
    loops = fix(len/hr_len);
    signal = zeros (1, len);

    if (gainP < 0) | (gainP > 100)
        cardInfo.errorText = 'spcMCalcSignal: gainP must be a value between 0 and 100';
        success = false;
        return;
    end

    if (shape < 1) | (shape > 4)
        cardInfo.errorText = 'spcMCalcSignal: shape must set to 1 (sine), 2 (rectangel), 3 (triangel), 4 (sawtooth)';
        success = false;
        return;
    end
    
    % ----- calculate resolution -----
    switch cardInfo.bytesPerSample
         
         case 1
             maxFS = 127;
             minFS = -128;
             scale = 127 * gainP / 100;
             
         case 2
             maxFS = 8191;
             minFS = -8192;
             scale = 8191 * gainP / 100;
     end
    
     % ----- calculate waveform -----
     block = len / loops;
     blockHalf = block / 2;
     sineXScale = 2 * pi / len * loops;
     span = maxFS - minFS;
     
     for i=1 : len
    
        posInBlock = mod (i, block);
        
        switch shape
            
            % ----- sine -----
            case 1
                signal (1, i) = scale * sin (sineXScale*i);
    
            % ----- rectangel -----
            case 2
                if posInBlock < time_sync %blockHalf  %time_sync
                    signal (1, i) = maxFS;
                else
                    signal (1, i) = minFS;
                end
            
           % ----- triangel -----
           case 3
               if posInBlock < blockHalf
                   signal (1, i) = minFS + posInBlock * span / blockHalf;
              else
                   signal (1, i) = maxFS - (posInBlock - blockHalf) * span / blockHalf;
              end     
         
          % ----- sawtooth -----
          case 4            
            signal (1, i) = minFS + posInBlock * span / block;
        end    
    end
    
    success = true;
