function [names] = list_builder(files_extension)
files = dir(files_extension);
names = {files.name};
names = names';
% Continue if no file is identified
if isempty(names)
    return
end
% Corret the answer if only one file is found
just_one = 0;
if size(names,1)==1
    just_one = 1;
end
names = split(names,'.');
if just_one
    names(end) = [];
end
% Prepare the ouput
names = names(:,1);
names_temp = str2double(names);
if ~any(isnan(names_temp))
    names = sort(names_temp);
    names(isnan(names(:)))=[];
end
end