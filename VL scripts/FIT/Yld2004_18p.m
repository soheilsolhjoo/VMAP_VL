function [c1,c2,Yld2004_fun,Yld2004_sym] = Yld2004_18p(s11,s22,s12,Y0,m)
%% Barlat-2005 Formula
syms x y z xx yy zz xy
c = sym('c', [1, 14]);

xx = 1/3 * (2 * x - y);
yy = 1/3 * (x - 2 * y);
zz =-1/3 * (x + y);
xy = z;

% Transformed matrices components
tcsxx = - c(1) * yy - c(2) * zz;
tcsyy = - c(3) * xx - c(4) * zz;
tcszz = - c(5) * xx - c(6) * yy;
tcsxy = - c(7) * xy;

tdsxx = - c(8)  * yy - c(9)  * zz;
tdsyy = - c(10) * xx - c(11) * zz;
tdszz = - c(12) * xx - c(13) * yy;
tdsxy = - c(14) * xy;

% Principal values of the transformed matrices
tc = [  tcsxx tcsxy 0;
        tcsxy tcsyy 0;
        0     0     tcszz];

td = [  tdsxx tdsxy 0;
        tdsxy tdsyy 0;
        0     0     tdszz];

Pc = eig(tc);
Pd = eig(td);

Sc1 = Pc(1);
Sc2 = Pc(2);
Sc3 = Pc(3);
Sd1 = Pd(1);
Sd2 = Pd(2);
Sd3 = Pd(3);

Yld2004_sym= abs(Sc1-Sd1).^m + abs(Sc1-Sd2).^m + abs(Sc1-Sd3).^m + ...
             abs(Sc2-Sd1).^m + abs(Sc2-Sd2).^m + abs(Sc2-Sd3).^m + ...
             abs(Sc3-Sd1).^m + abs(Sc3-Sd2).^m + abs(Sc3-Sd3).^m;
%% Minimization
c_series_0 = ones(1,14);
% sum-squared-error cost function
Yld2004_fun = matlabFunction(Yld2004_sym, 'Vars', {c,x,y,z});
SSECF = @(c) sum((Yld2004_fun(c,s11,s22,s12)-4*Y0.^m).^2);
% minimization
options = optimset('MaxFunEvals',10000,...
    'PlotFcns',@optimplotfval);
[c_series,~] = fminsearch(SSECF,c_series_0,options);

Yld2004_sym = (Yld2004_sym/4).^(1/m);
Yld2004_fun = matlabFunction(Yld2004_sym, 'Vars', {c,x,y,z});
Yld2004_sym = subs(Yld2004_sym,c,c_series);

c1 = c_series(1:7);
c2 = c_series(8:14);
end