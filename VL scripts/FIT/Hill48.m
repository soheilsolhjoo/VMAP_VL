function [HFGN,Hill48_fun,Hill48_sym] = Hill48(s11,s22,s12,Y0)
%% Hill formula
syms x y z
c = sym('c', [1, 4]);
Hill48_sym = c(1)*y.^2 + c(2)*(-x).^2 + c(3)*(x-y).^2 + 2*c(4)*z.^2;
%% Minimization
HFGN_0 = [1 1 1 1];
% sum-squared-error cost function
Hill48_fun = matlabFunction(Hill48_sym, 'Vars', {c,x,y,z});
SSECF = @(c) sum((abs(Hill48_fun(c,s11,s22,s12))-2*Y0.^2).^2);
% minimization
[HFGN,~] = fminsearch(SSECF,HFGN_0);
Hill48_sym = (Hill48_sym/2).^(1/2);
Hill48_fun = matlabFunction(Hill48_sym, 'Vars', {c,x,y,z});
Hill48_sym = subs(Hill48_sym,c,HFGN);
end