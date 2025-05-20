function GS = create_master_geom(geom_file_name)
%% Read Header
fid = fopen(geom_file_name,'r');
numLines = textscan(fid,'%n');
numLines = numLines{1} + 1;
header_text = cell(numLines,1);
for i = 1:numLines
    header_text(i) = {fgetl(fid)};
end
header_text{1} = [num2str(numLines-1),'	',header_text{1}];
fclose(fid);
%% Find the positions of the needed data in the geometry file
ind_grid = find(~cellfun(@isempty,strfind(header_text,'grid	a')));
ind_size = find(~cellfun(@isempty,strfind(header_text,'size	x')));
ind_orig = find(~cellfun(@isempty,strfind(header_text,'origin	x')));
% ind_grid = ind_grid(1);
%% Extract the number of grids and overwrite the system's size
grids(1:3) = sscanf(char(header_text(ind_grid ,:)),...
    'grid	a %f	b %f	c %f')';
header_text{ind_grid,1} = strrep(header_text{ind_grid,1}, ...
    ['a ' num2str(grids(1))], ['a ' num2str(3*grids(1))]);
header_text{ind_grid,1} = strrep(header_text{ind_grid,1}, ...
    ['b ' num2str(grids(2))], ['b ' num2str(3*grids(2))]);

geom_size(1:3)  = sscanf(char(header_text(ind_size,:)),...
    'size	x %f	y %f	z %f')';
header_text{ind_size,1} = strrep(header_text{ind_size,1}, ...
    ['x ' num2str(geom_size(1)) ], ...
    ['x ' num2str(3*geom_size(1)) ]);
header_text{ind_size,1} = strrep(header_text{ind_size,1}, ...
    ['y ' num2str(geom_size(2)) ], ...
    ['y ' num2str(3*geom_size(2)) ]);

geom_orig(1:3)  = sscanf(char(header_text(ind_orig,:)),...
    'origin	x %f	y %f	z %f')';
header_text{ind_orig,1} = replaceBetween(header_text{ind_orig,1},...
    "x ","y", [num2str(geom_size(1)+geom_orig(1)) '  ']);
header_text{ind_orig,1} = replaceBetween(header_text{ind_orig,1},...
    "y ","z", [num2str(geom_size(2)+geom_orig(2)) '  ']);

GS = [grids(1);grids(2);geom_size(1);geom_size(2)];
%% Extract the number of grains and overwrite the intitial structure
%Find the indeces for different needed headers
ind_header_micro = ...
    find(~cellfun(@isempty,strfind(header_text,'<microstructure>')));
ind_header_text = ...
    find(~cellfun(@isempty,strfind(header_text,'<texture>')));

%Number of microstructures
ind_micro        = ...
    find(~cellfun(@isempty,strfind(header_text,'microstructures	')));
micro_num = sscanf(char(header_text(ind_micro ,:)),'microstructures	%f')';
header_text{ind_micro,1} = strrep(header_text{ind_micro,1}, ...
    ['microstructures	' num2str(micro_num)], ...
    ['microstructures	' num2str(3*micro_num)]);

%Prepare two temporary cells for microstructure and texture
orig_micro  = header_text(...
    ind_header_micro+1:ind_header_micro+3*micro_num);
orig_text   = header_text(...
    ind_header_text+1:ind_header_text+2*micro_num);
%Replicate data for new 8 cells
micro_list = cell(3,1);
for j = 2:9
    for i = 1:micro_num
        micro_list(1) = cellstr(['[grain' num2str((j-1)*micro_num+i) ']']);
        micro_list(2:3) = orig_micro(3*(i-1)+1+1:3*i);
        orig_micro = vertcat(orig_micro,micro_list);
        
        orig_text = vertcat(orig_text,micro_list(1),...
            orig_text (2*(i-1)+1+1:2*i));
    end
end
%Replace & rewrite new lists into header_text
ind_homog = ...
    find(~cellfun(@isempty,strfind(header_text,'homogenization	')));
header_text{2,1} = header_text{ind_grid,1};
header_text{3,1} = header_text{ind_size,1};
header_text{4,1} = header_text{ind_orig,1};
header_text{5,1} = header_text{ind_homog,1};
header_text{6,1} = header_text{ind_micro,1};
header_text(7:end) = [];
header_text(end+1) = cellstr('<microstructure>');
header_text = vertcat(header_text,orig_micro);
header_text(end+1) = cellstr('<texture>');
header_text = vertcat(header_text,orig_text);

header_text{1,1} = [num2str(size(header_text,1)-1) ' header'];
%% Read grains & Extend it
grains = dlmread(geom_file_name,'',numLines,0);
k = 1;
for i = 1:grids(2):size(grains,1)
    temp_grain_orig = grains(i:i+grids(2)-1,:);
    temp_grain = temp_grain_orig;
    for j = 2:9
        temp_grain(:,:,j) = temp_grain(:,:,j-1) + micro_num;
    end
    
    temp_grain_layer = ...
        [temp_grain(:,:,1) temp_grain(:,:,2) temp_grain(:,:,3);
        temp_grain(:,:,4) temp_grain(:,:,5) temp_grain(:,:,6);
        temp_grain(:,:,7) temp_grain(:,:,8) temp_grain(:,:,9);];
    
    new_grain(k:k+3*grids(2)-1,:) = temp_grain_layer;
    k = k + 3*grids(2);
end
%% Write Header + Rotated Values
fid = fopen('headerFile.txt','w');
for i = 1:size(header_text,1)
    fprintf(fid,'%s\n',header_text{i});
end
your_first_value = fscanf(fid,'%d',1);
fclose(fid);
new_grain = table(new_grain);
writetable(new_grain,'grains.txt',...
    'delimiter','\t','WriteVariableNames',0);
if exist('master.geom')
    system('rm master.geom');
end
system('touch master.geom');
system('cat headerFile.txt >> master.geom');
system('cat grains.txt >> master.geom');
system('rm headerFile.txt');
system('rm grains.txt');
end