function [velseg,cellmod,details] = Spike1DetectReplaceARMA(velseg, vseasons, cellmod, ARMAopts, adjustmodel)
%% Subprogram for determining location of spikes
% requires a velocity segment and a model

% start timer
tic
% initial parameters
nsr = 0;
na = 0; % counter for model updates
kurtlog = [];
spikeidx = [];
nsmax = length(velseg)*ARMAopts.spikemax;

% initialize spikey for while loop
spikey = 1;
% start of while loop
while spikey
    % if you want to have the model coefficients updated as spikes are replaced
    if adjustmodel && na>ARMAopts.updatemodel
        % reestimate model coefficients
        [cellmod,ARMAopts] = GetModelARMA(velseg,ARMAopts);
        % reset counter
        na = 0;
    end
    
    % find the 'best' spike to replace
    % typically the largest residual, but subject to a number of conditions
    [spikei,zE] = findspike(velseg, vseasons, cellmod, ARMAopts);
    
    kurtlog = [kurtlog kurtosis(zE)]; %update kurtosis log

    if ARMAopts.cond(zE)
        % use the simulate algorithm to replace values
        velY0 = velseg(spikei(1)-cellmod.P:spikei(1)-1);
        velseg(spikei) = simulate(cellmod,length(spikei),'Y0',velY0);

        % update values
        nsr = nsr+length(spikei); % update spike count
        na = na+length(spikei); %update counter
        spikeidx = [spikeidx spikei]; % update spike replacement index

    else
        spikey = false;
    end  

    % check for a maximum spike number value to avoid endless loops
    if nsr>nsmax
        spikey = false;
    end
    
    % adjust model 
    % provided that this is turned on, na is greater than the number of
    % loops required for the update model, or if the data is no longer
    % spikey (final model is saved)
    if (adjustmodel && na>ARMAopts.updatemodel) || (adjustmodel && ~spikey)
        [cellmod,ARMAopts] = GetModelARMA(velseg,ARMAopts);
        % reset counter
        na = 0;
    end
end
% save details
details.ARnsr = nsr;
details.ARkurtlog = kurtlog;
details.ARspikeidx = spikeidx;
details.ARmean = mean(velseg);
details.ARstd = std(velseg);
details.ElapsedTime = toc;

end

function [spikei,zE] = findspike(velseg, vseasons, cellmod, ARMAopts)
% velseg is the velocity segment
% spikei is an index of possible detected spikes
% cellmod is the ARIMA model structure

% xwarm is the number of places needed for the model to 'warm up' i.e. cellmod.P
xwarm = cellmod.P;
%determine residuals using infer for that block
E = infer(cellmod, velseg(xwarm+1:end),'Y0',velseg(1:xwarm));
%Eseason = infer(cellmod, velseg(xwarm+1:end),'Y0',velseg(1:xwarm));
% calculate z-score of residuals
zE = (E-cellmod.Constant)/sqrt(cellmod.Variance);

% add while loop to check for values that are false spikes as a result of
% seasonal filter
falseseason = 1;
countfalse = 0;
while falseseason
    % identify location of biggest difference from model 
    [spikev,spikei] = max(abs(zE));

    % calculate z value without seasons effect
    zEseasons = (E(spikei)+vseasons(spikei)-cellmod.Constant)/sqrt(cellmod.Variance);
    % identify second largest spike
    zEp = zE(spikei);
    zE(spikei)=0;
    [spikev2,spikei2] = max(abs(zE));
    % if seasons spike is still greater than the second largest spike
    if abs(zEseasons)>=spikev2
        falseseason =0;
    % else the seasons filter is what made the spike in the first place, so 
    % replace it with the non-seasonal value, which is at least closer to the expected value    
    else
        zE(spikei) = zEseasons;
        countfalse = countfalse+1;
    end
end
%disp(num2str(countfalse));

% check the neighbourhood
%Due to "shock-effect" the observation after the true spike can
%have a larger residual.  Move the spike indice back while there is
%a large value of zE within the previous time intervals up to the model order
checkv = ARMAopts.checkthresh*spikev; % checkthresh coefficient is empirical
retreat = true;
while retreat && spikei>xwarm
    backzE = abs(zE(spikei-xwarm:spikei-1)) > checkv;
    if any(backzE);
        moveback = find(backzE,1,'first');

        % check to see if it has backed up into the warm up area
        if spikei-xwarm+moveback-1 > xwarm
            spikei = spikei - xwarm + moveback-1;
            %signv = sign(zE(spikei)); %
        else
            % stop loop
            retreat = false;
        end
    else
        % stop while loop
        retreat = false;
    end
end



% add xwarm 
spikei = spikei+xwarm;

end