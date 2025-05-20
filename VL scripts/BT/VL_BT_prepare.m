%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VL_BTT_prepare makes the required files ready for running VL_BTT.
% 
% This function extact <homogenization> and <texture> parts from the RVE,
% and generates 'material.config'.
%
% This code is written in Univeristy Groningen (FSE, ENTEG, APE)
%                      by Soheil Solhjoo,
%                      on 21 Mar 2019 (v1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VL_BT_prepare(RVE,forming_rate,strain,elastic_range,...
    tSafetyFactor)
%% Export the material.config file
% Extract and export <homogenization> and <texture> parts from the RVE in
% corresponding data files.
extract_microtex(RVE);
% Build material.config file
combine_files('data','material.config')
%% Calculate the deformation time
time(1,1) = round(strain / forming_rate,3) * tSafetyFactor;
if strain > elastic_range
    time(2,1) = round(elastic_range / forming_rate,6);
    time(1,1) = time(1,1) - time(2,1);
end
time = flip(time,1);

% Export time to time.mat
save('time','time');
end