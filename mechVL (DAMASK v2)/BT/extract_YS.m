function extract_YS()
close all
clear
%% Preparation section
% Load the list of files
names = sort_nat(string(list_builder('*.txt')));
%%%%%%%%
% List of required labels
e11 = '1_ln(V)';
s11 = '1_Cauchy';
TS  = 'totalshear';
dt  = 'time';
required_labels = {TS,e11,s11,dt};
clear e11 s11 TS
%% Collect the required data: Yield Loci
% Read the header
file_name = strjoin(cellstr([names(1) '.txt']),'');
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
y0 = [];
for i = 1:size(names,1)
    % Read the data in the files
    file_name = strjoin(cellstr([names(i) '.txt']),'');
    data = dlmread(file_name,'',numLines,0);
    
    % Find the index of the yield loci
    [~,y_ind] = max(gradient(gradient(data(:,ind_is(1)))));
    
    % Collect stress tensor
    s11 = data(y_ind:end,ind_is(3)+0);
    s12 = data(y_ind:end,ind_is(3)+1);
    s21 = data(y_ind:end,ind_is(3)+3);
    s22 = data(y_ind:end,ind_is(3)+4);
    % Average the values of s12 and s21
    s12 = abs(s12+s21)/2;

    ten_s   = [s11 s22 s12];    %stress
    
    y0 = [y0;ten_s(1,:)];
end
clearvars -except y0
%% Export the yield loci
csvwrite('VL_BT.csv',y0)