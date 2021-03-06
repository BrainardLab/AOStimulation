function AOStimulationLocalHook
% Configure things for working ASStimulation projects.
%
% For use with the ToolboxToolbox.  If you copy this into your
% ToolboxToolbox localToolboxHooks directory (by default,
% ~/localToolboxHooks) and delete "LocalHooksTemplate" from the filename,
% this will get run when you execute
%   tbUseProject('AOStimulation')
% to set up for this project.  You then edit your local copy to match your local machine.
%
% The main thing that this does is define Matlab preferences that specify input and output
% directories.
%
% You will need to edit the project location and i/o directory locations
% to match what is true on your computer.

%% Say hello
theProject = 'AOStimulation';
fprintf('Running %s local hook\n',theProject);

%% Remove old preferences
if (ispref(theProject))
    rmpref(theProject);
end

%% Define prefs for working directories
if (ispc)
    % If it is a PC, it's Hong for right now.
    setpref(theProject,'MovieBaseDir', '.\data\');
    setpref(theProject,'OutputBaseDir', '.data\TestOutput');
else
    [~, userID] = system('whoami');
    userID = strtrim(userID);
    switch userID
        case {'dhb'}
            setpref(theProject,'MovieBaseDir', '/Volumes/Users1/Dropbox (Aguirre-Brainard Lab)/AOFN_data/AOFPGATestData/TestMovies');
            setpref(theProject,'OutputBaseDir', '/Volumes/Users1/Dropbox (Aguirre-Brainard Lab)/AOFN_data/AOFPGATestData/TestOutput');        
        otherwise
            setpref(theProject,'MovieBaseDir', ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_materials/AOFN_data/AOFPGATestData/TestMovies']);
            setpref(theProject,'OutputBaseDir', ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_materials/AOFN_data/AOFPGATestData/TestOutput']);        
    end
end

