y0 = csvread('VL_BT.csv');
% correct the first element -> 1
y0(1) = 1;
% distribute the values into properly named variables
s11 = y0(:,1);
s22 = y0(:,2);
s12 = y0(:,3);
% select the value of Y0 (i.e. Y in yield criteria)
Y0 = y0(1);
%% FIT
m = 6;
% [~,~,YC_sym] = Hill48(s11,s22,s12,Y0);
% [~,~,YC_sym] = Yld91(s11,s22,s12,Y0,m);
% [~,~,YC_sym] = Yld2004_18p(s11,s22,s12,Y0);
%% DRAW
close all
figure('Renderer', 'Painters')
scatter3(s11,s22,s12,50,s12,...
    'filled',...
    'MarkerEdgeColor','k')
% YC_draw(YC_sym,Y0)
YS_figure

function YC_draw(YC_sym,Y0)
hold on
fg = fimplicit3(YC_sym == Y0);
fg.EdgeColor = 'none';
fg.FaceAlpha = 0.5;
fg.ZRange = [0 1];
end