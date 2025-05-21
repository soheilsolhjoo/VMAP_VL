function [c1234,Yld91_fun,Yld91_sym] = Yld91(s11,s22,s12,Y0,m)
%% Barlat-1991 Formula
syms x y z
c = sym('c', [1, 4]);

sxx = (+c(3)*(x-y)+c(2)*x)/3;
syy = (-c(3)*(x-y)+c(1)*y)/3;
szz = -(sxx + syy); %-(c(1)*y+c(2)*x)/3;
sxy = c(4)*z;

S12 = sqrt(((sxx-syy)/2).^2+sxy.^2);
S1  = (sxx+syy)/2 + S12;
S2  = (sxx+syy)/2 - S12;
S3  = szz;

Yld91_sym = abs(S1-S2).^m + abs(S2-S3).^m + abs(S3-S1).^m;
%% Minimization
c1234_0 = [1 1 1 1];
% sum-squared-error cost function
Yld91_fun = matlabFunction(Yld91_sym, 'Vars', {c,x,y,z});
SSECF = @(c) sum((Yld91_fun(c,s11,s22,s12)-2*Y0.^m).^2);
% minimization
[c1234,~] = fminsearch(SSECF,c1234_0);
Yld91_sym = (Yld91_sym/2).^(1/m);
Yld91_fun = matlabFunction(Yld91_sym, 'Vars', {c,x,y,z});
Yld91_sym = subs(Yld91_sym,c,c1234);

end