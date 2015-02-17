function [Data,Config]=OrganizeUDVPData(GUIControl,CSVControl)
% gets raw data from UDVP output files and saves in Config, Data.  
% called from OrganizeInput
% subfunctions include ConvCSV2Struct, CalcConfigECM

%% get raw data
% get data filename
inname = [GUIControl.CSVControlpathname,CSVControl.filename,'.mfprof'];
% get raw data from subprogram 
[timeStamp,DopplerData,AmplData,Configi] = UVPReaderv3p0(inname);

%% add variables to Config
% transfer parameters from control file
Configi.comp = {'Beam1'};

% get all fields in CSVControl and put them in Config
fnames = fieldnames(CSVControl);
nftot = length(fnames);
for nf = 1:nftot
    Configi.(fnames{nf}) = CSVControl.(fnames{nf});
end

if isfield(Configi,'Q')
    Configi.Qmeasured = Configi.Q; %measured discharge
end

% calculate additional config parameters
Configi.cellDist = Configi.cellStart+ Configi.cellInterval*(0:Configi.nCells-1);
Configi.Vrange=Configi.speedOfSound^2/4/Configi.Frequency/Configi.MaximumDepth; % section 3.1.9
Configi.DeltaV = Configi.Vrange/Configi.RawDataRange;
Configi.ntimetot = Configi.recordLength/Configi.nArrays;

% create a 1 x na structure array with all the Configi parameters 
for na = 1:Configi.nArrays
    Config(na) = Configi;
end

%% Calculate velocity from Doppler data
Data = CalcUDVPData(Configi,timeStamp,DopplerData,AmplData);


%% get position data
% if a posfunction was given in the control file
if GUIControl.Sampling
    % get position data using posfunction
    eval(['Config = ',GUIControl.CalcXYZfile(1:end-2),'(GUIControl,CSVControl,Config,Data);']);
else
    % else if this was left blank
    disp('Position function is required to calculate xpos,ypos and zpos for UDVP datasets')
end


end

%%%%%
function Data = CalcUDVPData(Config,timeStamp,DopplerData,AmplData)
% calculates velocity data from raw Doppler data

%% calculate velocity from raw data
% convert Doppler data to velocity
Vel=DopplerData/Config.RawDataRange*Config.Vrange;
% check for Velocity Interpreting Mode (parameter stored in *.mprof that
% determines velocity range of data.  == 0 if velocity range straddles v = 0)
% if VIM = 1 then velocity range is from 0 to vrange.
if Config.VelocityInterpretingMode == 1 
    % find negative velocities
    vneg = Vel<0;
    % add Vrange to the negative velocities
    Vel(vneg) = Vel(vneg)+Config.Vrange;
% if VIM = -1 then velocity range is from -vrange to 0
elseif Config.VelocityInterpretingMode == -1
    % find positive velocities
    vpos = Vel>0;
    % subtract Vrange from the positive velocities
    Vel(vpos) = Vel(vpos)-Config.Vrange;
end

%% save data from different probes into separate arrays (data is stored together in *.mprof)
Data = struct('timeStamp',{},'Vel',{},'Amp',{});
% calculate record length for one array
recordLengthi = Config.recordLength/Config.nArrays;
% calculate beginning and end indices
idxb = 1+[0:Config.nArrays-1]*recordLengthi;
idxe = [1:Config.nArrays]*recordLengthi;
% for each Array
for na = 1:Config.nArrays
    % get timeStamp, velocity, and amplitude data
    Data(na).timeStamp = timeStamp(idxb(na):idxe(na));
    Data(na).Vel.Beam1 = Vel(idxb(na):idxe(na),:);
    Data(na).Amp.Beam1 = AmplData(idxb(na):idxe(na),:);
end

end
%%%%%
function [timeStamp,DopplerData,AmplData,Config] = UVPReaderv3p0(filename)
% v2 - removed VelocityInterpretingMode block because it wasn't being used,
% some other tidying was done
% v2p2 - output Vrange so that wrapping can be calculated
% v2p3 - output VIM data
% v2p4 - return Amp data
% v3p0 - use Data Config data architecture, return all variables

%% Input Data
%Where input variables are
%Filename – full filename and path to UVP output file (eg C:\testdir\testfile.mfprof). Must be input as a string (enclosed in single quotes)
%Theta is the UVP probe angle (degrees from horizontal)
%s_speed is the speed of sound in m/s

%Output variables
%nCells = number of channels (integer value)
%snum = number of time-series points per channel (integer)
%DopplerVel = nCells-by-snum array including all of the resolved velocity values – velocities reported are the streamwise component (Vmeas/sin(theta)) – mm/s
%z = vertical location of each channel (Xact*cos(theta)) – mm
%t = time in seconds
%AmplData = nCells-by-snum array including the return signal amplitude data – may be used to determine bottom location (increased reflection = increased amplitude), or in certain applications the suspended sediment concentration.

%% Header info
% variable names match with Appendix 14 in "UVP-DUO User's Guide R5"
fid=fopen(filename);
Config.signum = fread(fid,64,'char');
Config.measParamsOffset = fread(fid,1,'int64');
Config.recordLength = fread(fid,1,'int32');
reserved1 = fread(fid,1,'int32');
Config.flags = fread(fid,1,'int32');
Config.recordSize = fread(fid,1,'int32');
Config.nCells = fread(fid,1,'int32');
reserved2 = fread(fid,1,'int32');
startTime = fread(fid,1,'int64');
Config.startTime = startTime*100/(24*3600*1e9); %convert from 100s of nanoseconds to datenum format in Matlab

