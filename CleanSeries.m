function CleanSeries(GUIControl)
% Control file for cleaning time series
% Called from MITT
% Calls CleanSpike, CleanFilter, and AutoPlotTimeSeries

% get list of all files in MITT directory
ncleantot = length(GUIControl.MITTdir);

for nclean = 1:ncleantot
    inname = [GUIControl.odir,filesep,GUIControl.MITTdir(nclean).name];

    load(inname,'Config','Data');
    
    % despike
    if GUIControl.Despike
        if ~Config.Despiked || GUIControl.SpikeReset
            Data = CleanSpike(Config,Data,GUIControl);
            Config.Despiked = 1;
        end
    end
    % filter using butterworth
    if GUIControl.FiltrBW
        if ~Config.Filtered || GUIControl.SpikeReset
            Data = CleanFilter(Config,Data,GUIControl);
            Config.Filtered = 1;
        end
    end
    % display
    if GUIControl.plotTimeSeries
        PlotTimeSeries(Config,Data,[])
    end
    
    % save data
    save(inname,'Config','Data');
end

end