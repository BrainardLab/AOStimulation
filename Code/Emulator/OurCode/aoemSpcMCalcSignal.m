function signal = aoemSpcMCalcSignal (len, shape, loops, gainP,noSync)
% Read in a movie acquired on the real AOSLO for us to play back
%
% Syntax:
%    signal = aoemSpcMCalcSignal (len, shape, loops, gainP,noSync)
% Description:
%    Read in a previously acquired movie that we have stored, and put it
%    into a form to play back.
%
% Get the input movie. Right now we just use one frame for test
% Inputs:
%    movieFileName    - the name of the movie  
%    emulatorParams    - emulator parameters
% 
% Outputs:
%    movie      - one x N array  
% Optional key/value pairs:
%    None.
%
% See also:
%
% History:
%   02/02/18  tyh, dhb   Wrote header comments.
%**************************************************************************
% Spectrum Matlab Library Package               (c) Spectrum GmbH , 11/2006
%**************************************************************************
% Supplies different common functions for Matlab programs accessing the 
% SpcM driver interface. Feel free to use this source for own projects and
% modify it in any kind
%**************************************************************************
% spcMCalcSignal:
% Calculates waveform data 
% shape: 1 : rectangel
%        2 : invert rectangel
%        3 : triangel
%        4 : sawtooth
%**************************************************************************

% NEED TO PASS WIDTH OF PULSE FOR CASE 2


    
    signal = zeros (1, len);

        
    % ----- calculate resolution -----
    
    maxFS = 8191;
    minFS = -8192;
    scale = 8191 * gainP / 100;
   
    
     % ----- calculate waveform -----
     block = len / loops;
     blockHalf = block / 2;
     sineXScale = 2 * pi / len * loops;
     span = maxFS - minFS;
     
     for i=1 : len
    
        posInBlock = mod (i, block);
        
        switch shape
            
            % ----- rectangle -----
            case 1
                if posInBlock < noSync%blockHalf %%/1000/2
                    signal (1, i) = minFS;
                else
                    signal (1, i) = maxFS;
                end
    
            % ----- rectangle -----
            case 2
                if posInBlock < noSync%blockHalf %%/1000/2
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
    
   
