function [numVilli, relativeHeight, xCenters, valleyIdx, peakIdx, dbg] = countVilli_XY_alphashape(coords, plotFlag)
% COUNTVILLI_XY_ALPHASHAPE  Count villus-like peaks from XY projection.
%
% Builds an alpha shape on the XY projection, creates a raster mask, then
% derives a height profile (y_top - y_bot) along X and counts peaks.

if nargin < 2
    plotFlag = false;
end

alphaScaleFactor = 7.25;
gridRes = 0.05;
binWidth = 0.25;
minProm = 0.4;
minPeakDistX = 2.0;
edgeMargin = 1.0;

if size(coords, 2) < 2
    [numVilli, relativeHeight, xCenters, valleyIdx, peakIdx] = deal(NaN, [], [], [], []);
    dbg = struct('reason', 'coords must be Nx2 or Nx3.');
    return;
end

xy = coords(:, 1:2);
xy = xy(all(isfinite(xy), 2), :);
if size(xy, 1) < 20
    [numVilli, relativeHeight, xCenters, valleyIdx, peakIdx] = deal(NaN, [], [], [], []);
    dbg = struct('reason', 'Too few points.');
    return;
end

x = xy(:, 1);
y = xy(:, 2);
xmin = min(x);
xmax = max(x);
ymin = min(y);
ymax = max(y);

[~, D] = knnsearch(xy, xy, 'K', 2);
medSpacing = median(D(:, 2));
alpha = alphaScaleFactor * medSpacing;
shp = alphaShape(x, y, alpha);

xGrid = xmin:gridRes:xmax;
yGrid = ymin:gridRes:ymax;
[Xq, Yq] = meshgrid(xGrid, yGrid);
inside = inShape(shp, Xq(:), Yq(:));
mask = reshape(inside, size(Xq));

xEdges = xmin:binWidth:(xmax + binWidth);
nBins = numel(xEdges) - 1;
xCenters = (xEdges(1:end-1) + xEdges(2:end)) / 2;

yTopBin = nan(1, nBins);
yBotBin = nan(1, nBins);
for b = 1:nBins
    colMask = xGrid >= xEdges(b) & xGrid < xEdges(b + 1);
    if ~any(colMask)
        continue;
    end
    slice = any(mask(:, colMask), 2);
    rows = find(slice);
    if isempty(rows)
        continue;
    end
    yTopBin(b) = yGrid(rows(end));
    yBotBin(b) = yGrid(rows(1));
end

yTopBin = fillmissing(yTopBin, 'linear', 'EndValues', 'nearest');
yBotBin = fillmissing(yBotBin, 'linear', 'EndValues', 'nearest');
relativeHeight = yTopBin - yBotBin;

minPeakDistBins = max(1, round(minPeakDistX / binWidth));
[~, peakIdx] = findpeaks(relativeHeight, 'MinPeakProminence', minProm, 'MinPeakDistance', minPeakDistBins);
[~, valleyIdx] = findpeaks(-relativeHeight, 'MinPeakProminence', minProm / 2, 'MinPeakDistance', minPeakDistBins);

keepPeak = xCenters(peakIdx) > xmin + edgeMargin & xCenters(peakIdx) < xmax - edgeMargin;
peakIdx = peakIdx(keepPeak);
numVilli = numel(peakIdx);

dbg = struct();
dbg.medSpacing = medSpacing;
dbg.alpha = alpha;
dbg.gridRes = gridRes;
dbg.binWidth = binWidth;
dbg.relativeHeight = relativeHeight;

if plotFlag
    figure('Name', 'XY Villi Count (Alpha Shape)', 'Position', [100 100 1100 500]);
    subplot(1, 2, 1);
    imagesc(xGrid, yGrid, mask);
    axis xy;
    axis tight;
    hold on;
    scatter(x, y, 4, [0.35 0.35 0.35], 'filled', 'MarkerFaceAlpha', 0.4);
    plot(xCenters, yTopBin, '-', 'LineWidth', 1.5);
    plot(xCenters, yBotBin, '-', 'LineWidth', 1.5);
    if ~isempty(peakIdx)
        scatter(xCenters(peakIdx), yTopBin(peakIdx), 80, '^', 'filled');
    end
    if ~isempty(valleyIdx)
        scatter(xCenters(valleyIdx), yTopBin(valleyIdx), 80, 'v', 'filled');
    end
    grid on;
    box on;

    subplot(1, 2, 2);
    plot(xCenters, relativeHeight, '-', 'LineWidth', 1.8);
    hold on;
    if ~isempty(peakIdx)
        scatter(xCenters(peakIdx), relativeHeight(peakIdx), 80, '^', 'filled');
    end
    if ~isempty(valleyIdx)
        scatter(xCenters(valleyIdx), relativeHeight(valleyIdx), 80, 'v', 'filled');
    end
    grid on;
    box on;
end
end
