function Plot1Series(pdat,COR,titover,Hz,comp,leg)
% creates time series plot
% called from ClassifyArrayGUI

%% user parameters
% power spectra using pwelch
window = 1000; % window length for the Hamming window 
noverlap = 0; % the number of signal samples (elements of x) that are common to two adjacent segments
nfft = 512; % the length of the FFT (must be a power of two)
% line properties
colo = {'b','g','r'};    %[.65 .65 .65],'k',[.4 .4 .4],'k','k','k'}
lins = {'-','-','-','none','none','none'};
linw = [1 1 1 1 1 1];
mark = {'none','none','none','s','^','o'};
cmkf = {'w','w','w','w','w','w'};

%% prepare data and axes scales
% size of matrix
[nttot,natot,nctot] = size(pdat);
% set window size equal to the length of the time series if nttot < window length
if nttot<=window
    window = nttot;
end

% velocity plot axes variables
ymaxabs = max(squeeze(pdat(:,natot,:)));
yminabs = min(squeeze(pdat(:,natot,:)));
if isfinite(ymaxabs(1)*yminabs(1)) && ymaxabs(1)~=yminabs(1)
    yint = ceil(10*(ymaxabs-yminabs))/100;
    ymax = ceil(ymaxabs./yint).*yint;
    ymin = floor(yminabs./yint).*yint;
else
    ymax = 1;
    ymin = 0;
end    
yrange = (ymax-ymin);

% time axes properties
xint = 15*Hz; % 15 s intervals
xmax = (ceil(nttot/xint))*xint;
xmem = 0:xint:xmax;
xlabels = xmem/Hz;

% correlation plot axes variables
yminc = 0;
ymaxc = 100;

% power spectra plot axes variables
% use despiked data for range
if natot==3
    narange = 2;
else
    narange = natot;
end
[Pxx,fx]=pwelch(pdat(:,narange,1),window,noverlap,nfft,Hz);
% get max and mins
ymaxpp = ceil(max(log10(Pxx(4:end))));
yminpp = floor(min(log10(Pxx(4:end))));
if ymaxpp==yminpp
    ymaxpp=ymaxpp+1;
end
% if there is no variability in signal set default ranges
if std(pdat(:,natot))==0
    ymaxpp=1;
    yminpp=0;
end
ymaxpp = -2;
yminpp = -6;
% calculate intervals
ypp = 10.^([yminpp:1:ymaxpp]);
% hardcode option
% yminp = 0.0000001; ymaxp = .001;
% calculate x axis intervals (hardcoded)
xminpp = -2; xmaxpp = 2;
xpp = 10.^([xminpp:1:xmaxpp]);

%% prepare axes
% multiple axes
nxtot = 3; % number of axes in x direction
nytot = nctot; % number of axes in y direction
titlespace = .5; % distance above plots
figxi = 1; % corner position of first figure
figyi = 1; 
axescale = 2; % multiplier for axes
yspace = 1; % vertical space between components
xspace = 0.5; % horizontal space between timeseries, boxplot, and power figures
axexi = 1.5; % corner position of lower left axis
axeyi = 1.4;

axey = 2*axescale; % height of axes
axex = [6.5 0.5 2]*axescale; % length of timeseries, box, and power spectra plot 
% calculate figure size
figx = axexi+sum(axex)+nxtot*xspace+3*titlespace;
figy = axeyi+nytot*(axey+yspace)+titlespace;
% create figure
plt1 = figure;
set(plt1,'Units','centimeters',...
    'Position',[figxi figyi figx figy],...
    'PaperPositionMode','auto',...
    'Renderer','Painters'); % updated Mar 21 to add renderer to ensure can be printed as vector
% calculate positions for individual axes
axexp = axexi+[0 axex(1)+xspace sum(axex(1:2))+2*xspace]; % x positions
axeyp = fliplr(axeyi+[0:nytot-1]*(axey+yspace)); %y positions
axeypcor = axeyp+axey;

