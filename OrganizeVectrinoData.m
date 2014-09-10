 function [Data,Config] = OrganizeVectrinoData(GUIControl,CSVControl)
% gets raw data from Vectrino output files and saves in Config, Data.  
% called from AOrganize
% subfunctions include CalcConfigVectrino GetDataVectrino

%% get Config and Data
% get filenames
inname = [GUIControl.CSVControlpathname,CSVControl.filename,'.dat'];
inhdrname = [GUIControl.CSVControlpathname,CSVControl.filename,'.hdr'];
% get Config data from subprogram
Config = CalcConfigVectrino(CSVControl,inhdrname);
Config.comp = {'u','v','w1','w2'};

% get all fields in CSVControl and put them in Config
fnames = fieldnames(CSVControl);
nftot = length(fnames);
for nf = 1:nftot
    Config.(fnames{nf}) = CSVControl.(fnames{nf});
end

% if a sampling locations algorithm was specified
if GUIControl.Sampling
    % get position data using posfunction
    eval(['Config = ',GUIControl.CalcXYZfile(1:end-2),'(Config);']);
end 

% calculate derived position data
Config.zZ = Config.zpos/Config.waterDepth;
Config.waterElevation = Config.bedElevation+Config.waterDepth; %
Config.zposGlobal = Config.bedElevation+Config.zpos;
if isfield(Config,'Y')
    Config.yY = Config.ypos/Config.Y;
end

% get Data from subprogram
Data = GetDataVectrino(inname,Config);
Config.ntimetot = length(Data.Vel.u);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Config = CalcConfigVectrino(CSVControl,inhdrname)

HdrID=fopen(inhdrname);
rawhead=textscan(HdrID, '%s');

%% get relevant parameters from Config structure
% %from control file
% Config.filename = CSVControl.filename;
% Config.instrument = CSVControl.instrument;
% Config.nArrays = CSVControl.nArrays;
% Config.nCells = CSVControl.nCells;
% Config.Comment = CSVControl.Comment;
% Config.Y = CSVControl.Y;

%from Vectrino header file
Config.date = datenum(char(rawhead{1,1}(strmatch('first',rawhead{1,1}(:,1))+2,1)));
Config.startTime = char(rawhead{1,1}(strmatch('first',rawhead{1,1}(:,1))+3,1));
Config.Hz = str2num(char(rawhead{1,1}(strmatch('rate',rawhead{1,1}(:,1))+1,1)));
Config.velRange = str2num(char(rawhead{1,1}(strmatch('range',rawhead{1,1}(:,1))+1,1)));
Config.probeType = char(rawhead{1,1}(strmatch('type',rawhead{1,1}(:,1))+1,1));
Config.transmitLength = str2num(char(rawhead{1,1}(strmatch('length',rawhead{1,1}(:,1))+1,1)));
Config.samplingVolume = str2num(char(rawhead{1,1}(strmatch('volume',rawhead{1,1}(:,1))+1,1)));
Config.powerLevel = char(rawhead{1,1}(strmatch('Powerlevel',rawhead{1,1}(:,1))+1,1));
Config.coordSystem = char(rawhead{1,1}(strmatch('Coordinate',rawhead{1,1}(:,1))+2,1));
Config.transformationMatrix = reshape(str2num(char(rawhead{1,1}(strmatch('matrix',rawhead{1,1}(:,1))+1:strmatch('matrix',rawhead{1,1}(:,1))+16,1))),4,4)';
Config.boundryDistance = str2num(char(rawhead{1,1}(strmatch('Quality',rawhead{1,1}(:,1))-2,1)));
Config.temperature = str2num(char(rawhead{1,1}(strmatch('Temperature',rawhead{1,1}(:,1))+1,1)));

fclose(HdrID);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Data = GetDataVectrino(inname,Config)
% extracts data from inname

Raw = load(inname,'\t');
   

%% get measured data
% column names
deets = {'Vel','Amp','SNR','Cor'};
% column numbers
deetsVar=[2,6,10,14];
ndtot = length(deets);
% for each component
for ncomp = 1:length(Config.comp)
    % get the first component of data from the Raw matrix
    eval(['Data.',deets{1},'.',Config.comp{ncomp},' = Raw(:,deetsVar(1)+ncomp);']);
    % for other components
    for nd=2:ndtot
        % get the data from Raw
        eval(['Data.',deets{nd},'.Beam',num2str(ncomp),' = Raw(:,deetsVar(nd)+ncomp);']);
    end
end
ntimetot = length(Data.Vel.u);
Data.timeStamp = (1:ntimetot)/Config.Hz;


end



