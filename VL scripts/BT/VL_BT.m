function VL_BT(RVE,varargin)
%% Check number of inputs
if nargin == 0 
error('RVE:missingData',...
    'VL_BT: call the function by assigning the required values.');
end

if nargin == 1 && ~(isstring(RVE) || ischar(RVE))
error('RVE:missingORincorrectType',...
    'VL_BT: the name of the RVE (file) is required, e.g. "RVE.geom".');
end

if ~isempty(varargin) && ~all(size(varargin{1}) == [1,5])
    error('Input:incorrectStruc',...
        ['VL_BT: the set of test numbers hsa to be as:' ...
        '[n1,n2,n3,n4,m]; the default is [1,0,0,0,0]. \n' ...
'NOTE: m = 0 means the test will be performed at a zero shear stress.']);
end

Defaults = {[1,0,0,0,0],0.003,0.1,80,0.0025,1,1.5};
idx = ~cellfun('isempty',varargin);
Defaults(idx) = varargin(idx);
[test_quadrant,strain,forming_rate,tests_number_max,...
    elastic_range,num_con,tSafetyFactor] = Defaults{:};
% num_con: 1 | 0 : copy | not_copy "numerics.config"
forming_rate_seg = 1;
if elastic_range > strain
error('RVE:missingORincorrectType',...
    ['VL_BT: the assigned "elastic range" cannot be larger than the',...
    '"total strain"']);
end
if ~ismember(num_conf,[0,1])
error('RVE:missingORincorrectType',...
    'VL_BT: the NC_flag (num_conf) can only be set as either 0 or 1.');
end
%% Call VL_BT_prepare & BW_VL_BT
VL_BT_prepare(RVE,forming_rate,strain,elastic_range,tSafetyFactor);
BW_VL_BT(RVE,forming_rate,forming_rate_seg,tests_number_max,...
    test_quadrant,num_con);
%% Prepare the VL_BT bash file
apos = '''';

% Headers
header(1,1) = cellstr('#!/bin/bash');
% header(2,1) = cellstr('source /opt/netapps/DAMASK/DAMASK_env.sh');

% Running Code
VL_BTT(    1,1) = cellstr('rm -rf master_results');
VL_BTT(end+1,1) = cellstr('rm -rf sample_*');
VL_BTT(end+1,1) = cellstr('rm *.mat');
VL_BTT(end+1,1) = cellstr('mkdir master_results');
VL_BTT(end+1,1) = cellstr('cp list_builder.m master_results');
VL_BTT(end+1,1) = cellstr('cp sort_nat.m master_results');
VL_BTT(end+1,1) = cellstr('cp extract_YS.m master_results');
VL_BTT(end+1,1) = cellstr('cp ind_finder.m master_results');
VL_BTT(end+1,1)= cellstr('bash BT_state_builder.sh');
VL_BTT(end+1,1)= cellstr('bash BT_loader.sh');
VL_BTT(end+1,1)= cellstr('rm time.mat');
VL_BTT(end+1,1)= cellstr('cd master_results');
VL_BTT(end+1,1)= cellstr(['matlab -nojvm -nodesktop -r ' ...
    '"extract_YS(); exit;"']);

% Export the bash file
VL_BT_command = vertcat(header,VL_BTT);
fid = fopen('VL_BT.sh','w');
for i = 1:size(VL_BT_command,1)
    fprintf(fid,'%s\n',VL_BT_command{i});
end
fclose(fid);
end