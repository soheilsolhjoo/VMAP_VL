function BW_VL_BT(RVE,forming_rate,fr_seg,tests_number_max,...
    test_quadrant,num_con)
torsion_switch = test_quadrant(end);
test_quadrant(end) = [];
%% Prepare the theta range in Radians
% All values related to angels should be provided in Degrees.
theta_range = deg2rad(linspace(0,360,5));
for i = 1:4
    ratio       = linspace(0,1,test_quadrant(i)+2);
    ratio(1)    = [];
    ratio(end)  = [];
    d_ratio = ratio./flip(ratio);
    q(i).theta  = atan(d_ratio) + (i-1)*pi/2;
end
q_theta = wrapTo2Pi([q(:).theta]);
theta = unique([theta_range(1:4) q_theta])';
clear q q_theta predef

% Assinging elevate anlge (x-z plane) betwen 0 and pi/2
el = linspace(0,pi/2,torsion_switch+2);
% Create the deformation space
[space_el,space_theta] = meshgrid(el,theta);
space_theta = space_theta(:);
space_el    = space_el(:);

% Finding the (x,y) points of a circle along the identified theta
% [xy(:,1),xy(:,2),xy(:,3)] = sph2cart(space_theta,space_el,forming_rate);
% Loop over forming_rate for a total of n values {1/n,2/n,...,1}*Fdot.
xy = [];
for ratio = 1:fr_seg
    tempo_forming_rate = ratio/fr_seg * forming_rate;
    [temp_xy(:,1),temp_xy(:,2),temp_xy(:,3)] = ...
        sph2cart(space_theta,space_el,tempo_forming_rate);
    xy = [xy;temp_xy];
end
xy = round(xy,5);
[xy,o1,~] = unique(xy, 'rows');
xy = [o1,xy];
xy = sortrows(xy,1);
xy(:,1) = [];
%% Prepare the Fdot tensor
% Check the list is less than the assigned maximum number of tests
list_data = xy;
if length(list_data) > tests_number_max
    fprintf(['\nThe number of requested tests is larger than ',...
        'the set maximum: ', num2str(tests_number_max), '. \n',...
        'This maximum value can be passed as input to VL_BT ',...
        '(tests_number_max).\n\n']);
    index = randperm(numel(list_data(:,1)))';
    index = sort(index(1:tests_number_max));
    list_data = list_data(index,:);
end

fdot11  = list_data(:,1);
fdot22  = list_data(:,2);
fdot21  = list_data(:,3);
% fdot21  = list_data(:,4);

% star_m is a dummy "*" for exporting text purposes
star_m = string(repmat('*',size(fdot11)));
P      = strtrim(cellstr(cat(2,star_m,star_m,star_m,star_m)));
Fdot   = P;
Fdot   = strtrim(cellstr(cat(2,...
         num2str(fdot11),num2str(zeros(size(fdot21))),...
         star_m,num2str(fdot22))));
%! The following line could not be written in the previous command
Fdot(:,3) = strtrim(cellstr(num2str(fdot21)));

% Update Fdot and P for Fdot = 0
F1 = ismember(Fdot(:,1),'0')~=0;
F2 = ismember(Fdot(:,4),'0')~=0;
F3 = ismember(Fdot(:,3),'0')~=0;
star_rep = strtrim(cellstr(star_m(1)));
zero_rep = strtrim(cellstr('0'));
Fdot(F1,1) = star_rep;
Fdot(F2,4) = star_rep;
Fdot(F3,3) = star_rep;
P(F1,1) = zero_rep;
P(F2,4) = zero_rep;
P(F3,3) = zero_rep;
%% Call other bash writers
BW_state_builder(RVE,Fdot,P,forming_rate,num_con);
BW_loader_builder(RVE,size(Fdot,1))
end