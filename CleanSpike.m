function Data = CleanSpike(Config,Data,GUIControl)
% controls detection and removal of spikes from time series
% called from AClean
% calls SpikeARMA, SpikeStdev, SpikeSkewness, SpikeGoringNikora, SpikeVelCorr
% subfunctions include ConvStruct2Multi, ConvMulti2Struct, ConvXYZ2Beam
% modified May 2016 to include SpikeARMA, corrected highpass filter for phase shift

%% user parameters
stdthresh = 0.2; % sets the minimum threshold to be considered a spike at the end of the analysis as a proportion of the standard deviation

%% initialize variables
ncomptot = length(Config.comp);

% put all components into a multidimensional array for easy analysis
MultiData = ConvStruct2Multi(Data.Vel,Config.comp);

% create zeros matrices for the analysis
[nttot,nCtot,ncomptot]=size(MultiData);
Raw = zeros(size(MultiData));
HighDat = zeros(size(MultiData));
DespikedHighDat = zeros(size(MultiData));

%% switch to beam if despiking is done in beam
% if despiking is to be done in Beam coordinates and the transformationMatrix is available
if GUIControl.switch2beam && isfield(Config, 'transformationMatrix')
    % for each Cell
    for nC = 1:Config.nCells
        % reshape the transformation matrix
        TransMi = reshape(Config.transformationMatrix(nC,:),4,4)';
        % isolate the cell and squeeze it
        Datai = squeeze(MultiData(:,nC,:));
        % convert xyz data to beam
        Raw(:,nC,:) = ConvXYZ2Beam(Datai,TransMi,1);
    end
else
    % raw data is the untransformed MultiData matrix of velocities
    Raw = MultiData;
end

%% preprocess data
% remove long term trend (median/linear)
if GUIControl.Preprocess == 1 || GUIControl.Preprocess == 3
    for ncomp = 1:ncomptot
        medians = median(Raw(:,:,ncomp));
        for nC = 1:nCtot
            HighDat(:,nC,ncomp) = Raw(:,nC,ncomp)-medians(nC);
        end
    end
elseif GUIControl.Preprocess == 2
    for ncomp = 1:ncomptot
        HighDat(:,:,ncomp) = detrend(Raw(:,:,ncomp));
    end
end
LowDat = Raw-HighDat;
% remove long term trend (filter)
if GUIControl.Preprocess == 3
    Detrendi = HighDat; % use median removed data to input into filter
    % highpass filter is applied
    %GUIControl.HighPassTime = 5; % coefficient
    windowSize = Config.Hz*GUIControl.HighPassTime; % filtersize window for removal of long term trends
    highpassfilt = ones(1,round(windowSize))/round(windowSize); 
    for ncomp = 1:ncomptot
        Filteredps = filter(highpassfilt,1,Detrendi(:,:,ncomp));
        % correct for phase shift as a result of filtering (windowSize/2+1)
        Filtered = zeros(size(Filteredps)); % copy Detrendi data (will remain only for the last windowSize/2 time intervals due to phase shift)
        windowval = round(windowSize/2);
        Filtered(1:end-windowval,:) = Filteredps(windowval+1:end,:);
        Filtered(end-windowval+1:end)=Filtered(end-windowval); % set remaining cells equal to last value
        LowDat(:,:,ncomp)=LowDat(:,:,ncomp)+Filtered;
    end
end
HighDat=Raw-LowDat;
% note: seasonal filter cannot be applied here because it relies on de-spiked data for a clean filter.  Therefore has to be applied
% progressively as is done in SpikeARMA.  Such a method could be set up for the other despiking methods but has not been done.

% classify mode to eliminate poor cells from de-spiking
goodCellsMode = zeros(nCtot,ncomptot);
for ncomp = 1:ncomptot
    goodCellsMode(:,ncomp) = ClassifyMode(HighDat(:,:,ncomp),GUIControl.pctmode/100);
end

