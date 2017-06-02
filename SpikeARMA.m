function [despike,vseasons,ARMA] = SpikeARMA(velnomedian,ARMAopts,goodCellsMode)
% Despike a 2D array of data using the ARMA method
% called from CleanSpike

% Inputs:
% velnomedian - velocity data with median removed from each column
% ARMAopts - ARMA options
% goodCellsMode - preliminary classification of data quality (typically
% from ClassifyMode) so that obviously poor time series can be skipped

% Outputs:
% despike - despiked velocity array
% vseasons - low frequency filter removed from velnomedian prior to despiking
% ARMA - model details and despiking procedure details

%  Determine size of array
% nttot is the number of time intervals, nCtot is the number of columns,
% which is the number of time series.
[nttot,nCtot] = size(velnomedian);

% Determine suitable ARMA models
[ARMA,ARMAdetails.model,ARMAopts] = ARMA_model(velnomedian,goodCellsMode,ARMAopts);

% Despike data using fitted ARMA models
[despike,vseasons,ARMAdetails.despike] = ARMA_despike(velnomedian,goodCellsMode, ARMA, ARMAopts);

% Save ARMA details
for nC =1:nCtot
    if goodCellsMode(nC)
        for nseg = 1:ARMAopts.nsegtot
            ARMA(nseg,nC).modeldetails = ARMAdetails.model(nseg,nC);
            ARMA(nseg,nC).despikedetails = ARMAdetails.despike(nseg,nC);
        end
    end
end
end

function [ARMA,ARMAdetails,ARMAopts] = ARMA_model(vel,goodCells,ARMAopts)

% turn on ability to adjust model as spikes are replaced
adjustmodel = true;

% create structure array of empty ARMA models
% loop preparation
[nttot,nCtot] = size(vel);
nsegtot = ARMAopts.nsegtot;
nobs = ARMAopts.nobs;
if isempty(ARMAopts.nobs_short)
    nmodel = nttot;
else
    nmodel = ARMAopts.nobs_short;
end

ARMA(nsegtot,nCtot)=struct('model',[]);
ARMAdetails(nsegtot,nCtot) = struct('ARnsr',[],'ARkurtlog',[],'ARspikeidx',[],...
    'ARmean',[],'ARstd',[],'ElapsedTime',[]);

%Estimate & clean ARMA  models for each segment
% for each Cell
for nC = 1:nCtot
    % display Cell number for user
    disp(num2str(nC));
    % check goodCells
    if goodCells(nC)
        % for each segment
        for nseg = 1:nsegtot;
            % start timer
            tic

            % find end points of segment
            segb = nobs*(nseg-1)+1;
            sege = min([segb+nmodel-1, nttot]);
            % isolate the velocity segment
            [velseg,vseasoni] = getvelseg(vel, nC, segb, sege, goodCells,ARMAopts.seasons);
            
            %1
            velin = velseg-vseasoni;

            [cellmod,ARMAopts] = GetModelARMA(velin,ARMAopts);

            [~,cellmod,details] = Spike1DetectReplaceARMA(velin, vseasoni, cellmod, ARMAopts, adjustmodel);
            
           
            % store model and fit quality parameters
            % should change to create matrices of parameters
            ARMA(nseg,nC).model = cellmod;
            ARMAdetails(nseg,nC) = details;

        end
    end
end

end
%%%%
function [despike,vseasons,ARMAdetails] = ARMA_despike(vel, goodCells, ARMA, ARMAopts)

% turn off ability to adjust model as spikes are replaced
adjustmodel = false;

% loop preparation
[nttot,nCtot] = size(vel);
nsegtot = ARMAopts.nsegtot;
nobs = ARMAopts.nobs;

vseasons = zeros(nttot,nCtot);
despike = zeros(nttot,nCtot);

ARMAdetails(nsegtot,nCtot) = struct('ARnsr',[],'ARkurtlog',[],'ARspikeidx',[],...
    'ARmean',[],'ARstd',[],'ElapsedTime',[]);

% for each cell
for nC = 1:nCtot
    % display Cell number for user
    disp(num2str(nC));
    % check goodCells
    if goodCells(nC)
        % for each segment
        for nseg = 1:nsegtot;

            % find end points of segment
            segb = nobs*(nseg-1)+1;
            sege = min([segb+nobs-1, nttot]);
            % isolate and deseason velocity
            [velseg,vseasoni] = getvelseg(vel, nC, segb, sege ,goodCells,ARMAopts.seasons);
 
            % get model
            % should change to interpolate from matrices of model parameters
            cellmod = ARMA(nseg,nC).model;

            % initialize segment i outputs
            velin = velseg-vseasoni; % note that vseasoni is only zeros if ARMAopts.seasons==0

            [velsegi,~,details] = Spike1DetectReplaceARMA(velin, vseasoni, cellmod, ARMAopts, adjustmodel);

            % save outputs
            despike(segb:sege,nC) = velsegi;
            vseasons(segb:sege,nC) = vseasoni;
            ARMAdetails(nseg,nC) = details;
        end
    end
end

end
%%%%
function [velseg,vseasoni] = getvelseg(vel, nC, segb, sege, goodCells,yseasons)
% vel is the 2D velocity time series (timeseries in columns, first row
% closest to the water surface
% nC is the cell (y) number
% nseg is the segment (x) number
% nmodel is the number of grid cells used to calculate the ARIMA model
% ndespike is the number of grid cells to which the model will be applied
% v2p5 modified to calculate the median

% 2D averaging weights, leaving the middle empty to highlight errors.
% error program works from 1 - end, which is normally from water surface
% towards bed, so the top 2 rows are also set to zero as they will include
% spikey data
%F = [0 0 0 2 2;0 0 0 2 1;0 0 0 4 2;0 0 0 2 1;0 0 0 0 0]; % tested Aug 31 2015 - works for timeseries in columns with first column closest to the water surface
F = [0 0 0 1 1;0 0 0 1 1;0 0 0 1 1;0 0 0 1 1;0 0 0 1 1]; % tested Aug 31 2015 - works for timeseries in columns with first column closest to the water surface

[~,nCtot] = size(vel);
% get columnsn (cells) of interest
Cb = max([nC-2 1]);
Ce = min([nC+2,nCtot]);
nCi = 3;
if nC-Cb < 2
    nCi = nC;
end

% isolate the region of interest
velroi = vel(segb:sege,Cb:Ce);

if yseasons
    % isolate the goodCells (note that it has to be fliped up/down because of
    % the way the convolution with F works
    Cgood = flipud(goodCells(Cb:Ce));
    % blank out columns in F that are not good
    for nCg = 1:length(Cgood)
        if ~Cgood(nCg)
            F(:,nCg)=zeros(1,5);
        end
    end

    Ftot = sum(sum(F));
    if Ftot
        F = F/Ftot;
    end

    % filter out the 'seasons' using the goodCells in F       
    vseasonroi = conv2(velroi,F,'same'); 
else
    vseasonroi = zeros(size(velroi));
end

vseasoni = vseasonroi(:,nCi);
velseg = velroi(:,nCi);

end



