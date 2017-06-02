function [Data,Config] = OrganizeADVData(GUIControl,CSVControl)
% gets raw data from ADV output files and saves in Config, Data.  
% called from AOrganize
% subfunctions include CalcConfigADV, GetDataADV

% note that WINADV must be used to preprocess the data to create a *.Vu
% format file.  MITT will not work with the binary ADV file

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
    eval(['Configa = ',GUIControl.CalcXYZfile(1:end-2),'(GUIControl,CSVControl);']);
    % add fields to Config
    fanames = fieldnames(Configa);
    nfatot = length(fanames);
    for nfa = 1:nfatot
        Config.(fanames{nfa}) = Configa.(fanames{nfa});
    end

end 
Config.transformationMatrix = str2num(CSVControl.transMatrix);

% calculate derived position data
Config.zZ = Config.zpos./Config.waterDepth;
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
% updated January 2017 by BM to allow for simultaneous ADV measurements
% extracts data from inname
RawAll = importdata(inname,';');
Raw = RawAll.data; 
[nttot,nctot] = size(Raw);
% column names
deetsin = {'V','COR','SNR','AMP'}; % headers in Vu file
deetsout = {'Vel','Cor','SNR','Amp'}; % structure file names
compin = {'x','y','z'}; % component names used for velocity V in Vu file
% column numbers
%deetsVar=[3,6,9,12]; can't use this for multiple columns
% find all desired outputs
ndtot = length(deetsout);
% for each output
for nd=1:ndtot
    % if nd == 1 - velocity component
    if nd == 1
        % for each component
        for ncomp = 1:length(Config.comp)
            % find columns with the appropriate header
            headi = [deetsin{nd},compin{ncomp}];
            a = strfind(RawAll.colheaders,headi);
            b = find(~cellfun(@isempty,a));
            dat = Raw(:,b)/100; % convert to m/s
            eval(['Data.',deetsout{nd},'.',Config.comp{ncomp},'= dat;']);
        end
        
    % other components use numbering system
    else
        for ncomp = 1:length(Config.comp)
            % find columns with the appropriate header
            headi = [deetsin{nd},num2str(ncomp-1)];
            a = strfind(RawAll.colheaders,headi);
            b = find(~cellfun(@isempty,a));
            dat = Raw(:,b);
            eval(['Data.',deetsout{nd},'.Beam',num2str(ncomp),' = dat;']);
            
        end
    end
end
% save timeStamp and temperature
Data.timeStamp = Raw(:,1);
temperature = [];%Raw(1,20); % not all instruments measure temperature, should change to an if

end
