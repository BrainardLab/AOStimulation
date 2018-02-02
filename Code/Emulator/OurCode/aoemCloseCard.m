function status = aoemCloseCard(cardInfo)
% Close down the D/A card gracefully
%
% Syntax:
%
% Description:
%    This command closes down the card when we are finished.
spcMCloseCard (cardInfo);
