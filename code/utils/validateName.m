function fullSaveName = validateName(fileName,output_path)
% Validate file name and output path
% Allows entering names of either char/string format,
% either on Linux or Windows.
%
% Yohay Zvi, June 2023

% change file name and path to char (''), not string ("")
if class (fileName)~= "char"
    fileName = convertStringsToChars(fileName);
end
if class (output_path) ~= "char"
    output_path = convertStringsToChars(output_path);
end

% file name should not start with "\" or "/" - the function adds it later on
if fileName(1) == '\' || fileName(1) == '/'
    fileName(1) = [];
end
% output path should not end with "\" or "/" - the function adds is later on
if output_path(end) == '/' || output_path(end) == '\'
    output_path(end) = [];
end

% adjust syntax according to PC vs Linux
if isunix
    backslashIndices = strfind(output_path, '\');
    output_path(backslashIndices) = '/';
    backslashIndices = strfind(fileName, '\');
    fileName(backslashIndices) = '/';
    % unite file name and path as a string ouput
    fullSaveName = strcat (output_path, "/", fileName);
elseif ispc
    backslashIndices = strfind(output_path, '/');
    output_path(backslashIndices) = '\';
    backslashIndices = strfind(fileName, '/');
    fileName(backslashIndices) = '\';
    % unite file name and path as a string ouput
    fullSaveName = strcat (output_path, "\", fileName);
end





