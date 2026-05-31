function topology = read_topology_results(topologyFile, runId, selectedTimePoint)
% READ_TOPOLOGY_RESULTS  Read optional BPA topology CSV for one run.
%
% This function reads a Python-generated topology CSV when present and
% returns one matched row for run_id/time_point. If the CSV is missing,
% topology fields are left as NaN with a clear status note.
%
% Inputs:
%   topologyFile - Path to bpa_topology_measurements.csv.
%   runId - Selected run label.
%   selectedTimePoint - Time point used by MATLAB measurement.
%
% Output:
%   topology - Structure with scalar topology fields and notes.

topology = struct( ...
    'components', NaN, ...
    'holes', NaN, ...
    'genus', NaN, ...
    'boundary_edges', NaN, ...
    'vertices', NaN, ...
    'edges', NaN, ...
    'faces', NaN, ...
    'bpa_pass', NaN, ...
    'topology_status', "not_available", ...
    'topology_notes', "BPA/topology results not available.");

if ~isfile(topologyFile)
    return;
end

T = readtable(topologyFile, 'TextType', 'string');
if isempty(T)
    topology.topology_status = "empty";
    topology.topology_notes = "Topology CSV exists but is empty.";
    return;
end

rowIdx = 1;

if ismember('run_id', T.Properties.VariableNames)
    idx = strcmp(string(T.run_id), string(runId));
elseif ismember('label', T.Properties.VariableNames)
    idx = strcmp(string(T.label), string(runId));
else
    idx = false(height(T), 1);
end

if any(idx)
    cand = find(idx);
    timeVar = '';
    if ismember('time_point', T.Properties.VariableNames)
        timeVar = 'time_point';
    elseif ismember('timestep', T.Properties.VariableNames)
        timeVar = 'timestep';
    end

    if ~isempty(timeVar)
        dt = abs(T.(timeVar)(cand) - selectedTimePoint);
        [~, k] = min(dt);
        rowIdx = cand(k);
    else
        rowIdx = cand(1);
    end
end

row = T(rowIdx, :);

names = string(T.Properties.VariableNames);
map = {
    'components', 'components';
    'holes', 'holes';
    'genus', 'genus';
    'boundary_edges', 'boundary_edges';
    'vertices', 'vertices';
    'edges', 'edges';
    'faces', 'faces';
    'bpa_pass', 'bpa_pass'
};

for i = 1:size(map, 1)
    src = map{i, 1};
    dst = map{i, 2};
    if any(names == src)
        topology.(dst) = row.(src);
    end
end

if any(names == 'topology_status')
    topology.topology_status = string(row.topology_status);
elseif any(names == 'status')
    topology.topology_status = string(row.status);
else
    topology.topology_status = "available";
end

if any(names == 'notes')
    topology.topology_notes = string(row.notes);
elseif any(names == 'topology_notes')
    topology.topology_notes = string(row.topology_notes);
else
    topology.topology_notes = "Topology row loaded from CSV.";
end
end
