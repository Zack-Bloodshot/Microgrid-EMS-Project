function startup()
%STARTUP Add all project folders to the MATLAB path.
%
%   Run this once per MATLAB session before using any project functions:
%       startup
%
%   Adds the root Matlab folder and all subfolders (Phase0, Phase1, Phase2,
%   Comparison) to the path so all functions are available.

    matlab_dir = fileparts(mfilename('fullpath'));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Phase0'), ...
        fullfile(matlab_dir, 'Phase1'), ...
        fullfile(matlab_dir, 'Phase2'), ...
        fullfile(matlab_dir, 'Comparison'));

    fprintf('Project path added: %s\n', matlab_dir);
end
