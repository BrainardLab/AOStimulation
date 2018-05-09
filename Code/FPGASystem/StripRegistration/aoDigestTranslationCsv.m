function aoDigestTranslationCsv(translationCsvFile)
% Read in a magic file that gives the alignment info from Alf's alignment
%
% Syntax:
%
% Description:
%    Alf's demotion software produces output that gives the row by row
%    estimates of shift.  Rob wrote a program that reads the python .dmp
%    file and produces a summary file of the translations.  We then read 
%    this file in and process it to get the estimated eye position shifts
%    for each row in each frame.
%
% Inputs:
%    translationCsvFile       - String.  Filename of translation csf file.
%
% Outputs:
%
% Optional key/value pairs:
%
% See also:
% 

% History:
%   05/09/18  dhb, rc, tyh  Started on it.

% Read file
% 
% Try textread, dlmread, csvread