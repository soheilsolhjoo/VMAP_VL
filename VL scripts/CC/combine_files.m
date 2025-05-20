function combine_files(extension,export)
list = list_builder(['*.' extension]);
j = 1;
for i=1:size(list,1)
    file_name = [list{i},'.',extension];
    
    fid = fopen(file_name);
    tline = fgetl(fid);
    l = 1;
    while ischar(tline)
        data(l,1) = cellstr(tline);
        tline = fgetl(fid);
        l = l + 1;
    end
    fclose(fid);
    
    data_list(j,1) = cellstr(['<' list{i} '>']);
    data_list(j+1:j+size(data,1),1) = data;
    
    j = j + size(data,1) + 1;
    clear data
end
%% Export
fid = fopen(export,'w');
for i = 1:size(data_list,1)
    fprintf(fid,'%s\n',data_list{i});
end
fclose(fid);
end