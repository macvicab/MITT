function veldespike = SpikeGoringNikora(velnomedian,UniMult,ReplacementMethod,Parsheh)
%GORING AND NIKORA PHASE SPACE FILTER
% from Goring, D.G. and Nikora, V.I. 2002. Despiking Acoustic Doppler
% Velocimeter data. Journal of Hydraulic Engineering, 128: 117-126.
% called from CleanSpike
% calls SpikeReplace
% subfunction inellipse
% modified June 2016 by BM to move preprocessing to CleanSpike

%% control parameters
%windowSize = Hz*5; % filtersize window for removal of long term trends
counterlim = 4; % sets the maximum number of spike detection loops

%% initial parameters
nttot = length(velnomedian);
spikelim = max([5 floor(nttot*0.001)]); % sets the minimum number of detected spikes to initiate loop post replacement
UniThresh = UniMult*(2*log(nttot))^0.5;          %CALCULATES UNIVERSAL THRESHOLD
sig = (0:2*pi/144:2*pi);

%% prepare velocity time series for analysis
% create vel and yes matrices
vel = zeros(nttot,3);
yes = vel;
% % remove long scale trends
% velnomean = raw-mean(raw);
% v2 = filter(ones(1,round(windowSize))/round(windowSize),1,velnomean);
% velhighpass = raw-v2;
% 
% % modified as per Wahl, T. L. (2003), Discussion of ‘‘Despiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 484-487.
% % and supported by Goring, D. G., and V. I. Nikora (2003), Closure to ‘‘Depiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 487-488.
% % use median as location estimator rather than mean
% velnomedian = velhighpass-median(velhighpass);
% 
vel(:,1) = velnomedian;

%% loop to remove spikes
% initialize variables
spike = 1;
counter = 0;

while spike
    % step 1 - calculate surrogates for the first and second derivatives
	vel(2:end-1,2) = (vel(3:end,1)-vel(1:end-2,1))/2;
	vel(3:end-2,3) = (vel(4:end-1,2)-vel(2:end-3,2))/2;
	
	% step 2 - calculate the standard deviation of the three variables
	%stdvel = std(vel);
    % modified as per Wahl, T. L. (2003), Discussion of ‘‘Despiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 484-487.
    % and supported by Goring, D. G., and V. I. Nikora (2003), Closure to ‘‘Depiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 487-488.
    % use median absolute deviation multiplied by an estimator that makes it analogous to the standard deviation (1.483) to make it
    % equivalent to the standard deviation
    for nv = 1:3
        stdvel(nv) = 1.483*median(abs(vel(:,nv)-median(vel(:,nv))));
    end
	%% new jay data
	% step 2b - calculate the theoretical maxima using the Universal criterion
	maxvel = stdvel*UniThresh;
	
	% step 3 - calculate the rotation angle of the principle axis of veldd vs vel
    theta(1:2) = 0;
	theta(3) = atan(sum(vel(:,1).*vel(:,3))./sum(vel(:,1).^2));
	
	% step 4 - calculate the ellipse for each pair of variables
    % xa and ya specify the order of the x and y axis variables
    % respectively
    xa = [1 2 1]; ya = [2 3 3];
    % loop for each axis
    for fg = 1:3
        a = xa(fg); b = ya(fg);
        %General equation of an ellipse.  
        %General form doens't include the squared. 
        %Calculating radius of the points along the ellipse - using angles in radians
        r = ((maxvel(a)^2*maxvel(b)^2)./(maxvel(a)^2*(sin(sig)).^2+maxvel(b)^2*(cos(sig)).^2)).^0.5;
        %This creates an elipse in cartesian coords (non-tilted) 
        [xi,yi] = pol2cart(sig,r);
        %This tilts the ellipse at the rotation angle (theta)
        x = xi*cos(theta(fg))-yi*sin(theta(fg));
        y = yi*cos(theta(fg))+xi*sin(theta(fg));
        %Determines if point for a given velocity falls within the ellipse or not.  The yes matrix is keeping track of where outliers are located   
        %check = ~inpolygon(vel(:,a),vel(:,b),x,y);
        yes(:,fg) = ~inellipse(vel(:,a),vel(:,b),x,y);
        
    end
    %Determines if a spike occurs in the raw, 1st or 2nd derivate data sets
    spikeyes = yes(:,1)|yes(:,2)|yes(:,3);

    if Parsheh
    %Only spkies of extraneous values are accepted (Parsheh et al 2010)%
        % Identify "good" data (Parsheh et al 2010)%
        FVel(:,1)= vel(:,1)<= -stdvel(1) | vel(:,1)>=stdvel(1);
        spikeyes=spikeyes & FVel;
    end

    % replace spikes
    veldespike = SpikeReplace(spikeyes,vel(:,1),ReplacementMethod);

    spike = sum(spikeyes)>spikelim & counter < counterlim; %set limit for iteration at 5 spikes or 5 loops
    counter = counter+1;
end
% % create despiked series and add the median back into data
% despiked = veldespike+median(velhighpass)+v2;

end

function yes = inellipse(xDat,yDat,xEllipse,yEllipse)
% determines whether positions (xDat,yDat) are in an ellipse 

% intialize output
yes = zeros(size(xDat))==0;
%% prepare ellipse
% convert cartesian ellipse coordinates into polar coordinates
[angEllipse,rEllipse]=cart2pol(xEllipse,yEllipse);
if any(angEllipse>0)
    % delete end value
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
end