%% send to despiking algorithm
% all methods other than ARMA are run with one time series at a time
if ~GUIControl.SpikeARMA
    % for each component
    for ncomp = 1:ncomptot
        % for each cell
        for nC = 1:nCtot
            % isolate data  % note that 'dat' is cycled through the subprograms so that the spike detection methods
                % can act in series if multiple options are selected
            dat = HighDat(:,nC,ncomp);
            % if data passes the initial screening (mode classification)
            if goodCellsMode(nC,ncomp)
                % if Standard Deviation spike detection algorithm is activated
                if GUIControl.SpikeStddev
                    % send to spike detection and replacement algorithm
                    dat = SpikeStddev(dat,GUIControl.StddevThreshold,GUIControl.ReplacementMethod);
                end
                % if Skewness spike detection algorithm is activated
                if GUIControl.SpikeSkewness
                    % send to spike detection and replacement algorithm
                    dat = SpikeSkewness(dat,GUIControl.SkewnessThreshold,GUIControl.ReplacementMethod);
                end
                % if Nikora Goring spike detection algorithm is activated
                if GUIControl.SpikeGoringNikora
                    % send to spike detection and replacement algorithm
                    dat = SpikeGoringNikora(dat,GUIControl.GoringNikoraThreshold,GUIControl.ReplacementMethod,GUIControl.Parsheh);
                end
            end
            % save in temp matrix
            DespikedHighDat(:,nC,ncomp) = dat;
        end
    end
else
    %% ARMA preparation
    % set ARMAopts
    ARMAopts = GUIControl.ARMAopts;
    % if nobs_long is empty
    if isempty(ARMAopts.nobs_long)
        % the whole time series is considered as a single segment
        ARMAopts.nsegtot = 1;
        ARMAopts.nobs = nttot;
    else
        % the time series is broken into multiple segments
        ARMAopts.nsegtot = ceil(nttot/ARMAopts.nobs_long);  %number of segments to calculate models 
        ARMAopts.nobs = floor(nttot/ARMAopts.nsegtot); % number of observations in each segment
    end
    % create a temporary structure array to contain information about the ARMA models
    ARMA(ARMAopts.nsegtot,nCtot,ncomptot) = struct('model',[],'modeldetails',[],'despikedetails',[]);

    % for each component
    for ncomp = 1:ncomptot
        % isolate data
        datin = HighDat(:,:,ncomp);
        % send profile of time series to SpikeARMA algorithm
        [datout,vseason,ARMAi] = SpikeARMA(datin,ARMAopts,goodCellsMode(:,ncomp)); 
        % save despiked values in temp matrix
        DespikedHighDat(:,:,ncomp) = datout;
        % add vseason to LowDat 
        LowDat(:,:,ncomp) = LowDat(:,:,ncomp)+vseason;
        for nseg = 1:ARMAopts.nsegtot
            ARMA(nseg,:,ncomp) = ARMAi(nseg,:);
        end
    end
end

% if Velocity Correlation spike detection algorithm is activated
if GUIControl.SpikeVelCorr
    if ncomptot>1
        % for each cell
        for nC = 1:nCtot
            % isolate data (all components are required
            dat = squeeze(DespikedHighDat(:,nC,:));
            % send to spike detection and replacement algorithm
            dat = SpikeVelCorr(dat,Config.Hz,GUIControl.VelCorrThreshold,GUIControl.ReplacementMethod);
            for ncomp = 1:ncomptot
                DespikedHighDat(:,nC,ncomp) = dat(:,ncomp);
            end
        end
    end
end

%% add DespikedHighDat to LowDat
Despiked = DespikedHighDat+LowDat;

%% switch back to xyz if despiking done in beam
if GUIControl.switch2beam && isfield(Config, 'transformationMatrix')
    for nC = 1:nCtot
        % switch to beam
        TransMi = reshape(Config.transformationMatrix(nC,:),4,4)';
        Datai = squeeze(Despiked(:,nC,:));
        Despiked(:,nC,:) = ConvXYZ2Beam(Datai,TransMi,2);
        Dataii =  squeeze(HighDat(:,nC,:));
        HighDat(:,nC,:) = ConvXYZ2Beam(Dataii,TransMi,2);
    end
end

%% determine spikes 
SpikeY = Raw~=Despiked;
% for ncomp = 1:ncomptot
%     for nC = 1:nCtot
%         % calculate SpikeY from from threshold criteria comparing raw to despiked series 
%         SpikeY(:,nC,ncomp) = abs(Raw(:,nC,ncomp)-Despiked(:,nC,ncomp)) > std(Despiked(:,nC,ncomp))*stdthresh;
%     end
% end

% addfields from multidimensional array to Data
Data = ConvMulti2Struct(Despiked,Data,Config.comp,'Despiked');
Data = ConvMulti2Struct(SpikeY,Data,Config.comp,'SpikeY');
Data = ConvMulti2Struct(LowDat,Data,Config.comp,'LowDat');
if GUIControl.SpikeARMA 
    Data = ConvMulti2Struct(ARMA,Data,Config.comp,'ARMA');
end

end

