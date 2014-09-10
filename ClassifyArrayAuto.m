function ClassifyArrayAuto(GUIControl)
% automatically identifies bad cells in data array
% Called by MITT
% Calls CalcGoodCells

%% directories

% for each file in MITTdir
nsFtot = length(GUIControl.MITTdir);
for nsF = 1:nsFtot
    % load Config and Data
    AllinOne = load([GUIControl.odir,filesep,GUIControl.MITTdir(nsF).name],'Config','Data');
    Config = AllinOne.Config;
    Data = AllinOne.Data;
    Anames = getAnames(Data);

    GUIControl.X.var = Anames{GUIControl.nxvar};
    GUIControl.Y.var = 'zZ';

    % get y data
    Config = CalcGoodCells(Config,Data,GUIControl);

    if GUIControl.plotQCauto
        PlotQCTable(Config)
    end

    % save faQC to Config
    Config.faQC = GUIControl.faQC;
    % append updated Config to file
    save([GUIControl.odir,filesep,GUIControl.MITTdir(nsF).name],'Config','-append');
end
        
end

