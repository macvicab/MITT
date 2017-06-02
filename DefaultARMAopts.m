function ARMAopts = DefaultARMAopts

ARMAopts = optimset('fmincon'); %Find minimum of constrained nonlinear multivariable function

% optimization options.  Not tested - default values used.
ARMAopts.Algorithm = 'sqp';    % Changed from default 'interior-point', recommended for faster results with small- to medium-sized problems
ARMAopts.MaxFunEvals = 2000;   % Maximum number of function evaluations allowed
ARMAopts.TolCon = 1e-6;%5e-2;  % Tolerance on the constraint violation, a positive scalar. The default is 1e-6.
ARMAopts.TolFun = 1e-6;%0.1;   % Termination tolerance on the function value, a positive scalar. The default is 1e-6.
ARMAopts.TolX = 1e-6;%1e-8;    % Termination tolerance on x, a positive scalar. The default value for all algorithms except 'interior-point' is 1e-6
ARMAopts.Display = 'off'; 

% model type
ARMAopts.seasons = false; % turn on seasonality algorithm to remove large scale trends

ARMAopts.findpqbic = false;
ARMAopts.pfix = 1;
ARMAopts.qfix = 0;
ARMAopts.Constant0 = 0;% value to use as initial guesses for optimization.  Can be changed to
ARMAopts.AR0 = [0.7];% value to use as initial guesses for optimization.
ARMAopts.MA0 = [];


% speed up calculations for different data sets

ARMAopts.nobs_short = 1000;% %number of observations used to estimate model (and applied to entire segment). Previously 250.  Up to 625.  back to 500.
ARMAopts.nobs_long =[]; % %number of observations to which cleaned models are applied.  Empty brackets mean the model will be applied to the entire cell
ARMAopts.updatemodel = 10; % number of spike replacements before model is updated
% note that [] for the above variables means that the whole time series will be used

ARMAopts.JBAlpha = 0.001; %value to use to test data for normality using the Jarque-Bera test 
ARMAopts.Cutoffmethod = 2; %1 for Jarque Bera, 2 for Kurtosis
ARMAopts.cutkurt = true; % turn cutkurt option on to stop spike replacement when kurtosis is less than a threshold
ARMAopts.kurtthresh = 4;    %empirical.  Cutoff for kurtosis.
ARMAopts.checkthresh = 0.75; % empirical. % of current residual used as threshold to check for previous spikes as part of shock effect

% Group spike parameters
% ARMAopts.groupspike = false;
% ARMAopts.lookaround =20;    %empirical
% ARMAopts.groupkurtthresh = 5*ARMAopts.kurtthresh; % empirical result.  Works well for Vectrino II data

% ARMAopts.deltakurt =0.05*ARMAopts.cutkurt ;   %empirical. 
% ARMAopts.minkurt = 6;   %empirical

ARMAopts.spikemax = 0.05; % stop despiking after spikemax% of data is replaced

ARMAopts.cutrms = 1.2; %empirical. for corrupt cell detection
ARMAopts.zscore = 1.96; %empirical.  For corrupt subprogram.  z-score to include 95% of area of residuals

ARMAopts.pctmode = 0.20;%0.015 used by Scott for Vectrino, too low for UDVP
end