%% loop through each component 
for nc = 1:1:nctot
    % create time series axes
    long = axes('Units','centimeters',...
        'Position',[axexp(1) axeyp(nc) axex(1) axey],...
        'NextPlot','add',...
        'YLim',[ymin(nc) ymax(nc)],...
        'XLim',[0 xmax],...
        'XTick',xmem,...
        'XTickLabel',[ ],...
        'XGrid','on','YGrid','on');
    ylabel([comp{nc},' (ms^{-1})']);
    % if correlation data exists
    if ~isempty(COR)
        % create correlation axes
        coraxe = axes('Units','centimeters',...
            'Position',[axexp(1) axeypcor(nc) axex(1) axey*0.2],...
            'YLim',[yminc ymaxc],...
            'XLim',[0 xmax],...
            'XTick',xmem,...
            'XTickLabel',[],...
            'XGrid','on','YGrid','on');
        ylabel('Corr (%)');
        % add 70% line for reference
        line([0 xmax],[70 70],'Color','r','LineStyle',':')
    end
    % create boxplot axes
    box = axes('Units','centimeters','Position',[axexp(2) axeyp(nc) axex(2) axey]);
    % create power spectra axes
    powr = axes('Units','centimeters',...
        'Position',[axexp(3) axeyp(nc) axex(3) axey],...
        'NextPlot','add',...
        'YLim',[yminpp ymaxpp],...
        'XLim',[xminpp xmaxpp],...
        'YTick',[yminpp:1:ymaxpp],...
        'XTick',[xminpp:1:xmaxpp],...
        'XGrid','on',...
        'YTickLabel',ypp,...
        'XTickLabel',[],...
        'YAxisLocation','right');
    ylabel('p(x) (m^2s^{-1})');
    % add grid lines at -5/3 slope
    for nl = ymaxpp+5:-1:yminpp-5
        line([-3 6],[nl+5 nl-10],...
        'Color',[0.5 0.5 0.5],...
        'LineStyle','--');
    end
    
    % set x and y axes labels
    % for the first (upper) axes
    if nc == 1
        % set title
        set(plt1,'CurrentAxes',long); 
        text(0,ymin(1)+1.3*yrange(1),titover,'HorizontalAlignment','left','FontSize',14) ;
    end
    % for the last (bottom) component, add labels
    if nc == nctot
        set(get(long,'XLabel'),'String','Time (s)');
        set(long,'XTickLabel',xlabels);
        set(get(powr,'XLabel'),'String','Frequency (s^{-1})');
        set(powr,'XTickLabel',[xpp]);
    end

    %% add data to axes
    % velocity time series
    set(plt1,'CurrentAxes',long);
    for na = 1:2%natot
        vline = line(1:nttot,pdat(:,na,nc),...
            'Color',colo{na},...
            'LineWidth',linw(na));
    end
    if nc == nctot
        legend(leg)
    end
%     spikeline = line(spikey(:,1),pdat(spikey(:,1),1,nc),...
%         'Color','g',...
%         'LineStyle','none',...
%         'Marker','o');
    % correlation
    if ~isempty(COR)
        set(plt1,'CurrentAxes',coraxe);
        corline = line(1:nttot,COR(:,nc));
    end
    % boxplot
    set(plt1,'CurrentAxes',box);
    boxplot(pdat(:,:,nc),1,'r+',1,2.0,'labels',leg,'plotstyle','compact')
    set(box,...
        'Position',[axexp(2) axeyp(nc) axex(2) axey],...
        'YLim',[ymin(nc) ymax(nc)],...
        'YTickLabel',[],...
        'XGrid','on','YGrid','on');
    % spectra using pwelch
    set(plt1,'CurrentAxes',powr);
    for na = 1:2%natot
        [Px,fx]=pwelch(pdat(:,na,nc),window,noverlap,nfft,Hz);
        pline = line(log10(fx),log10(Px),...
            'Color',colo{na},...
            'LineWidth',linw(na));
    end

end 