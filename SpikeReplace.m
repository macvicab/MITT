function veldespike = SpikeReplace(spikeyes,vel,ReplacementMethod);
% replaces detected spikes in time series
% called from SpikeSkewness and SpikeGoringNikora

% set output equal to input to start
veldespike = vel;

%% define one spike as a continuous series of spikes
% find spike begining and end points of spikes
spikes = find(diff(spikeyes)>0);
spikee = find(diff(spikeyes)<0);
% eliminate solo spikes (i.e. one end but no beginning, or vice versa)
if isempty(spikes)
    spikee = [];
end
if isempty(spikee)
    spikes = [];
end
% loops to eliminate unfinished or unstarted spikes
if ~isempty(spikee) || ~isempty(spikes)
    if spikee(1) < spikes(1)
        spikee(1) = [];
    end
    if ~isempty(spikee)
        if spikes(end)>spikee(end)
            spikes(end) = [];
        end
    else
        spikes(end) = [];
    end
end

%% replace spikes
% calculate total number of spikes
spiketot = length(spikes);

for snum = 1:spiketot
    % replacement algorithm
    if ReplacementMethod == 1
        % linear interpolation
        veldespike(spikes(snum)+1:spikee(snum)) = interp1([spikes(snum) spikee(snum)+1],...
            [vel(spikes(snum)) vel(spikee(snum)+1)],[spikes(snum)+1:spikee(snum)]);
    end
end

