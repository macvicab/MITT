function [Data,Config] = OrganizeVectrinoIIData(GUIControl,CSVControl)
% gets raw data from VectrinoII output files and saves in Config, Data.  
% called from AOrganize
% subfunctions include CalcConfigVectrinoII GetDataVectrinoII

%% get Config and Data
% get filenames
inname = [GUIControl.CSVControlpathname,CSVControl.filename,'.mat'];
% get Config data from subprogram
Config = CalcConfigVectrinoII(CSVControl,inname);
% save component names in Config
Config.comp = {'u','v','w1','w2'};
% get all fields in CSVControl and put them in Config
fnames = fieldnames(CSVControl);
nftot = length(fnames);
for nf = 1:nftot
    Config.(fnames{nf}) = CSVControl.(fnames{nf});
end

% if a sampling locations algorithm was specified
if GUIControl.Sampling
    % get position data using CalcXYZfile
    eval(['Config = ',GUIControl.CalcXYZfile(1:end-2),'(Config);']);
end

% calculate derived position data
Config.zZ = Config.zpos/Config.waterDepth;
Config.waterElevation = Config.bedElevation+Config.waterDepth; %
Config.zposGlobal = Config.bedElevation+Config.zpos;

if isfield(Config,'Y')
    Config.yY = Config.ypos/Config.Y;
end
% calculate sampling volume (estimated - difficult to actually calculate
% according to Nortek
% assume a cylindrical volume the same diameter as ADV
Config.cellRadius = 0.006/2; % in m, from Sontek/YSI 2001 reference
Config.samplingVolume = pi()*Config.cellRadius^2*Config.cellWidth;

%% get Data from subprogram
Data = GetDataVectrinoII(Config,inname);
% save additional parameters to Config
Config.ntimetot = length(Data.timeStamp);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Config = CalcConfigVectrinoII(CSVControl,inname)

Raw = load(inname,'Config');

%% get relevant parameters from Config structure
datenull = 7;% number of columns to ignore for date value in Config (4 for UW Vectrino II, 7 for Australia)
Config.startTime = datenum(Raw.Config.date(1:end-datenull)); %  
Config.coordSystem = Raw.Config.coordSystem;
Config.syncType = Raw.Config.syncType;
Config.Hz = Raw.Config.sampleRate;
Config.cellWidth = Raw.Config.cellSize/10000;
Config.cellInterval = Config.cellWidth; %same as cellWidth
Config.nCells = Raw.Config.nCells;
% calculate distance to center of 1st cell (add cellWidth/2)
Config.cellStart = Raw.Config.cellStart/10000+Config.cellWidth/2;
Config.velocityRange = Raw.Config.velocityRange/1000;
Config.horizontalVelocityRange = Raw.Config.horizontalVelocityRange/1000;
Config.verticalVelocityRange = Raw.Config.verticalVelocityRange/1000;
Config.bottom_supported = Raw.Config.bottom_supported ;
Config.bottom_enable = Raw.Config.bottom_enable ;
Config.bottom_Hz = Raw.Config.bottom_sampleRate;
Config.bottom_minRange = Raw.Config.bottom_minRange/1000;
Config.bottom_maxRange = Raw.Config.bottom_maxRange/1000;
Config.bottom_nCells = Raw.Config.bottom_nCells;
Config.bottom_cellSize = Raw.Config.bottom_cellSize/10000;
Config.MainBoard_acSerialNo = Raw.Config.MainBoard_acSerialNo;
Config.MainBoard_Hz = Raw.Config.MainBoard_hFrequency*1000;
Config.MainBoard_hPICversion = Raw.Config.MainBoard_hPICversion;
Config.MainBoard_hHWrevision = Raw.Config.MainBoard_hHWrevision;
Config.MainBoard_hRecSize = Raw.Config.MainBoard_hRecSize;
Config.MainBoard_cFWversion = Raw.Config.MainBoard_cFWversion;
%Config.MainBoard_cFWRepoVersion = Raw.Config.MainBoard_cFWRepoVersion;
Config.MainBoard_cFWdate = Raw.Config.MainBoard_cFWdate;
Config.Probe_acSerialNo = Raw.Config.Probe_acSerialNo;
%Config.transformationMatrix = Raw.Config.ProbeCalibration_calibrationMatrix;
Config.originalfileName = Raw.Config.fileName;
Config.startCollectionTime_seconds = Raw.Config.startCollectionTime_seconds;
Config.startCollectionTime_subseconds = Raw.Config.startCollectionTime_subseconds;
Config.endCollectionTime_seconds = Raw.Config.endCollectionTime_seconds;
Config.endCollectionTime_subseconds = Raw.Config.endCollectionTime_subseconds;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Data = GetDataVectrinoII(Config,inname)
% updated 14/09/12 to fix errors in beam calculations

Raw = load(inname,'Data');
   
%% get measured data
if Config.coordSystem == 1
    Data.Vel.u = Raw.Data.Profiles_VelX;
    Data.Vel.v = Raw.Data.Profiles_VelY;
    Data.Vel.w1 = Raw.Data.Profiles_VelZ1;
    Data.Vel.w2 = Raw.Data.Profiles_VelZ2;
% if saved in Beam, transform into components u v w1 w2
elseif Config.coordSystem == 2
    ntimetot = length(Raw.Data.Profiles_TimeStamp); % added 14/09/12
    nCells=length(Raw.Data.Profiles_Range); % added 14/09/12 
    Beam = zeros(ntimetot,Config.nCells,4);
    Ortho = zeros(ntimetot,4,Config.nCells);
    for ncomp = 1:4
        eval(['Beam(:,:,ncomp) = Raw.Data.Profiles_VelBeam',num2str(ncomp),';']);  % edited 14/09/12 
    end
    Beam = permute(Beam,[1 3 2]);
    for nC = 1:nCells
        % switch to beam
        TransMi = reshape(Config.transformationMatrix(nC,:),4,4)';
        Ortho(:,:,nC) = ConvXYZ2Beam(Beam(:,:,nC),TransMi,1); % edited 14/09/12 to send to correct subprogram
    end
    Ortho = permute(Ortho,[1 3 2]);
    % save components in 
    Data.Vel.u = Ortho(:,:,1);
    Data.Vel.v = Ortho(:,:,2);
    Data.Vel.w1 = Ortho(:,:,3);
    Data.Vel.w2 = Ortho(:,:,4);

end

% get additional detail from files
deets = {'Cor','Amp','SNR','DataQuality'};
ndtot = length(deets);

for ncomp = 1:length(Config.comp)
    for nd=1:ndtot
        eval(['Data.',deets{nd},'.Beam',num2str(ncomp),' = Raw.Data.Profiles_',deets{nd},'Beam',num2str(ncomp),';']);
    end
end

Data.timeStamp = Raw.Data.Profiles_TimeStamp;

end




