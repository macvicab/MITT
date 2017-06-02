function faQC = DefaultfaQC
% % default parameters for filter array Quality Control analysis
% called from MITT 
 
faQC.Range = 1;
faQC.nigood = 8;
faQC.negood = 200;
faQC.pctmodecheck = 0;
faQC.pctmode = 20;
faQC.Correlation = 0;
faQC.Corthreshold = 70;
faQC.pctmodecheck = 1;
faQC.pctmode = 10;
faQC.xcorr = 1;
faQC.xcorrthreshold = 90;
faQC.w1w2xcorr = 0;
faQC.w1w2xcorrthreshold = 5;
faQC.Spikes = 1;
faQC.SpikeThreshold = 10;
faQC.InertialSlope = 0;
faQC.InertialSlopeThreshold = -1;
faQC.PolyFilt = 1;
faQC.zscore = 3.08;% z score for 3rd order polynomial

end