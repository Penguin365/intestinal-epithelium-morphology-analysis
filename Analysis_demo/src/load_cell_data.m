function [cellData, dataFile] = load_cell_data(runFolder, timePoint)
% LOAD_CELL_DATA  Load one cell_data_time_*.dat file for a selected run.
%
% This function reads one selected time point file and returns both a table
% with standardised x/y/z columns and the source filename.
%
% Inputs:
%   runFolder - Path to one simulation result folder.
%   timePoint - Integer time point from available files.
%
% Outputs:
%   cellData - Table containing all raw columns and x/y/z aliases.
%   dataFile - Full path to the loaded file.

dataFile = fullfile(runFolder, 'cellData', sprintf('cell_data_time_%d.dat', timePoint));
if ~isfile(dataFile)
    error('Cell data file not found: %s', dataFile);
end

raw = readmatrix(dataFile);
if isempty(raw)
    cellData = table();
    return;
end

nCols = size(raw, 2);
varNames = strings(1, nCols);
for i = 1:nCols
    varNames(i) = sprintf('col%d', i);
end

cellData = array2table(raw, 'VariableNames', cellstr(varNames));

% Chaste cell_data files use columns 3:5 for x/y/z in this workflow.
cellData.x = raw(:, 3);
cellData.y = raw(:, 4);
cellData.z = raw(:, 5);
end
