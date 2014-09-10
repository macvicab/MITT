function despiked = SpikeVelCorr(raw,Hz,UniMult,ReplacementMethod)
%Velocity Correlation Spike Detection
% from Cea, L., J. Puertas, and L. Pena (2007), Velocity measurements on highly turbulent free surface flow using ADV, Experiments in Fluids, 42(3), 333-348.
% called from CleanSpike
% calls SpikeReplace
% subfunction inellipse


%% control parameters
windowSize = Hz*5; % filtersize window for removal of long term trends
counterlim = 4; % sets the maximum number of spike detection loops
spikelim = 5;

%% initial parameters
[nttot,ncomptot] = size(raw);
UniThresh = UniMult*(2*log(nttot))^0.5;          %CALCULATES UNIVERSAL THRESHOLD
sig = (0:2*pi/144:2*pi);

%% prepare velocity time series for analysis
% create vel and yes matrices
vel = zeros(nttot,ncomptot);
yes = vel;
% % remove long scale trends
% for ncomp = 1:ncomptot
%     v2 = filter(ones(1,windowSize)/windowSize,1,raw(:,ncomp));
%     vel(:,ncomp) = raw(:,ncomp)-v2;
% end
% remove mean (and trends) of velocity components
vel = detrend(raw);
stdvel = std(vel);

% calculate the reynolds stress terms
reyn = vel'*vel;

%% loop to remove spikes
% initialize variables
spike = 1;
counter = 0;

while spike

    % xa and ya specify the order of the x and y axis variables respectively
    xa = [1 1 2]; ya = [2 3 3];
    % loop for each axis
    for fg = 1:3
        % set component number for each combination
        a = xa(fg); b = ya(fg);
        % calculate theta
        theta = atan(reyn(a,b)/reyn(a,a)); % equation 5 in Cea et al 2007
        % calculate major and minor axes of ellipse (Equation 6 in Cea et al 2007)
        xo = ((UniThresh*stdvel(a)*cos(theta))^2-(UniThresh*stdvel(b)*sin(theta))^2)/(cos(theta)^2-sin(theta)^2);
        yo = ((UniThresh*stdvel(b)*cos(theta))^2-(UniThresh*stdvel(a)*sin(theta))^2)/(cos(theta)^2-sin(theta)^2);
        
        %General equation of an ellipse.  
        %General form doens't include the squared. 
        %Calculating radius of the points along the ellipse - using angles in radians
        r = ((xo^2*yo^2)./(xo^2*(sin(sig)).^2+yo^2*(cos(sig)).^2)).^0.5;
        
        %This creates an ellipse in cartesian coords (non-tilted) 
        [xi,yi] = pol2cart(sig,r);
        %This tilts the ellipse at the rotation angle (theta)
        x = xi*cos(theta)-yi*sin(theta);
        y = yi*cos(theta)+xi*sin(theta);

        %Determines if point for a given velocity falls within the ellipse or not.  The yes matrix is keeping track of where outliers are located   
        %check = ~inpolygon(vel(:,a),vel(:,b),x,y);
        yes(:,fg) = ~inellipse(vel(:,a),vel(:,b),x,y);
        
    end
    %Determines if a spike occurs in any components
    spikeyes = yes(:,1)|yes(:,2)|yes(:,3);
    % replace spikes
    veldespike = SpikeReplace(spikeyes,vel(:,1),ReplacementMethod);

    spike = sum(spikeyes)>spikelim & counter < counterlim; %set limit for iteration at 5 spikes or 5 loops
    counter = counter+1;
end
% create despiked series and add the mean back into data
despiked = veldespike+mean(raw)+v2;

end

function yes = inellipse(xDat,yDat,xEllipse,yEllipse);
% determines whether positions (xDat,yDat) are in an ellipse 

% intialize output
yes = zeros(size(xDat))==0;
%% prepare ellipse
% convert cartesian ellipse coordinates into polar coordinates
[angEllipse,rEllipse]=cart2pol(xEllipse,yEllipse);
% delet end value
angEllipse(end) = [];
rEllipse(end) = [];
%sort Ellipse data
[~,sortIDX] = sort(angEllipse);
angEllipse = angEllipse(sortIDX);
rEllipse = rEllipse(sortIDX);
% close the loop
angEllipse = [angEllipse(end)-2*pi angEllipse ];
rEllipse = [rEllipse(end) rEllipse ];
ravgEllipse = rEllipse(1:end-1)+diff(rEllipse)/2;

%% determine in or out status of points
% convert x and y dat to polar coordinates
[angDat,rDat]=cart2pol(xDat,yDat);
% sort points with a histogram
[n,angIDX] = histc(angDat,angEllipse);
% get last bin and set to next to last
nogoo = find(angIDX == length(angEllipse) | angIDX == 0);
angIDX(nogoo) = 1;
% determine all angles
angmem = unique(angIDX);
% for each angle, determine whether points are greater or less than the
% radius
natot = length(angmem);
for na=1:natot
    goo = angIDX == angmem(na);
    yes(goo) = rDat(goo)<=ravgEllipse(angmem(na));
end
end