figure
ntot= length(vel(:,4));
xdat1 = unique(vel(:,4));
ydat1 = histc(vel(:,4),xdat1)/ntot;

xdat2 = unique(vel(:,34));
ydat2 = histc(vel(:,34),xdat2)/ntot;

bar(xdat1,ydat1,0.5,'FaceColor','w','EdgeColor','k')
hold on
bar(xdat2,ydat2,0.5,'FaceColor','b','EdgeColor','k')

set(gca,'XLim',[-0.06 0.06])
set(gca,'YLim',[0 0.3])
ylabel('Relative Frequency')
xlabel('Difference from mean (m/s)')
set(gcf,'Renderer','Painters')