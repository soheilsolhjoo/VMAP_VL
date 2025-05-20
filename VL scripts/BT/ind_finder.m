function ind_is = ind_finder(header,required_labels)
% Find the columns for the required labels
[~,ind_which] = ismember(header,required_labels);
ind_is = find(ind_which~=0);
% Make sure that the identified columns are sorted correctly, compared
% to the defined "required_labels"
ind_which(ind_which==0) = [];
ind = sortrows([ind_which',ind_is'],1);
ind_is = ind(:,2)';
end