% RUN_ANALYSIS_DEMO
%
% Demo analysis pipeline for ChipFrame simulation results.
% The script loads selected result folders, checks whether the data are
% usable, applies user manual check/count, calculates key morphology
% measurements, and writes a summary table.

clear; clc;

% Paths for this analysis package.
demoDir = fileparts(mfilename('fullpath'));
addpath(fullfile(demoDir, 'src'));
addpath(fullfile(demoDir, 'external'));

dataDir = fullfile(demoDir, 'example_data');
outputDir = fullfile(demoDir, 'demo_output');
manualCsv = fullfile(outputDir, 'manual_screening.csv');
topologyFile = fullfile(outputDir, 'bpa_topology_measurements.csv');

if ~isfolder(outputDir)
    mkdir(outputDir);
end

% Find all run folders in example_data.
runDirs = dir(dataDir);
runDirs = runDirs([runDirs.isdir]);
runDirs = runDirs(~ismember({runDirs.name}, {'.', '..'}));

if isempty(runDirs)
    error('No run folder found under example_data.');
end

runNames = string(sort({runDirs.name}))';
runNames = strtrim(runNames);
manualTable = create_manual_screening_table(runNames, manualCsv);
manualRunIds = strtrim(string(manualTable.run_id));

selectedMask = logical(manualTable.use_for_analysis);

selectedRuns = manualRunIds(selectedMask);
selectedRuns = selectedRuns(ismember(selectedRuns, runNames));
if isempty(selectedRuns)
    selectedRuns = runNames(1);
end

summaryTable = table();
targetTimePoint = 19200;
pcaPassRatioThreshold = 2.0;

% Main loop over selected runs.
for i = 1:numel(selectedRuns)
    selectedRun = selectedRuns(i);
    runFolder = fullfile(dataDir, selectedRun);

    timePoints = get_time_points(runFolder);
    if isempty(timePoints)
        error('No cell_data_time_*.dat files found in %s', runFolder);
    end

    if any(timePoints == targetTimePoint)
        selectedTimePoint = targetTimePoint;
    else
        selectedTimePoint = timePoints(end);
    end

    [cellData, dataFile] = load_cell_data(runFolder, selectedTimePoint);
    [isValid, validityNotes] = check_result_validity(runFolder, timePoints, selectedTimePoint, cellData);

    % PCA is used as a screening criterion, not as a morphology metric.
    coords = [cellData.x, cellData.y, cellData.z];
    [pcaPeakRatio, pcaFirstBinIsPeak] = compute_pca_peak_ratio(coords);
    pcaPass = pcaFirstBinIsPeak && isfinite(pcaPeakRatio) && pcaPeakRatio >= pcaPassRatioThreshold;

    manualIdx = find(strcmp(manualRunIds, strtrim(selectedRun)), 1, 'first');
    if isempty(manualIdx)
        manualStatus = "unchecked";
        manualNotes = "No manual screening record found for this run.";
        useForAnalysis = false;
        screeningMethod = "UMC";
    else
        manualStatus = string(manualTable.manual_status(manualIdx));
        manualNotes = string(manualTable.manual_notes(manualIdx));
        useForAnalysis = logical(manualTable.use_for_analysis(manualIdx));
        screeningMethod = string(manualTable.screening_method(manualIdx));
    end

    measurements = calculate_measurements(cellData, runFolder, selectedTimePoint);
    topology = read_topology_results(topologyFile, selectedRun, selectedTimePoint);

    row = table();
    row.run_id = selectedRun;
    row.data_file = string(dataFile);
    row.selected_time_point = selectedTimePoint;
    row.selected_days = selectedTimePoint / 2400;
    row.is_valid = isValid;
    row.validity_notes = validityNotes;
    row.manual_status = manualStatus;
    row.manual_notes = manualNotes;
    row.use_for_analysis = useForAnalysis;
    row.screening_method = screeningMethod;
    row.simulation_complete = (selectedTimePoint >= targetTimePoint);
    row.pca_peak_ratio = pcaPeakRatio;
    row.pca_pass = pcaPass;

    row.total_cell_number = measurements.total_cell_number;
    row.hard_cell_count = measurements.hard_cell_count;
    row.soft_cell_count = measurements.soft_cell_count;
    row.mean_height = measurements.mean_height;
    row.max_height = measurements.max_height;
    row.height_std = measurements.height_std;
    row.surface_variation = measurements.surface_variation;
    row.villi_xy_count = measurements.villi_xy_count;
    row.villi_heightmap_count = measurements.villi_heightmap_count;
    row.mean_curvature = measurements.mean_curvature;
    row.max_curvature = measurements.max_curvature;
    row.std_curvature = measurements.std_curvature;
    row.measurement_notes = measurements.notes;

    row.components = topology.components;
    row.holes = topology.holes;
    row.genus = topology.genus;
    row.boundary_edges = topology.boundary_edges;
    row.vertices = topology.vertices;
    row.edges = topology.edges;
    row.faces = topology.faces;
    row.bpa_pass = topology.bpa_pass;
    row.enter_next_step = row.simulation_complete && row.pca_pass && (topology.bpa_pass == 1);
    row.topology_status = topology.topology_status;
    row.topology_notes = topology.topology_notes;

    summaryTable = [summaryTable; row];
end

% Write summary outputs.
csvFile = fullfile(outputDir, 'summary_measurements.csv');
matFile = fullfile(outputDir, 'summary_measurements.mat');
write_summary_table(summaryTable, csvFile, matFile);

fprintf('=== Analysis Demo Summary ===\n');
fprintf('Runs found: %d | Analysed: %d\n', numel(runNames), height(summaryTable));
fprintf('Latest analysed run: %s\n', summaryTable.run_id(end));
fprintf('Time point: %d (%.2f days)\n', summaryTable.selected_time_point(end), summaryTable.selected_days(end));
fprintf('Valid: %d\n', summaryTable.is_valid(end));
fprintf('Cells: %d | Mean height: %.3f | Max height: %.3f\n', ...
    summaryTable.total_cell_number(end), summaryTable.mean_height(end), summaryTable.max_height(end));
fprintf('Topology status: %s\n', summaryTable.topology_status(end));
fprintf('Saved: %s\n', csvFile);
fprintf('Saved: %s\n', matFile);
