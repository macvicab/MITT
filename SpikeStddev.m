function veldespike = SpikeStddev(raw,Hz,UniMult,ReplacementMethod)
% detects spikes in a time series based on skewness

% set skewness threshold (hardcoded for the moment)
% zthreshold = 7.0;
windowSize = Hz*5; % 5 seconds for highpass filter
nttot = length(raw);
UniThresh = UniMult*(2*log(nttot))^0.5;          %CALCULATES UNIVERSAL THRESHOLD

% calculate statistics
%umean = mean(raw);
%ustd = std(raw);
% modified as per Wahl, T. L. (2003), Discussion of ‘‘Despiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 484-487.
% and supported by Goring, D. G., and V. I. Nikora (2003), Closure to ‘‘Depiking Acoustic Doppler Velocimeter Data’’ by Derek G. Goring and Vladimir I. Nikora, Journal of Hydraulic Engineering, 129(6), 487-488.
% use median as location estimator rather than mean
umedian= median(raw);
stdvel = 1.483*median(abs(raw-umedian));

% remove long scale trends
% velnomean = raw-mean(raw);
% v2 = filter(ones(1,windowSize)/windowSize,1,velnomean);
% velhighpass = raw-v2;

% calculate absolute thresholds
umin = umedian-UniThresh*stdvel;
umax = umedian+UniThresh*stdvel;

% find points outside the range of 'good' data
spikeyes = raw<umin | raw>umax;

% send to SpikeReplace if any spikes detected
if any(spikeyes)
    veldespike = SpikeReplace(spikeyes,raw,ReplacementMethod);
else
    veldespike = raw;
end
end


        