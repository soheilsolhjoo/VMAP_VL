function BW_loader_builder(RVE,tests_number)
header = cellstr('#!/bin/bash');

pre = ''; % NOTE: all related commands have been removed.

% Name of the geom file
RVE_name = split(RVE,'.');
RVE_name = RVE_name(1);

% Write the loader bash file
loader(1,1) = cellstr(' ');
for i = 1:tests_number
    loader(end+1,1) = cellstr(['cd ' pre 'sample_' num2str(i)]);
    loader(end+1,1) = cellstr(['DAMASK_spectral  --load BT.load' ...
        ' --geom ' convertStringsToChars(RVE) ' > BT.out']);
    loader(end+1,1) = cellstr(['postResults ' ...
        char(RVE_name) ...
        '_BT.spectralOut --time --cr f,p --co totalshear']);
    loader(end+1,1) = cellstr('if [ -d "postProc" ]; then');
    loader(end+1,1) = cellstr('cd postProc');
    loader(end+1,1) = cellstr(['addStrainTensors ' char(RVE_name) ...
        '_BT.txt --left --logarithmic']);
    loader(end+1,1) = cellstr(['addCauchy ' ...
        char(RVE_name) '_BT.txt']);
    loader(end+1,1) = cellstr(['cp ' char(RVE_name) ...
        '_BT.txt ' pre num2str(i) '.txt']);
    loader(end+1,1) = cellstr(['mv ' pre num2str(i) ...
        '.txt ../../master_results/']);
    loader(end+1,1) = cellstr('cd ..');
    loader(end+1,1) = cellstr('cd ..');
    loader(end+1,1) = cellstr('else');
    loader(end+1,1) = cellstr('cd ..');
    loader(end+1,1) = cellstr('fi');
end

% Export the bash file
loader_command = vertcat(header(1,1),loader);
fid = fopen([pre 'BT_loader.sh'],'w');
for i = 1:size(loader_command,1)
    fprintf(fid,'%s\n',loader_command{i});
end
fclose(fid);

end