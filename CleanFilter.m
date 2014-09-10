function Data = CleanFilter(Config,Data,GUIControl)
% controls frequency filtering of time series
% called from AClean
% subfunctions include ConvStruct2Multi, ConvMulti2Struct, butt3filt

%% initialize variables
ncomptot = length(Config.comp);

% put all components into a multidimensional array for easy analysis
if Config.Despiked == 1
    InData = Data.Despiked;
else
    InData = Data.Vel;
end

MultiData = ConvStruct2Multi(InData,Config.comp);
% create zeros matrices for the analysis
Filtered = zeros(size(MultiData));

%% send to filtering algorithm one timeseries at a time
for nc = 1:ncomptot
    for nCell = 1:Config.nCells
        dat = MultiData(:,nCell,nc);
        % 3rd order Butterworth filter
        if GUIControl.ReplacementMethod == 1
            Filtered(:,nCell,nc) = butt3filt(dat,Config.Hz);
        end
    end
end

% addfields from multidimensional array to Data
Data = ConvMulti2Struct(Filtered,Data,Config.comp,'Filtered');

end

function butt = butt3filt(dat,Hz)
% third order butterworth filter 
% procedure as outlined in Roy et al (1997) "Implications of low-pass filtering 
% on power spectra and autocorrelation functions of turbulent velocity signals." 
% Mathematical Geology, 29(5), 653-668. 

fN = Hz/2; % Nyquist frequency
f50 = Hz/2.93; %DIGITAL FILTER FOR n=3, FROM ROY ET AL (1997) TABLE 1 fD = 2pif50
ord = 3;

mu = f50/fN; % for input into matlab (must be between 0 and 1 where 1 is the Nyquist)
[buttb,butta] = butter(ord,mu); %DIGITAL FILTER FOR n=3, FROM ROY ET AL (1997) TABLE 1 fD = 2pif50

butt = filter(buttb,butta,dat);

% correct phase shift and replace ends with raw data
butt(1:end-1) = butt(2:end);
butt(1:3)=dat(1:3);
butt(end-1:end) = dat(end-1:end);

end