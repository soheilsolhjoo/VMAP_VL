y0 = csvread('VL_BT.csv');
% correct the first element -> 1
y0(1) = 1;
% distribute the values into properly named variables
s11 = y0(:,1);
s22 = y0(:,2);
s12 = y0(:,3);
% select the value of Y0 (i.e. Y in yield criteria)
Y0 = y0(1);