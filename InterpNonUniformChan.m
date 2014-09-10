function [oneD,twoD] = InterpNonUniformChan(filename)
% function to calculate water and bed grid for centerline (oneD) and entire
% section (twoD)

% Called from OrganizeInput
% requires use of griddedInterpolant embedded function

% grid resolution, i.e. the number of cells in x and y grid
gridRes = 50; 

% get flume positions from data file
% this program assumes that columns in the filename include xchannel,
% ychannel, zchannel, and wsurf
FlumePos = ConvCSV2Struct(filename,0);
xchannel = [FlumePos.xchannel]';
ychannel = [FlumePos.ychannel]';
zchannel = [FlumePos.zchannel]';
wsurf = [FlumePos.wsurf]';

%% 1D way
% isolate xpositions and find minimum bed and water surface
xu = unique(xchannel);
nxutot = length(xu);
bedi = zeros(nxutot,1);
wsurfi = zeros(nxutot,1);
% find minimum bed position
for nx = 1:nxutot
    xi = xchannel==xu(nx);
    bedi(nx) = min(zchannel(xi));
    wsurfi(nx) = min(wsurf(xi));
end

% interpolate on regular grid and put data into C structure
xmem = xu(1):(xu(end)-xu(1))/gridRes:xu(end);
ymem = min(ychannel):(max(ychannel)-min(ychannel))/gridRes:max(ychannel);

oneD.xchannel = xmem;
oneD.ymem = ymem;
oneD.bedElevation = interp1(xu,bedi,xmem);
oneD.waterElevation = interp1(xu,wsurfi,xmem);

%% 2D way

% create 2D interpolants for bed and water surface
Fbed = scatteredInterpolant(xchannel,ychannel,zchannel,'linear','none');
Fwater = scatteredInterpolant(xchannel,ychannel,wsurf,'linear','none');

% isolate xpositions and interpolate to a finer grid
% create 2D grid for interpolation
[xgrid,ygrid]=ndgrid(xmem,ymem); % grid for 2d xy plane

twoD.xchannel = xgrid;
twoD.ychannel = ygrid;
twoD.bedElevation = Fbed(xgrid,ygrid);
twoD.waterElevation = Fwater(xgrid,ygrid);
% can get the bed and water surface position of any x and y point
twoD.Fbed = Fbed; 
twoD.Fwater = Fwater;


end