function measurements = calculate_measurements(cellData, runFolder, selectedTimePoint)
% CALCULATE_MEASUREMENTS  Calculate morphology measurements from cell data.
%
% Computes cell number, height statistics, cell-type counts, and selected
% morphology metrics for one analysed time point.
%
% Inputs:
%   cellData - Table returned by load_cell_data.
%   runFolder - Path to selected run folder.
%   selectedTimePoint - Time point used for measurement.
%
% Output:
%   measurements - Structure with scalar metrics used in the summary table.

measurements = struct();
measurements.total_cell_number = NaN;
measurements.hard_cell_count = NaN;
measurements.soft_cell_count = NaN;
measurements.mean_height = NaN;
measurements.max_height = NaN;
measurements.height_std = NaN;
measurements.surface_variation = NaN;
measurements.villi_xy_count = NaN;
measurements.villi_heightmap_count = NaN;
measurements.mean_curvature = NaN;
measurements.max_curvature = NaN;
measurements.std_curvature = NaN;
measurements.notes = "";

if isempty(cellData)
    measurements.notes = "Cell table is empty.";
    return;
end

y = cellData.y;
coords = [cellData.x, cellData.y, cellData.z];

measurements.total_cell_number = height(cellData);
measurements.mean_height = mean(y, 'omitnan');
measurements.max_height = max(y);
measurements.height_std = std(y, 'omitnan');

[softCount, hardCount, cellTypeNote] = read_celltypes_from_viz(runFolder, selectedTimePoint);
measurements.soft_cell_count = softCount;
measurements.hard_cell_count = hardCount;

% Villi count method 1: XY alpha-shape profile peaks.
villiXYNote = "";
try
    [villiXY, ~, ~, ~, ~, ~] = countVilli_XY_alphashape(coords, false);
    measurements.villi_xy_count = villiXY;
catch ME
    villiXYNote = "XY villi count not available: " + string(ME.message);
end

% Villi count method 2: heightmap regional maxima.
villiHmNote = "";
try
    numBins = 50;
    x_min = min(coords(:, 1));
    x_max = max(coords(:, 1));
    z_min = min(coords(:, 3));
    z_max = max(coords(:, 3));
    x_centers = linspace(x_min, x_max, numBins);
    z_centers = linspace(z_min, z_max, numBins);
    [X_grid, Z_grid] = meshgrid(x_centers, z_centers);
    H_filled = griddata(coords(:, 1), coords(:, 3), coords(:, 2), X_grid, Z_grid, 'linear');
    nonNanHeights = H_filled(~isnan(H_filled));
    if ~isempty(nonNanHeights)
        baseValue = min(nonNanHeights) - 0.1;
        H_filled(isnan(H_filled)) = baseValue;
    else
        H_filled = zeros(numBins);
    end
    [villiHM, ~, ~] = countVilli_Heightmap(H_filled, x_centers, z_centers);
    measurements.villi_heightmap_count = villiHM;
catch ME
    villiHmNote = "Heightmap villi count not available: " + string(ME.message);
end

% Curvature from third-party normal estimation code.
[meanCurv, maxCurv, stdCurv, curvNote] = compute_curvature_metrics(coords, 20);
measurements.mean_curvature = meanCurv;
measurements.max_curvature = maxCurv;
measurements.std_curvature = stdCurv;
% Keep consistency with original pipeline where Curvature used MeanCurvature.
measurements.surface_variation = meanCurv;

noteParts = strings(0, 1);
if strlength(cellTypeNote) > 0
    noteParts(end+1) = cellTypeNote;
end
if strlength(villiXYNote) > 0
    noteParts(end+1) = villiXYNote;
end
if strlength(villiHmNote) > 0
    noteParts(end+1) = villiHmNote;
end
if strlength(curvNote) > 0
    noteParts(end+1) = curvNote;
end
if isempty(noteParts)
    measurements.notes = "Core measurements calculated.";
else
    measurements.notes = strjoin(noteParts, " ");
end
end
