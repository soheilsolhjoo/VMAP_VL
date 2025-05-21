function extract_rY(tests_number)
%% Preparation section
% Prepare the list of angles (theta)
theta = linspace(0,90,tests_number);
% Load the list of files
[names,jo] = list_builder('*.txt');
% End the function if no file is identified
if isempty(names)
    error('VL_UT: DAMASK post-processed files are not found!');
%     return
end
names = split(names,'_');
% Correct the answer if there is only one file
if jo
    names(1,2) = cellstr(names(2,1));
    names(2,:) = [];
end
% Sort the names' list
names(:,2) = strtrim(cellstr(num2str(sort(str2double(names(:,2))))));
% List of required labels: e11, e22, e33, s11, with e: strain, s: stress
e11 = '1_ln(V)';
e22 = '5_ln(V)';
e33 = '9_ln(V)';
s11 = '1_Cauchy';
required_labels = {e11,e22,e33,s11};
%% Reading files
% Read the header
file_name = strjoin(cellstr([names{1,1},'_',names{1,2},'.txt']),'');
fid = fopen(file_name,'r');
numLines = textscan(fid,'%n');
numLines = numLines{1} + 1;
header = cell(numLines,1);
for j = 1:numLines
    header(j) = {fgetl(fid)};
end
fclose(fid);
header = header(end);
header = strsplit(header{1});
ind_is = ind_finder(header,required_labels);
% Loop over the files
for i = 1:size(names,1)
    % Read the data in the files
    file_name = strjoin(cellstr([names{i,1},'_',names{i,2},'.txt']),'');
    % Read the data in the files
    data = dlmread(file_name,'',numLines,0);
    data_collect_e11(:,i) = data(:,ind_is(1));
    data_collect_e22(:,i) = data(:,ind_is(2));
    data_collect_e33(:,i) = data(:,ind_is(3));
    data_collect_s11(:,i) = data(:,ind_is(4));
end
data_r = data_collect_e22 ./ data_collect_e33;
%% Postprocessing on uniform spaces of e11 and W11
% Find the common maximum of e11s
min_e11     = min(max(data_collect_e11));
% Generate a uniformly spaced e11 and W11
interp_e11  = linspace(0,min_e11,size(data,1))';
% Estimate the values of s11 and r for the newly defined spaces of e11
% so that the comparable results could be made.
for i = 1:size(names,1)
    s11_e11(:,i) = ...
        interp1(data_collect_e11(:,i),data_collect_s11(:,i),interp_e11);
    r_e11(:,i) = interp1(data_collect_e11(:,i),data_r(:,i),interp_e11);
end
%% Prepare the report matrix
rm_1 = vertcat(NaN, interp_e11);
rm_2 = theta(str2double(names(:,2)));
rm_2 = [rm_2 rm_2];
rm_3 = s11_e11;
rm_3(:,2:end) = rm_3(:,2:end) ./ rm_3(:,1);
rm_4 = r_e11;
rm = [rm_1,[rm_2;[rm_3,rm_4]]];
%% Export the report matrix
csvwrite('VL_UT.csv',rm)
end