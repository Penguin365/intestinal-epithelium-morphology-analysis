function timePoints = get_time_points(runFolder)
% GET_TIME_POINTS  List available simulation time points for one run.
%
% This function scans cellData/cell_data_time_*.dat under a selected run
% folder and returns sorted time points as numeric values.
%
% Input:
%   runFolder - Path to one simulation result folder.
%
% Output:
%   timePoints - Sorted numeric vector of available time points.

files = dir(fullfile(runFolder, 'cellData', 'cell_data_time_*.dat'));
if isempty(files)
    timePoints = [];
    return;
end

tokens = regexp({files.name}, 'cell_data_time_(\d+)\.dat', 'tokens', 'once');
timePoints = nan(size(tokens));
for i = 1:numel(tokens)
    timePoints(i) = str2double(tokens{i}{1});
end
timePoints = sort(timePoints(:))';
end
