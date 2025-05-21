function extract_microtex(RVE)
%% Read Header
fid = fopen(RVE,'r');
numLines = textscan(fid,'%n');
numLines = numLines{1} + 1;
header_text = cell(numLines,1);
for i = 1:numLines
    header_text(i) = {fgetl(fid)};
end
header_text{1} = [num2str(numLines-1),'	',header_text{1}];
fclose(fid);
%% Find the positions of the needed data in the geometry file
ind_micro_number = ...
    find(contains(header_text,'microstructures	'));
ind_micro = ...
    find(contains(header_text,'<microstructure>'));
ind_text = ...
    find(contains(header_text,'<texture>'));
%% Extract data
micro_number = sscanf(char(header_text(ind_micro_number,:)),...
    'microstructures	%f')';
geom_microstructure = header_text(ind_micro+1:ind_micro+3*micro_number);
geom_texture = header_text(ind_text+1:ind_text+2*micro_number);
%% Export <microstructre> and <texture> lists as data files
fid = fopen('microstructure.data','w');
for i = 1:size(geom_microstructure,1)
    fprintf(fid,'%s\n',geom_microstructure{i});
end
fclose(fid);
fid = fopen('texture.data','w');
for i = 1:size(geom_texture,1)
    fprintf(fid,'%s\n',geom_texture{i});
end
fclose(fid);
end