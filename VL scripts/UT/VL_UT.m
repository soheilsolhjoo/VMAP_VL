function VL_UT(RVE,varargin)%(RVE,loading_file,tests_number)
%% Check the input values
if nargin == 0 || nargin > 6
error('RVE:missingData',...
    'VL_UT: call the function by assigning the required values.');
end
if nargin == 1 && ~(isstring(RVE) || ischar(RVE))
error('RVE:missingORincorrectType',...
    'VL_UT: the name of the RVE (file) is required, e.g. "RVE.geom".');
end

if size(varargin,2) == 2 && size(varargin{2},2) ~= 2
        error('Input:incorrectStruc',...
    ['VL_UT: if [r] is assigned as an array, [t] and [n] should also',...
    ' be defined with the same size']);
end
if size(varargin,2) == 3 && size(varargin{3},2) ~= 2
        error('Input:incorrectStruc',...
    'VL_UT: the array [t] should have only two values.');
end
if size(varargin,2) == 4 && size(varargin{3},2) ~= size(varargin{4},2)
        error('Input:incorrectStruc',...
    'VL_UT: the array [t] and [n] should have the same size.');
end
if size(varargin,2) == 5 && size(varargin{3},2) ~= size(varargin{5},2)
        error('Input:incorrectStruc',...
    ['VL_UT: the array [f] should have the same size of ',...
    '[n] should have the same size.']);
elseif ~all(floor(varargin{5}) == varargin{5})
    error('RVE:missingORincorrectType',...
    'VL_UT: the assigned frequencies has to be of type integer.');
end
if size(varargin,2) > 3 && ...
        ~(size(varargin{2},2) == 1 || ...
         size(varargin{2},2) == size(varargin{3},2))
        error('Input:incorrectStruc',...
    'VL_UT: the array [r] should have the same size as [t] and [n].');
end
Defaults = {3,0.01,[1,20],[10,90],[1,1]};
idx = ~cellfun('isempty',varargin);
Defaults(idx) = varargin(idx);
[tests_number,strate,ts,incs,freq] = Defaults{:};
%% Prepare the loading state
UT_loading(strate,ts,incs,freq);
loading_file = 'UT.load';
%% Prepare the variables
theta = deg2rad(linspace(0,90,tests_number));
GS = create_master_geom(RVE);
%% Remove extension from init_RVE and loading_file
loading_file = cellstr(split(loading_file,'.'));
loading_file_full = [loading_file{1} '.' loading_file{2}];
%% Write the loader bash file
header(1,1) = cellstr('#!/bin/bash');
command(1,1) = cellstr('');
for i = 1:tests_number
    command(end+1,1) = cellstr(['cp ' loading_file_full ...
        ' sample_' num2str(i)]);
    command(end+1,1) = cellstr(['cd sample_' num2str(i)]);
    command(end+1,1) = cellstr(['DAMASK_spectral  --load ' ...
        loading_file_full ' --geom cut.geom  > UT.out']);
    command(end+1,1) = cellstr(['postResults cut_'  loading_file{1} ...
        '.spectralOut --cr f,p']);
    command(end+1,1) = cellstr('if [ -d "postProc" ]; then');
    command(end+1,1) = cellstr('cd postProc');
    command(end+1,1) = cellstr(['addStrainTensors cut_' ...
        loading_file{1} '.txt --left --logarithmic']);
    command(end+1,1) = cellstr(['addCauchy cut_' loading_file{1} '.txt']);
    command(end+1,1) = cellstr(['cp cut_' loading_file{1} '.txt ' ...
        loading_file{1} '_' num2str(i) '.txt']);
    command(end+1,1) = cellstr(['mv ' ...
        loading_file{1} '_' num2str(i) ...
        '.txt ../../master_results/']);
    command(end+1,1) = cellstr('cd ..');
    command(end+1,1) = cellstr('cd ..');
    command(end+1,1) = cellstr('else');
    command(end+1,1) = cellstr('cd ..');
    command(end+1,1) = cellstr('fi');
end
% Export the rotator bash file
master_command = vertcat(header,command);
fid = fopen('loader.sh','w');
for i = 1:size(master_command,1)
    fprintf(fid,'%s\n',master_command{i});
end
fclose(fid);
clear master_command header command
%% Write the rotator bash file
% Header
header(1,1) = cellstr('#!/bin/bash');
system('mv master.geom main_master.geom');
% Preparing the rotated master files
rotate_command(1,1) = cellstr('');
for i = 1:tests_number
    rotate_command(end+1,1) = cellstr('cp main_master.geom master.geom');
    rotate_command(end+1,1) = cellstr(['geom_rotate --rotation '...
        num2str(theta(i)) ' 0 0 1 master.geom']);
    rotate_command(end+1,1) = cellstr(...
        ['mv master.geom ' num2str(i) '.master_rot']);
    rotate_command(end+1,1) = cellstr(['mkdir sample_' num2str(i)]);
end
cutter = cellstr(['matlab -nojvm -nodesktop -r ' ...
    '"cut_config_builder([' num2str(GS') ']); exit;"']);

% Export the rotator bash file
master_command = vertcat(header,rotate_command,cutter);
fid = fopen('rotate_geom.sh','w');
for i = 1:size(master_command,1)
    fprintf(fid,'%s\n',master_command{i});
end
fclose(fid);
clear master_command header rotate_command
%% Write the Lab file
header(1,1) = cellstr('#!/bin/bash');
header(2,1) = cellstr('source /opt/netapps/DAMASK/DAMASK_env.sh');

command(    1,1) = cellstr('rm -rf master_results');
command(end+1,1) = cellstr('rm -rf sample_*');
command(end+1,1) = cellstr('rm *.master_rot');

command(end+1,1)= cellstr('mkdir master_results');
command(end+1,1)= cellstr('bash rotate_geom.sh');
command(end+1,1)= cellstr('rm main_master.geom');
command(end+1,1)= cellstr('bash loader.sh');
command(end+1,1)= cellstr('cp extract_rY.m master_results');
command(end+1,1)= cellstr('cp ind_finder.m master_results');
command(end+1,1)= cellstr('cp list_builder.m master_results');
command(end+1,1)= cellstr('cd master_results');
command(end+1,1)= cellstr(['matlab -nojvm -nodesktop -r ' ...
    '"extract_rY(' num2str(tests_number) '); exit;"']);
command(end+1,1)= cellstr('rm extract_rY.m');
command(end+1,1)= cellstr('rm ind_finder.m');
command(end+1,1)= cellstr('rm list_builder.m');

% Export the lab bash file
master_command = vertcat(header,command);
fid = fopen('VL_UT.sh','w');
for i = 1:size(master_command,1)
    fprintf(fid,'%s\n',master_command{i});
end
fclose(fid);
clear master_command header command

end