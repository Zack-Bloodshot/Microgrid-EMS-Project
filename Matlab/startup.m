function startup()
%STARTUP Add all project folders to the MATLAB path.
%
%   Run this once per MATLAB session before using any project functions:
%       startup
%
%   Adds the root Matlab folder and all subfolders (Stage0, Stage1, Stage2,
%   Stage3, Comparison) to the path so all functions are available.

    matlab_dir = fileparts(mfilename('fullpath'));
    addpath(matlab_dir, ...
        fullfile(matlab_dir, 'Stage0'), ...
        fullfile(matlab_dir, 'Stage1'), ...
        fullfile(matlab_dir, 'Stage2'), ...
        fullfile(matlab_dir, 'Stage3'), ...
        fullfile(matlab_dir, 'Comparison'));

    fprintf('Project path added: %s\n', matlab_dir);
end
