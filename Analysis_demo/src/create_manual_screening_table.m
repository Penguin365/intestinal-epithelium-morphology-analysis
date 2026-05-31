function manualTable = create_manual_screening_table(runIds, manualCsv)
% CREATE_MANUAL_SCREENING_TABLE  Create or update manual screening labels.
%
% Loads an existing manual screening CSV when available, appends missing
% runs with default labels, marks whether each row is present in the
% current data folders, and writes the updated table back to CSV.

runIds = string(runIds(:));

if isfile(manualCsv)
    T = readtable(manualCsv, 'TextType', 'string', 'VariableNamingRule', 'preserve');
else
    T = table();
end

if isempty(T)
    T = table(string.empty(0, 1), string.empty(0, 1), string.empty(0, 1), false(0, 1), string.empty(0, 1), ...
        'VariableNames', {'run_id', 'manual_status', 'manual_notes', 'use_for_analysis', 'screening_method'});
end

requiredNames = {'run_id', 'manual_status', 'manual_notes', 'use_for_analysis', 'screening_method'};
for i = 1:numel(requiredNames)
    if ~ismember(requiredNames{i}, T.Properties.VariableNames)
        switch requiredNames{i}
            case 'run_id'
                T.run_id = strings(height(T), 1);
            case 'manual_status'
                T.manual_status = repmat("unchecked", height(T), 1);
            case 'manual_notes'
                T.manual_notes = strings(height(T), 1);
            case 'use_for_analysis'
                T.use_for_analysis = false(height(T), 1);
            case 'screening_method'
                T.screening_method = repmat("UMC", height(T), 1);
        end
    end
end

T = T(:, requiredNames);
T.run_id = string(T.run_id);
T.manual_status = string(T.manual_status);
T.manual_notes = string(T.manual_notes);
T.use_for_analysis = logical(T.use_for_analysis);
T.screening_method = string(T.screening_method);

% Remove empty placeholder rows from older CSV versions.
nonEmptyRun = strlength(strtrim(T.run_id)) > 0;
T = T(nonEmptyRun, :);

existingRuns = string(T.run_id);
missingRuns = runIds(~ismember(runIds, existingRuns));

if ~isempty(missingRuns)
    addT = table(missingRuns, repmat("unchecked", numel(missingRuns), 1), strings(numel(missingRuns), 1), ...
        false(numel(missingRuns), 1), repmat("UMC", numel(missingRuns), 1), ...
        'VariableNames', requiredNames);
    T = [T; addT];
end

% Keep one default selected run when the table has no active rows.
if ~isempty(runIds) && ~any(T.use_for_analysis)
    firstPresent = find(ismember(string(T.run_id), runIds), 1, 'first');
    if ~isempty(firstPresent)
        T.manual_status(firstPresent) = "pass";
        if strlength(strtrim(T.manual_notes(firstPresent))) == 0
            T.manual_notes(firstPresent) = "Selected example run.";
        end
        T.use_for_analysis(firstPresent) = true;
        T.screening_method(firstPresent) = "UMC";
    end
end

T.run_present = ismember(string(T.run_id), runIds);

writetable(T, manualCsv);
manualTable = T;
end
