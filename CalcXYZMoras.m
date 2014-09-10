function Config = CalcXYZMoras(GUIControl,Config)
% rotate data from local coordinate system to global system

% user parameters
dmultiplier = 0.01;

% load bridgefile for rotation
bridgeDate = Config.bridgeDate;
if length(bridgeDate)<6
    bridgeDate = ['0',bridgeDate]; % to compensate for zeros that disappear when you go in and out of excel with a text file
end
bridgefile = [GUIControl.CSVControlpathname,'bridge',bridgeDate,'.mat'];
load(bridgefile); 

% choose the benchmark to which the local data points will be translated and
% around which they will be rotated
pont = eval(['bridge',bridgeDate]);
origg = find(pont(:,1) == 12);
% choose a second benchmark for calculation of rotation angle
rotg = find(pont(:,1) == 18);
% identify origin and rotation points
xgo = pont(origg,2);
ygo = pont(origg,3);
xgr = pont(rotg,2);
ygr = pont(rotg,3);
% transform rotation point into polar coordinates
[thetarot,rhorot] = cart2pol(xgr-xgo,ygr-ygo);

% calculate translation distances to global origin
% translate to origin (using point x=2,y=0)
xlt = Config.xlocal-0;
ylt = Config.ylocal-0;
%convert to polar
[thetal,rhol] = cart2pol(xlt,ylt);
% remove local angle (equal to 0), add global
thetalr = thetal-0+thetarot;
% transform back into cartesian
[xltr,yltr] = pol2cart(thetalr,rhol);
% add constants to obtain new coordinates
Config.xpos=xltr+xgo;
Config.ypos=yltr+ygo;

% calculate zpos data
Config.zpos = [Config.z1 Config.z2 Config.z3 Config.z4]*dmultiplier;
Config.waterDepth = Config.waterDepth*dmultiplier;
Config.bedElevation = Config.bridgeElevation-Config.bridgeDepth*dmultiplier; % bed surface 
end