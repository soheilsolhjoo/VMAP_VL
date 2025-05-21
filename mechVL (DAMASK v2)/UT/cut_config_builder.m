function cut_config_builder(GS)
% Load the list of files
names = list_builder('*.master_rot');

for i = 1:size(names,1)
    cut_rotated_grain(names(i),GS);
    combine_files('data','material.config')
%     build_mater_config;
    
    move_command(1,1) = cellstr(['mv cut.geom sample_' num2str(names(i))]);
    move_command(2,1) = cellstr(['mv material.config sample_' ...
        num2str(names(i))]);
    move_command(3,1) = cellstr(['rm ' num2str(names(i)) '.master_rot']);

    fid = fopen('move.sh','w');
    for j = 1:size(move_command,1)
        fprintf(fid,'%s\n',move_command{j});
    end
    fclose(fid);
    !bash move.sh
    system('rm move.sh');
end

end