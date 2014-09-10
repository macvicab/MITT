function veldespike = SpikeSkewness(raw,UniMult,ReplacementMethod)
% detects spikes in a time series based on skewness

%% set thresholds and find location estimator
nttot = length(raw);
UniThresh = UniMult*(2*log(nttot))^0.5;          %CALCULATES UNIVERSAL THRESHOLD

% as per Wahl, T. L. (2003), Discussion of ‘‘Despiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 484-487.
% and supported by Goring, D. G., and V. I. Nikora (2003), Closure to ‘‘Depiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 487-488.
% use median as location estimator rather than mean
medianvel= median(raw);

%% calculate value for standard deviation from the side of the data farthest from zero 
% (the so-called 'seeding' error observed in UDVP data)

% for positive values
if medianvel>=0
    % subtract the median
    posvel = raw-medianvel;
% for negative values flip the data
elseif medianvel<0
    % subtract the data from the mode (so the 'good' data is flipped over to
    % the positive side for further analysis)
    posvel = medianvel-raw;
end
% use values on the positive side to define the standard error
posvelmem = posvel>0;
% calculate standard deviation of the 'good' data
stdpos = sqrt(sum(posvel(posvelmem).^2)/(sum(posvelmem)-1));

%% find and replace spikes
% calculate threshold that will detect 'poor' data on the negative side
absthreshold = -UniThresh*stdpos; % 

% find points below the threshold
spikeyes = posvel<absthreshold; 

% send to SpikeReplace if any spikes detected
if any(spikeyes)
    veldespike = SpikeReplace(spikeyes,raw,ReplacementMethod);
else
    veldespike = raw;
end
end


        