function [oneD,twoD] = CalcIllinoisFlumePos(GUIControl,CSVControl)
% calculate 1 and 2D surfaces for plotting and calculation

filename = [GUIControl.CSVControlpathname,CSVControl(1).ffname,'.csv'];

% get flume positions from data file
[xchannel,ychannel,zchannel,beamh,wsurf]=textread(filename,'%f %f %f %f %f',...
    'delimiter',',','commentstyle','matlab');

%% 1D way
% isolate xpositions and interpolate to a finer grid
xu = unique(xchannel);
nxutot = length(xu);
bedi = zeros(nxutot,1);
wsurfi = zeros(nxutot,1);
beamhi = zeros(nxutot,1);

% find average bed position
for nx = 1:nxutot
    xi = xchannel==xu(nx);
    bedi(nx) = mean(zchannel(xi));
    wsurfi(nx) = mean(wsurf(xi));
    beamhi(nx) = mean(beamh(xi));
end

% interpolate on regular grid and
% put data into C structure
xmem = xu(1):diff(xu)/200:xu(end);
oneD.xchannel = xmem;
oneD.bedElevation = interp1(xu,bedi,xmem);
oneD.waterElevation = interp1(xu,wsurfi,xmem);
oneD.beamh = interp1(xu,beamhi,xmem);
oneD.Y = CSVControl(1).Y*ones(1,length(xmem));

% isolate xpositions and interpolate to a finer grid
ymem = 0:CSVControl(1).Y/20:CSVControl(1).Y;
oneD.ymem = ymem;

%% 2D way 

% create 2D grid for interpolation
[xgrid,ygrid]=ndgrid(xmem,ymem); % grid for 2d xy plane

% create 2D interpolants for bed and water surface
Fbed = scatteredInterpolant(xchannel,ychannel,zchannel,'linear','linear');
Fwater = scatteredInterpolant(xchannel,ychannel,wsurf,'linear','linear');


twoD.xchannel = xgrid;
twoD.ychannel = ygrid;
twoD.bedElevation = Fbed(xgrid,ygrid);
twoD.waterElevation = Fwater(xgrid,ygrid);
% can get the bed and water surface position of any x and y point
twoD.Fbed = Fbed; 
twoD.Fwater = Fwater;

end
