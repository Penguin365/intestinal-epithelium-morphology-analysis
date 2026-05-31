function write_summary_table(summaryTable, csvFile, matFile)
% WRITE_SUMMARY_TABLE  Write analysis summary outputs.
%
% This function writes the final one-row summary as CSV for portability and
% as MAT for direct MATLAB reuse in later scripts.
%
% Inputs:
%   summaryTable - Final summary table.
%   csvFile - Output CSV file path.
%   matFile - Output MAT file path.
%
% Outputs:
%   Writes files to disk.

outDir = fileparts(csvFile);
if ~isfolder(outDir)
    mkdir(outDir);
end

writetable(summaryTable, csvFile);
save(matFile, 'summaryTable');
end
