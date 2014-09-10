function PlotTimeSeries(Config,Data,nCellmem)
% controls automatic time series plot
% called from AClean
% calls Plot1Series
% subfunctions include ConvStruct2Multi, ConvMulti2Struct, TransMAT

% determine number of analyses
Anames = {'Despiked','Filtered'};
nAtot = length(Anames);

% determine number of components 
ncomptot = length(Config.comp);

% create a multidimensional array in 4D with rows, columns, sheets and volumes 
% as time intervals, cells, components, and analyses
Pdata = zeros(Config.ntimetot,Config.nCells,ncomptot,nAtot+1);

% get raw data and save in Pdata
Pdata(:,:,:,1) = ConvStruct2Multi(Data.Vel,Config.comp);

leg{1} = 'Raw';
nidx = 2;

%% get other analyses and save in Pdata
% for each analysis
for nA = 1:nAtot
    % check if analysis was completed
    eval(['chk = Config.',Anames{nA},';']);
    if chk
        % convert structure to multidimensional array format
        eval(['Pdata(:,:,:,nidx) = ConvStruct2Multi(Data.',Anames{nA},',Config.comp);']);
        % add name to legend
        leg{nidx} = Anames{nA};
        
        nidx = nidx+1;
    else
        Pdata(:,:,:,nidx) = [];
    end
end

%% get correlation data
% determine if correlation data is available
CORy = isfield(Data,'Cor');
if CORy
    for nc = 1:ncomptot
        % create a string with field names
        eval(['compstr(nc) = {''Beam',num2str(nc),'''};']);
    end
    COR = ConvStruct2Multi(Data.Cor,compstr);
else
    COR = [];
end

%% send data to plotting algorithm Plot1Series
% reshape Pdata for plotting
if length(size(Pdata))==4
    Pdata = permute(Pdata,[1 4 3 2]); 
end

% if a list of values were sent in nCellmem, then only those cellnumbers
% will be plotted, otherwise all cells will be plotted
if isempty(nCellmem);
    nCellmem = 1:Config.nCells;
end

% for each cell
for nCell = nCellmem;
    % isolate the correct correlation data
    if ~isempty(COR)
        CORi = squeeze(COR(:,nCell,:));
    else
        CORi = COR;
    end
    % set title for figure
    titover = [Config.CSVControlpathname,' ',Config.filename,' nCell = ',num2str(nCell)];
    % send to Plot1Series
    Plot1Series(Pdata(:,:,:,nCell),CORi,titover,Config.Hz,Config.comp,leg)
    % 
    pause(2);
end

end
