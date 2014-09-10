function [oneD,twoD] = InterpUniformChan(Slope,Width,Depth,Length,Sideslope,Widthgrid,Depthgrid,Lengthgrid)
% function to calculate water and bed grid for centerline (oneD) and entire
% section (twoD)
% only works for trapezoidal, rectangular, and triangular channels
% Called from OrganizeInput
% requires use of griddedInterpolant embedded function

% centerline 1D data (common to all channel types)
xmem = 0:Lengthgrid:Length;
nxtot = length(xmem);
bed = zeros(1,nxtot)-Slope*xmem;
wsurf = bed+Depth;

oneD.bedElevation = bed;
oneD.waterElevation = wsurf;
oneD.xchannel = xmem;

% 2D bed and water surface calculation (rectangular, trapezoidal, and
% triangular only)
topwidth = Width + 2*Sideslope*Depth;
ymemi = -topwidth/2:Widthgrid:topwidth/2;
nmiddle = Width/Widthgrid;
% create cross section bed elevation
zcrossside = 0:Widthgrid/Sideslope:Depth;
zcross = [fliplr(zcrossside) zeros(1,nmiddle+1) zcrossside];
% add an extra point on either end of cross sections at the channel depth
ymem = [-topwidth/2-Widthgrid ymemi topwidth/2+Widthgrid];
oneD.ymem = ymem;

% 2D bed and water surface
nytot = length(ymem);
bed2 = zeros(nxtot,nytot);
wsurf2 = zeros(nxtot,nytot);
for nx=1:nxtot
    bed2(nx,:) = zcross+bed(nx);
    wsurf2(nx,:) = bed(nx)+Depth;
end

[xgrid,ygrid]=ndgrid(xmem,ymem); % grid for 2d xy plane

Fbed = griddedInterpolant(xgrid,ygrid,bed2,'linear','none');
Fwater = griddedInterpolant(xgrid,ygrid,wsurf2,'linear','linear');

twoD.xchannel = xgrid;
twoD.ychannel = ygrid;
twoD.bedElevation = Fbed(xgrid,ygrid);
twoD.waterElevation = Fwater(xgrid,ygrid);
% can get the bed and water surface position of any x and y point
twoD.Fbed = Fbed; 
twoD.Fwater = Fwater;

end