function [Data,Config] = OrganizeECMData(GUIControl,CSVControl)
% gets raw data from ECM output files and saves in Config, Data.  
% called from AOrganize
% subfunctions include ConvCSV2Struct, CalcConfigECM

%% get Raw data
% get filename
inname = [GUIControl.CSVControlpathname,CSVControl.filename,'.dat'];

% read velocity data data from CSV file
Raw = ConvCSV2Struct(inname,1);
% get fieldnames of Raw structure
fimem = fieldnames(Raw);
nfitot = length(fimem)-1;
eval(['nttot = length(Raw.',fimem{1},');']);

% get all fields in CSVControl and put them in Config
fnames = fieldnames(CSVControl);
nftot = length(fnames);
for nf = 1:nftot
    Config.(fnames{nf}) = CSVControl.(fnames{nf});
end
% additional Config parameters
Config.startTime = datenum([CSVControl.date,CSVControl.startTime],'ddmmyyyyHH:MM:SS');
Config.Hz = 1/CSVControl.Frequency;

%% determine orientation
% determine components of ECM data from control parameter
if Config.Orientation == 1
    Config.comp = {'u','w'};
elseif CSVControl.Orientation == 2
    Config.comp = {'u','v'};
else
    Config.comp = {'v','w'};
end
nctot = length(Config.comp);

%% get position data
% if a posfunction was given in the control file
if GUIControl.Sampling
    % get position data using posfunction
    eval(['Config = ',GUIControl.CalcXYZfile(1:end-2),'(GUIControl,Config);']);
end


% calculate derived position data
Config.zZ = Config.zpos/Config.waterDepth;
Config.waterElevation = Config.bedElevation+Config.waterDepth; %
Config.zposGlobal = Config.bedElevation+Config.zpos;
Config.yY = Config.ypos/Config.Y;

% calculate orientations based on a comparison of comp and the fieldnames
% in Raw
orient = zeros(nfitot,nctot);
for nfi = 1:nfitot
    orient(nfi,:) = strcmp(char(fimem{nfi+1}(1)),Config.comp);
end
% determine how many files have that orientation
notot = sum(orient);

%% save velocity data in Data
% for each component
for nc = 1:nctot
    % if the orientation has been identified
    if notot(nc)>0
        % create zero matrix for one componenet
        eval(['Data.Vel.',Config.comp{nc},' = zeros(nttot,notot(',num2str(nc),'));'])
        omem = find(orient(:,nc));
        for nu = 1:notot(nc)
             eval(['Data.Vel.',Config.comp{nc},'(:,nu) = [Raw.',fimem{omem(nu)+1},']*CSVControl.',Config.comp{nc},'multiplier;'])
        end
    end
end

Data.timeStamp = [0:nttot-1]/Config.Hz;
% save velocity component timelength in Config
eval(['Config.ntimetot = length(Data.Vel.',Config.comp{1},');']);
Config.cellRadius = 2.5*0.013; % radius is 2.5 times the diameter of the probe
Config.samplingVolume = 4/3*pi()*Config.cellRadius^3;
end







