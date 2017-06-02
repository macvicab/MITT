function [cellmod,ARMAopts] = GetModelARMA(velseg,ARMAopts)
% get an arima model for a velocity segment given the options in ARMAopts

%% if the BIC test is activated to determine the optimal numbers for model
% order (pin, qin)
if ARMAopts.findpqbic
    [pin,qin] = TestARMAfit1(velseg);
else
    % use fixed order from ARMAopts
    pin = ARMAopts.pfix;
    qin = ARMAopts.qfix;
end

%% create model
modelname = arima(pin,0,qin);
% check number of existing default intial guesses for AR model
nARtot = length(ARMAopts.AR0);
% if there are not enough, add (without going over a sum of 1)
if pin>nARtot
    ARMAopts.AR0 = [ARMAopts.AR0 0.1*ones(1,pin-nARtot)];
% else if there are too many, delete
elseif pin<nARtot
    ARMAopts.AR0(pin+1:end) = [];
end
% check number of existing default intial guesses for MA model
nMAtot = length(ARMAopts.MA0);
% if there are not enough, add (without going over a sum of 1)
if qin>nMAtot
    ARMAopts.MA0 = [ARMAopts.MA0 0.1*ones(1,qin-nMAtot)];
% else if there are too many, delete
elseif qin<nMAtot
    ARMAopts.MA0(qin+1:end) = [];
end    

% estimate initial model
cellmod = estimate(modelname,velseg,'print',false,'options',ARMAopts,...
    'Constant0',ARMAopts.Constant0,'AR0',ARMAopts.AR0,'MA0',ARMAopts.MA0,...
    'Display','off');

% update initial guesses
ARMAopts.Constant0 = cellmod.Constant;
ARMAopts.AR0 = cellmod.AR;
ARMAopts.MA0 = cellmod.MA;
ARMAopts.Variance0 = cellmod.Variance;

% set cutoff method
if ARMAopts.Cutoffmethod == 1
    ARMAopts.cond = @(x) jbtest(x,ARMAopts.JBAlpha);
elseif ARMAopts.Cutoffmethod == 2
    ARMAopts.cond = @(x) kurtosis(x)>ARMAopts.kurtthresh;  
end

end

%%%%%
function [pmin,qmin] = TestARMAfit1(dati)
%% use BIC test to determine the optimal numbers for model
nmax = 4; % maximum number of p or q parameters for arima model (hardcode to limit size of matrix)

LOGL = zeros(nmax,nmax); %Initialize 
PQ = zeros(nmax,nmax);
for p = 1:nmax
    for q = 1:nmax
        mod = arima(p,0,q-1);
        %[EstMdl,estParams,EstParamCov,logL,Output] = estimate(mod,dati,'print',false);
        [~,~,logL] = estimate(mod,dati,'print',false);
        LOGL(p,q) = logL;
        PQ(p,q) = p+q;
     end
end

%% calculate Bayesian Information Criterion (BIC) for the fitted models
LOGL = reshape(LOGL,nmax^2,1);
PQ = reshape(PQ,nmax^2,1);
[~,bic] = aicbic(LOGL,PQ+1,100);
% reshape and normalize
bic = (reshape(bic,nmax,nmax))/length(dati);

[~,qminp] = min(min(bic));
qmin = qminp-1;

[~,pmin] = min(min(bic,[],2));

%disp(['The best model is an arima{',num2str(pmin),',0,',num2str(qmin),') model']);
end