%% Get Data
% Zero matrices
timeStamp = zeros(Config.recordLength,1);
DopplerData = zeros(Config.recordLength,Config.nCells);

%% Read in data
if Config.flags
    AmplData = zeros(Config.recordLength,Config.nCells);
    for j=1:Config.recordLength
        A = fread(fid,1,'int32');
        A = fread(fid,1,'int32');
        timeStamp(j) = fread(fid,1,'int64')/1e7;% convert to seconds
        DopplerData(j,:)=fread(fid,Config.nCells,'int16');
        AmplData(j,:)=fread(fid,Config.nCells,'int16');
    end
else
    for j=1:Config.recordLength
        A = fread(fid,1,'int32');
        A = fread(fid,1,'int32');
        timeStamp(j) = fread(fid,1,'int64')/1e7; % convert to seconds
        DopplerData(j,:)=fread(fid,Config.nCells,'int16');
    end
end

%% Get Config data
tline = fgetl(fid);
Config.Frequency=fscanf(fid,'Frequency=%d \n');
Config.cellStart=fscanf(fid,'StartChannel=%f \n')/1000;
Config.cellInterval=fscanf(fid,'ChannelDistance=%f \n')/1000;
Config.cellWidth=fscanf(fid,'Width=%f \n')/1000;
Config.MaximumDepth=fscanf(fid,'MaximumDepth=%f \n')/1000;
Config.speedOfSound=fscanf(fid,'SoundSpeed=%i \n');
Config.Angle=fscanf(fid,'Angle=%d \n');
Config.GainStart = fscanf(fid,'GainStart=%d \n');
Config.GainEnd = fscanf(fid,'End=%d \n');
Config.Voltage = fscanf(fid,'Voltage=%d \n');
Config.Iterations = fscanf(fid,'Iterations=%d \n');
Config.NoiseLevel = fscanf(fid,'NoiseLevel=%d \n');
Config.CyclesPerPulse = fscanf(fid,'CyclesPerPulse=%d \n');
Config.TriggerMode = fscanf(fid,'TriggerMode=%d \n');
Config.TriggerModeName = fscanf(fid,'Name=%s \n');
Config.ArrayLength = fscanf(fid,'ProfileLength=%d \n');
Config.ArraysPerBlock = fscanf(fid,'sPerBlock=%d \n');
Config.nArrays = fscanf(fid,'Blocks=%d \n');
Config.AmplitudeStored = fscanf(fid,'AmplitudeStored=%d \n');
Config.DoNotStoreDoppler = fscanf(fid,'DoNotStoreDoppler=%d \n');
Config.RawDataMin = fscanf(fid,'RawDataMin=%d \n');
Config.RawDataMax = fscanf(fid,'ax=%d \n');
Config.RawDataRange = fscanf(fid,'RawDataRange=%i \n');
Config.AmplDataMin = fscanf(fid,'AmplDataMin=%i \n');
Config.AmplDataMax = fscanf(fid,'ax=%i \n');
Config.VelocityInterpretingMode=fscanf(fid,'VelocityInterpretingMode=%i \n'); % Velocity Interpreting mode (0 is normal, 1 is from zero to +Vrange, -1 is from -Vrange to 0)
Config.UserSampleTime=fscanf(fid,'UserSampleTime=%i \n');
Config.SampleTime=fscanf(fid,'SampleTime=%i \n')/1000; %deltt
Config.Hz = 1/Config.SampleTime;
Config.UseMultiplexer=fscanf(fid,'UseMultiplexer=%i \n'); 
Config.FlowMapping=fscanf(fid,'FlowMapping=%i \n'); 
Config.FirstValidChannel=fscanf(fid,'irstValidChannel=%i \n'); 
Config.LastValidChannel=fscanf(fid,'LastValidChannel=%i \n'); 
Config.FlowRateType=fscanf(fid,'FlowRateType=%i \n'); 
 tline = fgetl(fid);%Config.PeriodEnhOffset=fscanf(fid,'PeriodEnhOffset=%i \n'); 
 tline = fgetl(fid);%Config.PeriodEnhPeriod=fscanf(fid,'=%i \n'); 
 tline = fgetl(fid);%Config.PeriodEnhNCycles=fscanf(fid,'PeriodEnhNCycles=%i \n'); 
 tline = fgetl(fid);%Config.Comment=fscanf(fid,'Comment=%i \n'); 
 tline = fgetl(fid);%Config.MeasurementProtocol=fscanf(fid,'MeasurementProtocol=%i \n'); 
% if multiplexer used then a table will exist at the bottom with additional parameters
if Config.UseMultiplexer
    tline = fgetl(fid);
    Config.NumberOfCycles=fscanf(fid,'NumberOfCycles=%i \n');
    Config.CycleDelay=fscanf(fid,'CycleDelay=%i \n');
    Config.Version=fscanf(fid,'Version=%i \n');
    Config.nArraysconnected=fscanf(fid,'Table=%i \n');
else
    Config.nArrays = 1;
end

fclose(fid);


end


