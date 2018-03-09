function status = aoemCloseCard(cardInfo)
% Close the DAC card.
%
% Syntax:
%    status = aoemCloseCard(cardInfo)
%
% Description:
%    Close the DAC card.
%
% Inputs:
%    cardInfo           - Struct with DAC card information
%    
% Outputs:
%    status             - Boolean. True means success, false means failure of
%                         some sort.   
%
% Optional key/value pairs:
%    None.

% History:
%   02/02/18  tyh, dhb   Wrote header comments.

% Call into API to do this.
spcMCloseCard(cardInfo);
