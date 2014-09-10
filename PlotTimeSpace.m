function PlotTimeSpace(xdata,ydata,Udata,goodCells,ptitle)
% creates array image plot
% called from ClassifyArrayGUI
% subfunctions include CreateFig, makeLegend

%% user parameters
%pcont = [-0.05:0.01:0.05]; % hard wire in contours

%% prepare data
% find size of array
[nttot,nCells] = size(Udata);
% remove mean from each cell
Umean = mean(Udata);
Unomean = zeros(nttot,nCells);
for nC=1:nCells
    Unomean(:,nC) = Udata(:,nC)-Umean(nC);
end

%% calculate intervals for colorbar
% initialize range
pmax = 0;
pmin = 0;
% for each Cell
for nC=1:nCells
    % if it is a goodCell
    if goodCells(nC)
        % use it to adjust max and min
        pmaxi=max(Unomean(nC,:));
        if pmaxi>pmax
            pmax = pmaxi;
        end
        pmini = min(Unomean(nC,:));
        if pmini<pmin
            pmin = pmini;
        end
    end
end
if ~pmin
    pmin = min(min(Unomean));
end
if ~pmax
    pmax = max(max(Unomean));
end
% get rounded values
rngtot = pmax-pmin
if rngtot>1
    divrng = 1;
elseif rngtot>0.1
    divrng = 10;
else
    divrng = 100;
end
pmaxe = ceil(pmax*divrng)/divrng;
pmine = floor(pmin*divrng)/divrng;
% calculate interval
pint = ceil((pmaxe-pmine)/20*100)/100;
% set intervals for contour lines
pcont = pmine:pint:pmaxe;

%% create image
% figure and axes
axe = CreateFig;
% add image
image(xdata-xdata(1),ydata,(Unomean'-pcont(1))/pint,...
    'CDataMapping','direct');%values are integers that map to colors
% colormap 
nctot = length(pcont)-1;
cmap = jet; % jet coloring, could also be used with bone, autumn, etc.
njettot = length(cmap);
ngooc = floor(1:njettot/nctot:njettot);
col = cmap(ngooc,:);
colormap(col);
% axes parameters
set(axe(1,1),...
    'XDir','reverse',...
    'YDir','normal');
% labels and titles
xlabel(ptitle.xaxis)
ylabel(ptitle.yaxis)
title(ptitle.top);
% legend
makeLegend(pcont,ptitle.legend,col)

end

%%%%%
function axe = CreateFig
% multiple axes
plt1 = figure;
titlespace = .5; % distance above plots
figxi = 1.5; % corner position of first figure
figyi = 1.5; 
nxtot = 1; % number of axes in x direction
nytot = 1; % number of axes in y direction
axescale = 2.5; % multiplier for axes
axey = 5*axescale;
axex = 10*axescale;
axespace = 1; % space between axes
axexi = 1.5; % corner position of 
axeyi = 1.3;
figx = axexi+nxtot*(axex+axespace)+1.5*titlespace;
figy = axeyi+nytot*(axey+axespace)+titlespace;
set(plt1,'Units','centimeters','Position',[figxi figyi figx figy],'PaperPositionMode','auto');

% multiple axes
for nx = 1:nxtot
    axexin = axexi+(nx-1)*(axex+axespace);
    for ny = 1:nytot 
        axeyin = axeyi+(ny-1)*(axey+axespace);
        axe(nx,ny) = axes('Units','centimeters','Position',[axexin axeyin axex axey]);
    end
end
end
%%%%%
function makeLegend(pcont,ptit,col)
 
pctot = length(pcont);
 
a = get(gca,'Position');
xi = a(1)+a(3)+0.7;
axel = axes('Units','centimeters','Position',[xi a(2) 0.15 a(4)/2]);
set(axel,'NextPlot','add');
set(axel,'XLim',[0.5 1.5]);
set(axel,'YLim',[0.5 pctot-0.5]);
set(axel,'YAxisLocation','right');
set(axel,'YTick',[0.5:2:pctot]);
set(axel,'YTickLabel',pcont(1:2:pctot));
 
set(axel,'XTick',[]);
 
image([1:pctot-1]','CDataMapping','direct');
text(-0.5,(pctot)/2, ptit,'Rotation',90,'VerticalAlignment','middle');%,... 'HorizontalAlignment','center')

end