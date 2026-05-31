function [peakRatio, firstBinIsPeak] = compute_pca_peak_ratio(coords)
% COMPUTE_PCA_PEAK_RATIO  Estimate PCA thickness peak ratio from coordinates.
%
% Computes local PCA thickness in neighbourhoods and returns the ratio of
% the first histogram bin to the largest remaining bin. Also returns
% whether the first bin is the global histogram peak.

peakRatio = NaN;
firstBinIsPeak = false;
if size(coords, 1) < 20
    return;
end

[~, d1] = knnsearch(coords, coords, 'K', 2);
dMed = median(d1(:, 2), 'omitnan');
if ~isfinite(dMed) || dMed <= 0
    return;
end

cellDiam = 1.0;
radius = 1.5 * cellDiam;
[idxR, ~] = rangesearch(coords, coords, radius);

n = size(coords, 1);
localThickness = nan(n, 1);
for i = 1:n
    nbrs = coords(idxR{i}, :);
    if size(nbrs, 1) < 5
        continue;
    end

    X = nbrs - mean(nbrs, 1);
    C = (X' * X) / size(X, 1);
    [V, ~] = eig(C);
    normal = V(:, 1);
    proj = X * normal;
    localThickness(i) = max(proj) - min(proj);
end

tNorm = localThickness / dMed;
tValid = tNorm(~isnan(tNorm));
if numel(tValid) < 10
    return;
end

counts = histcounts(tValid, 40, 'Normalization', 'probability');
if numel(counts) < 2
    return;
end

firstBin = counts(1);
firstBinIsPeak = (firstBin == max(counts));
maxOther = max(counts(2:end));
if maxOther > 0
    peakRatio = firstBin / maxOther;
end
end
