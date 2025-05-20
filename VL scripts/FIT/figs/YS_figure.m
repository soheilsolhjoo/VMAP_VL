function YS_figure
fs = 20;

daspect([1 1 1])
pbaspect([1 1 1])
grid off
view(2)
% gridlines ---------------------------
hold on
g1 = [0 0];
g2 = [-2 2];
plot(g1,g2,'k') %y grid lines
plot(g2,g1,'k') %y grid lines
ax=gca;
ax.XTick = -2:1:2;
ax.YTick = ax.XTick;
box on
xlabel('$\bar{\sigma}_{11}$','interpreter','latex') 
ylabel('$\bar{\sigma}_{22}$','interpreter','latex') 

set(gca, 'FontName', 'Calibri')
set(gca,'FontSize',fs)


c = colorbar;
c.Label.Interpreter = 'latex';
c.Label.String = '$\bar{\sigma}_{12}$';
set(c,'FontSize',fs)

end