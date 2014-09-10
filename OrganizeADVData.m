function [Data,Config] = OrganizeADVData(GUIControl,CSVControl)
% gets raw data from ADV output files and saves in Config, Data.  
% called from AOrganize
% subfunctions include CalcConfigADV, GetDataADV

%% get Config and Data
% get filename
inname = [GUIControl.CSVControlpathname,CSVControl.filename,'.Vu'];
% save component names in Config
Config.comp = {'u','v','w'};
% get all fields in CSVControl and put them in Config
fnames = fieldnames(CSVControl);
nftot = length(fnames);
for nf = 1:nftot
    Config.(fnames{nf}) = CSVControl.(fnames{nf});
end

%% get position data
% if a posfunction was given in the control file
if GUIControl.Sampling
    % get position data using CalcXYZfile
    eval(['Config = ',GUIControl.CalcXYZfile(1:end-2),'(GUIControl,CSVControl);']);
end 
Config.transformationMatrix = str2num(CSVControl.transMatrix);

% calculate derived position data
Config.zZ = Config.zpos/Config.waterDepth;
Config.waterElevation = Config.bedElevation+Config.waterDepth; %
Config.zposGlobal = Config.bedElevation+Config.zpos;

if isfield(Config,'Y')
    Config.yY = Config.ypos/Config.Y;
end

% sampling volume information
Config.cellRadius = 0.006/2; % in m, from Sontek/YSI 2001 reference
Config.cellWidth = 0.009;
Config.samplingVolume = pi()*Config.cellRadius^2*Config.cellWidth;% height of measurement cylinder from Sontek reference

% get Data from subprogram
[Data,temperature] = GetDataADV(inname,Config);

% save additional parameters to Config
Config.Hz = 1/(Data.timeStamp(2,1)-Data.timeStamp(1,1));
Config.temperature = temperature;
Config.ntimetot = length(Data.timeStamp);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Data,temperature] = GetDataADV(inname,Config)
% extracts data from inname
RawAll = importdata(inname,';');
Raw = RawAll.data; 
% column names
deets = {'Vel','Cor','SNR','Amp'};
% column numbers
deetsVar=[3,6,9,12];
ndtot = length(deets);
% for each component
for ncomp = 1:length(Config.comp)
    % get the first component of data from the Raw matrix
    eval(['Data.',deets{1},'.',Config.comp{ncomp},' = Raw(:,deetsVar(1)+ncomp)/100;']);
    % for other components
    for nd=2:ndtot
        % get the data from Raw
        eval(['Data.',deets{nd},'.Beam',num2str(ncomp),' = Raw(:,deetsVar(nd)+ncomp);']);
    end
end
% save timeStamp and temperature
Data.timeStamp = Raw(:,1);
temperature = Raw(1,20);

end
