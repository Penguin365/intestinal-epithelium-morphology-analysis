function [numVilli, peakPos, H_used] = countVilli_Heightmap(H_filled, x_centers, z_centers)
% COUNTVILLI_HEIGHTMAP  Count villus-like peaks from a 2D height map.
%
% Applies median smoothing, extracts regional maxima, filters peaks using a
% base-height threshold, and returns component count and peak positions.

H_smoothed = medfilt2(H_filled, [3 3]);
H_used = H_smoothed;

baseHeight = min(H_used(:));
minHeightProminence = 0.5;

peak_mask = imregionalmax(H_used);
peak_mask = peak_mask & (H_used > (baseHeight + minHeightProminence));

cc = bwconncomp(peak_mask);
numVilli = cc.NumObjects;

S = regionprops(cc, 'Centroid');
peakPos_idx = vertcat(S.Centroid);

if isempty(peakPos_idx)
    peakPos = [];
else
    peakPos = zeros(size(peakPos_idx, 1), 2);
    peakPos_x_idx = round(peakPos_idx(:, 1));
    peakPos_z_idx = round(peakPos_idx(:, 2));
    peakPos_x_idx = min(max(peakPos_x_idx, 1), numel(x_centers));
    peakPos_z_idx = min(max(peakPos_z_idx, 1), numel(z_centers));
    peakPos(:, 1) = x_centers(peakPos_x_idx);
    peakPos(:, 2) = z_centers(peakPos_z_idx);
end
end
