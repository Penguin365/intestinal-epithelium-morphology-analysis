function [isValid, validityNotes] = check_result_validity(runFolder, timePoints, selectedTimePoint, cellData)
% CHECK_RESULT_VALIDITY  Check whether one run is usable for measurement.
%
% This function performs small, practical checks before measurement:
% required files exist, selected time point exists, and usable height data
% are present in the loaded table.
%
% Inputs:
%   runFolder - Path to one simulation result folder.
%   timePoints - Available time points from get_time_points.
%   selectedTimePoint - Time point chosen for measurement.
%   cellData - Loaded cell data table.
%
% Outputs:
%   isValid - Logical flag.
%   validityNotes - Short note describing the check result.

isValid = true;
notes = strings(0, 1);

if ~isfolder(runFolder)
    isValid = false;
    notes(end+1) = "Run folder not found.";
end

if isempty(timePoints)
    isValid = false;
    notes(end+1) = "No cell_data files were found.";
end

if ~any(timePoints == selectedTimePoint)
    isValid = false;
    notes(end+1) = "Selected time point is not available.";
end

if isempty(cellData)
    isValid = false;
    notes(end+1) = "Loaded cell data are empty.";
end

requiredVars = {"x", "y", "z"};
for i = 1:numel(requiredVars)
    if ~ismember(requiredVars{i}, cellData.Properties.VariableNames)
        isValid = false;
        notes(end+1) = "Required coordinate columns are missing.";
        break;
    end
end

if ~isempty(cellData) && ismember("y", cellData.Properties.VariableNames)
    y = cellData.y;
    if all(~isfinite(y))
        isValid = false;
        notes(end+1) = "Height values are not finite.";
    end
end

if isValid
    validityNotes = "Required cell data were found and are usable.";
else
    validityNotes = strjoin(notes, " ");
end
end
