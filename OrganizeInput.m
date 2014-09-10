function OrganizeInput(GUIControl)
% Control file for organizing instrument output into Data and Config arrays
% Called from MITT
% Calls Organize(Instrument)Data, where Instrument comes from Control.Instrument 
% and CalcChannelMesh

%%
% get control file
CSVControl = ConvCSV2Struct([GUIControl.CSVControlpathname,GUIControl.CSVControlfilename],0);
% number of files
nftot = length(CSVControl);

% store output name and number of files
GUIControl.nftot = nftot;

if GUIControl.DefineGeometry
    % calculate mesh of sampling channel
    GUIControl = CalcChannelMesh(GUIControl,CSVControl);
end

% save file
chk = dir(GUIControl.outname);
if isempty(chk)
    save(GUIControl.outname,'GUIControl')
else
    save(GUIControl.outname,'GUIControl','-append')
end

% for each file
for nf = 1:nftot

    % load data by sending Control structure to the instrument-appropriate Organize**Data file
    eval(['[Dataa,Configa] = Organize',CSVControl(nf).instrument,'Data(GUIControl,CSVControl(nf));']);

    % for each array
    if isfield(Configa,'nArrays')
        natot = Configa.nArrays;
    else
        natot = 1;
    end

    for na = 1:natot
        % create Config and Data arrays
        Config = Configa(na);
        Config.CSVControlpathname = GUIControl.CSVControlpathname;
        % filename
        Config.filename = [CSVControl(nf).filename,'na',num2str(na)];

        % save Config and Data to the output file
        oname = [GUIControl.odir,filesep,Config.filename,'.mat'];
        % chk for any output files
        chk = dir(oname);
        % if this file has not been created
        if isempty(chk)
            % get data from Dataa matrix (raw data only)
            Data = Dataa(na);
            % add empty variables faQC and goodCells to Config in
            % preparation for data quality control
            Config.faQC = struct;
            goodCells = ones(Config.nCells,1);
            % add a goodCells vector for each component
            ncomptot = length(Config.comp);            
            for nc = 1:ncomptot
                eval(['Config.goodCells.',Config.comp{nc},' = goodCells;']);
            end
            % add variable nums to keep track of what analyses have been completed
            Config.Despiked = 0; %
            Config.Filtered = 0; %

            save(oname,'Config','Data');
        % else if this file exists, then just worry about Config and
        % transfer information about quality analyses
        else
            Ctemp = load(oname,'Config');
            Config.faQC = Ctemp.Config.faQC';
            Config.goodCells = Ctemp.Config.goodCells;
            Config.Despiked = Ctemp.Config.Despiked;
            Config.Filtered = Ctemp.Config.Filtered;
            
            save(oname,'Config','-append');
        end
        

    end        
end

end