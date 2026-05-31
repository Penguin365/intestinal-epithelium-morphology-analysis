function [softCount, hardCount, note] = read_celltypes_from_viz(runFolder, selectedTimePoint)
% READ_CELLTYPES_FROM_VIZ  Read hard/soft cell counts from results.vizcelltypes.
%
% Uses the selected time point to map to the corresponding line in
% results.vizcelltypes and returns counts for type 1 (soft) and type 0
% (hard) cells.

softCount = NaN;
hardCount = NaN;
note = "";

vizFile = fullfile(runFolder, 'results_from_time_0', 'results.vizcelltypes');
if ~isfile(vizFile)
    note = "results.vizcelltypes not found; type counts left as NaN.";
    return;
end

targetLine = floor(selectedTimePoint / 50) + 1;
fid = fopen(vizFile, 'r');
if fid == -1
    note = "Could not open results.vizcelltypes; type counts left as NaN.";
    return;
end

allLines = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
allLines = string(allLines{1});

if targetLine < 1 || targetLine > numel(allLines)
    note = "Selected time point line not present in results.vizcelltypes.";
    return;
end

lineData = strtrim(allLines(targetLine));
parts = split(lineData);
parts(parts == "") = [];

if numel(parts) <= 1
    note = "No cell type entries at selected time point.";
    softCount = 0;
    hardCount = 0;
    return;
end

typeVals = str2double(parts(2:end));
typeVals = typeVals(~isnan(typeVals));

softCount = sum(typeVals == 1);
hardCount = sum(typeVals == 0);

if isempty(typeVals)
    note = "Cell type entries could not be parsed.";
end
end
