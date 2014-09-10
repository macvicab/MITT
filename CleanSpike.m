function Data = CleanSpike(Config,Data,GUIControl)
% controls detection and removal of spikes from time series
% called from AClean
% calls SpikeStdev, SpikeSkewness, SpikeGoringNikora, SpikeVelCorr
% subfunctions include ConvStruct2Multi, ConvMulti2Struct

%% user parameters
stdthresh = 0.2; % sets the minimum threshold to be considered a spike at the end of the analysis as a proportion of the standard deviation

%% initialize variables
ncomptot = length(Config.comp);

% put all components into a multidimensional array for easy analysis
MultiData = ConvStruct2Multi(Data.Vel,Config.comp);

% create zeros matrices for the analysis
Raw = zeros(size(MultiData));
temp = zeros(size(MultiData));
Despiked = zeros(size(MultiData));
SpikeY = zeros(size(MultiData));

%% switch to beam if despiking is done in beam
if GUIControl.switch2beam && isfield(Config, 'transformationMatrix')
    for nCell = 1:Config.nCells
        % switch to beam
        TransMi = reshape(Config.transformationMatrix(nCell,:),4,4)';
        Datai = squeeze(MultiData(:,nCell,:));
        Raw(:,nCell,:) = ConvXYZ2Beam(Datai,TransMi,1);
    end
else
    Raw = MultiData;
end

%% send to despiking algorithm one timeseries at a time
% for each component
for ncomp = 1:ncomptot
    % for each cell
    for nCell = 1:Config.nCells
        % isolate data
        dat = Raw(:,nCell,ncomp);
        % if Standard Deviation spike detection algorithm is activated
        if GUIControl.SpikeStddev
            % send to spike detection and replacement algorithm
            dat = SpikeStddev(dat,Config.Hz,GUIControl.StddevThreshold,GUIControl.ReplacementMethod);
        end
        % if Skewness spike detection algorithm is activated
        if GUIControl.SpikeSkewness
            % send to spike detection and replacement algorithm
            dat = SpikeSkewness(dat,GUIControl.SkewnessThreshold,GUIControl.ReplacementMethod);
        end
        % if Nikora Goring spike detection algorithm is activated
        if GUIControl.SpikeGoringNikora
            % send to spike detection and replacement algorithm
            dat = SpikeGoringNikora(dat,Config.Hz,GUIControl.GoringNikoraThreshold,GUIControl.ReplacementMethod,GUIControl.Parsheh);
        end
        % save in temp matrix
        temp(:,nCell,ncomp) = dat;
    end
end

% if Velocity Correlation spike detection algorithm is activated
if GUIControl.SpikeVelCorr
    if ncomptot>1
        % for each cell
        for nCell = 1:Config.nCells
            % isolate data (all components are required
            dat = squeeze(temp(:,nCell,:));
            % send to spike detection and replacement algorithm
            dat = SpikeVelCorr(dat,Config.Hz,GUIControl.VelCorrThreshold,GUIControl.ReplacementMethod);
            for ncomp = 1:ncomptot
                temp(:,nCell,ncomp) = dat(:,ncomp);
            end
        end
    end
end

%% switch back to xyz if despiking done in beam
if GUIControl.switch2beam && isfield(Config, 'transformationMatrix')
    for nCell = 1:Config.nCells
        % switch to beam
        TransMi = reshape(Config.transformationMatrix(nCell,:),4,4)';
        Datai = squeeze(temp(:,nCell,:));
        Despiked(:,nCell,:) = ConvXYZ2Beam(Datai,TransMi,2);
    end
else
    Despiked = temp;
end

%% determine spikes 
for ncomp = 1:ncomptot
    for nCell = 1:Config.nCells
        % calculate SpikeY from from threshold criteria comparing raw to despiked series 
        SpikeY(:,nCell,ncomp) = abs(Raw(:,nCell,ncomp)-Despiked(:,nCell,ncomp)) > std(Despiked(:,nCell,ncomp))*stdthresh;
    end
end

% addfields from multidimensional array to Data
Data = ConvMulti2Struct(Despiked,Data,Config.comp,'Despiked');
Data = ConvMulti2Struct(SpikeY,Data,Config.comp,'SpikeY');

end

