function PlotQCTable(Config)
% to create table that shows the output from the Data Quality Classification 

f = figure('Position',[200 200 500 200]);
set(f,'Name',['Classify Cell Quality Output for file:',Config.filename]);
Qrnames = 1:Config.nCells;
uitable('Parent',f,'Data',Config.Qdat,'ColumnName',Config.Qcnames,... 
        'RowName',Qrnames,'Position',[20 20 460 150]);
    
end