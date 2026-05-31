function [meanCurv, maxCurv, stdCurv, note] = compute_curvature_metrics(coords, numNeighbours)
% COMPUTE_CURVATURE_METRICS  Compute curvature summary from point cloud.
%
% Uses findPointNormals to estimate pointwise curvature and returns mean,
% max, and standard deviation on finite values.

meanCurv = NaN;
maxCurv = NaN;
stdCurv = NaN;
note = "";

if nargin < 2
    numNeighbours = 20;
end

if size(coords, 1) < 10
    note = "Too few points for curvature estimation.";
    return;
end

try
    [~, curvatures] = findPointNormals(coords, numNeighbours, [], []);
catch ME
    note = "Curvature estimation failed: " + string(ME.message);
    return;
end

validCurv = curvatures(isfinite(curvatures));
if isempty(validCurv)
    note = "Curvature values are empty.";
    return;
end

meanCurv = mean(validCurv);
maxCurv = max(validCurv);
stdCurv = std(validCurv);
end
