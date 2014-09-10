function ClassifyArrayGUI(GUIControl,selmem)
% plots array statistics and interactively identifies bad cells from data array
% Called from MITT
% Calls CalcGoodCells, CalcArrayStats
% input is based on a control.csv file - each file should have passed
% through the MITT toolbox and have a Dataa and Configa file for each array


%% Create figure
% create basic figure
[plt,axe] = qcFigure;

% create uicontrol buttons in figure
B = qcButtons(plt,axe);

% initialize buttons
set(B.selfile,'String',{GUIControl.MITTdir.name});
set(B.Select,'Visible','on');
set(B.replace,'Enable','off');
set(B.Actions,'Visible','off');
set(B.Filter,'Visible','off');
set(B.Y.panel,'Visible','off');
for nx = 1:plt.nxtot
    set(B.X(nx).panel,'Visible','off');
end

% if files have been preselected (for example for duplicates)
if ~isempty(selmem)
    set(B.selfile,'Value',selmem);
end

%% set callback functions for the different uicontrol buttons
% Select arrays panel
set(B.selfiledone,'Callback',@hselfileCallback);
set(B.replace,'Callback',@hreplaceCallback);
% Actions panel
set(B.actfile,'Callback',@hactfileCallback);
set(B.plotpositions,'Callback',@hplotpositionsCallback);
set(B.plotone,'Callback',@hplotoneCallback);

set(B.plotarrayimage,'Callback',@hplotarrayimageCallback);
set(B.plotaicomp,'Callback',@hplotaicompCallback);
set(B.plotaianalysis,'Callback',@hplotaianalysisCallback);

set(B.filtarray,'Callback',@hfiltarrayCallback);
set(B.filtanalysis,'Callback',@hfiltanalysisCallback);
%
% Classify Options panel
set(B.reClassify,'Callback',@hreClassifyCallback);
set(B.manualGoodCells,'Callback',@hmanualGoodCellsCallback);
set(B.saveQC,'Callback',@hsaveQCCallback);

% y axis callbacks
set(B.Y.var,'Callback',@hyvarCallback);
set(B.Y.min,'Callback',@hyminCallback);
set(B.Y.max,'Callback',@hyminCallback);

% x axis callbacks
for nx = 1:plt.nxtot
    set(B.X(nx).var,'Callback',{@hxvarCallback,nx});
    set(B.X(nx).analysis,'Callback',{@hxanalysisCallback,nx});
    set(B.X(nx).min,'Callback',{@hxminCallback,nx});
    set(B.X(nx).max,'Callback',{@hxminCallback,nx});
    set(B.X(nx).clear,'Callback',{@hxclearCallback,nx});
end

%% Callback functions

%%%%%%%%%%
% Select arrays panel
    %%%%%
    function hselfileCallback(hObject, eventData, handles)
    % to select files to display in selection list 
    % acts when 'Done' button is pushed on 'Select Arrays' panel
        yvarname = {'zZ'};

        % get values
        nsFmem = get(B.selfile,'Value');
        % calc number of files selected
        nsFtot = length(nsFmem);
        colline = getColline(nsFtot);

        % create zero matrices
        Configa = cell(1,nsFtot);
        Dataa = cell(1,nsFtot);
        % load Dataa 
        for nsF = 1:nsFtot
            AllinOne = load([GUIControl.odir,'\',GUIControl.MITTdir(nsFmem(nsF)).name],'Config','Data');
            Configa{nsF} = AllinOne.Config;
            Dataa{nsF} = AllinOne.Data;
        end
        % get all field names (including from subFields)
        Configanames = fieldnames(Configa{1});
        Dataanames = ['dummy';subFieldnames(Dataa{1})]; % subroutine to get all field names from array with sub array
        % set fieldnames
        set(B.Y.var,'String',Configanames);
        % find default value and set
        nyvar = find(strcmp(yvarname,Configanames)); % zZ is hardcoded in
        set(B.Y.var,'Value',nyvar);
        for nx = 1:plt.nxtot
            set(B.X(nx).var,'String',Dataanames);
        end
        set(B.actfile,'String',{GUIControl.MITTdir(nsFmem).name});
        % attach data to figure
        setappdata(plt.id,'Configa',Configa)
        setappdata(plt.id,'Dataa',Dataa)
        setappdata(plt.id,'Configanames',Configanames)
        setappdata(plt.id,'Dataanames',Dataanames)

        % turn on necessary panels
        set(B.Y.panel,'Visible','on');
        set(B.Y.var,'Enable','on');
        set(B.selfiledone,'Enable','off');
    end
%%%%%
    function hreplaceCallback(hObject, eventData, handles)
    % to allow the arrays to be replaced on the axes without having to re-enter
    % everything
    % acts when 'Replace' button is pushed on the 'Select Arrays' panel

        % get values
        nsFmem = get(B.selfile,'Value');
        nyvar = get(B.Y.var,'Value');
        % calc number of files selected
        nsFtot = length(nsFmem);
        colline = getColline(nsFtot);
        % get data from figure
        xdata = getappdata(plt.id,'xdata');
        % create zero matrices
        Configa = cell(1,nsFtot);
        Dataa = cell(1,nsFtot);
        ydata = cell(1,nsFtot);
        % replace Configa and Dataa with data from new files 
        for nsF = 1:nsFtot
            % load
            AllinOne = load([GUIControl.odir,'\',GUIControl.MITTdir(nsFmem(nsF)).name],'Config','Data');
            Configa{nsF} = AllinOne.Config;
            Dataa{nsF} = AllinOne.Data;
            if nsF == 1
                % get all field names (including from subFields)
                Configanames = fieldnames(Configa{1});
                Dataanames = ['dummy';subFieldnames(Dataa{1})]; % subroutine to get all field names from array with sub array
            end
            eval(['ydata{nsF} = Configa{',num2str(nsF),'}.',Configanames{nyvar},';']);
        end
        % set active data
        set(B.actfile,'String',{GUIControl.MITTdir(nsFmem).name});
        % check which axes are active and replot
        for nx = 1:plt.nxtot
            if ~isempty(xdata{nx})
                % get values
                nanalysis = get(B.X(nx).analysis,'Value');
                typeanalysis = get(B.X(nx).analysis,'String');
                nxvar = get(B.X(nx).var,'Value');% subtract 1 for dummy value

                set(plt.id,'CurrentAxes',axe.id(nx))
                % allow axes limits to change automatically
                set(axe.id(nx),'XLimMode','auto');
                % clear axis
                cla
                % empty array dat needs to be declared in GUI figure
                dat = [];
                % for each selected array
                for nsF = 1:nsFtot
                    % get data from Dataa
                    eval(['dat = Dataa{',num2str(nsF),'}.',Dataanames{nxvar},';']);
                    % sub array analysis
                    xdata{nx,nsF} = CalcArrayStats(dat,typeanalysis(nanalysis,:));
                    % box is a combination of mean and standard deviation data that needs additional
                    % lines to be plotted
                    if strcmp(typeanalysis(nanalysis,:),'box')
                        serror = std(dat);
                        meanx1 = mean(dat);
                        lx = [meanx1-serror;meanx1+serror];
                        ly = [ydata{nsF};ydata{nsF}];
                        line(lx,ly,'Color',col1,'LineStyle','-','Marker','+');
                    end
                    
                    % plot line
                    h(nsF) = line(xdata{nx,nsF},ydata{nsF},'Color',colline(nsF,:),'LineStyle','none','Marker','*');
                    
                end
                if nx==1 
                    legend(h,get(B.actfile,'String'),...
                        'TextColor','k',...
                        'EdgeColor','k');
                end
                % get automatically determined limits to plot
                xlim = get(gca,'XLim');
                % write values to the appropriate editable boxes
                set(B.X(nx).min,'String',num2str(xlim(1)));
                set(B.X(nx).max,'String',num2str(xlim(2)));

            end
            
        end
        % if patches exist already in the figure
        if isappdata(plt.id,'hpatch')
            % get handles
            rmappdata(plt.id,'hpatch')
        end

        set(B.Filter,'Visible','off');

        % attach data to figure
        setappdata(plt.id,'Configa',Configa)
        setappdata(plt.id,'Dataa',Dataa)
        setappdata(plt.id,'Configanames',Configanames)
        setappdata(plt.id,'Dataanames',Dataanames)
        setappdata(plt.id,'ydata',ydata);
        setappdata(plt.id,'xdata',xdata);
   
    end
%%%%%%%%%%
% Actions panel
    %%%%%
    function hplotpositionsCallback(hObject, eventData, handles)
    % to show positions of probes and sampling volumes within the channel
        % retrieve data from figure
        Configa=getappdata(plt.id,'Configa');

        PlotPositions(Configa,GUIControl.outname);
    
    end
    function hactfileCallback(hObject, eventData, handles)
    % to enable filtering and plotting of active file
    
        % turn on fields
        set(B.plotone,'Enable','on');
        set(B.filtarray,'Enable','on');
        set(B.plotarrayimage,'Enable','on');
        % get values
        naF = get(B.actfile,'Value');
        % retrieve data from figure
        Configa=getappdata(plt.id,'Configa');
        Dataa=getappdata(plt.id,'Dataa');

        Anames = getAnames(Dataa{naF});
        % display the available data component names
        set(B.filtanalysis,'Enable','off');
        set(B.filtanalysis,'String',Anames);
        set(B.Filter,'Visible','off');
        set(B.plotaicomp,'String',Configa{naF}.comp)
        set(B.plotaicomp,'Enable','off');
        set(B.plotaianalysis,'Enable','off');
        set(B.plotaianalysis,'String',Anames);
        

    end
    %%%%%
    function hplotoneCallback(hObject, eventData, handles)
    % to plot timeseries from selected Dataa point in profile
    
        % get values
        naF = get(B.actfile,'Value');
        % retrieve data from figure
        Configa=getappdata(plt.id,'Configa');
        Dataa=getappdata(plt.id,'Dataa');
        ydata = getappdata(plt.id,'ydata');
        % get position of point to plot
        [xi,yi] = ginput(1);
        % find nearest point
        [dum,naP] = min(abs(yi-ydata{naF}));

        PlotTimeSeries(Configa{naF},Dataa{naF},naP);

    end
    %%%%%
    function hplotarrayimageCallback(hObject, eventData, handles)
    % to turn on filtering panel and load previous filter
    % acts when 'Classify' button is pushed on 'Options' panel

        % enable filtering components dropdown menu
        set(B.plotaicomp,'Enable','on');
        
    end
    %%%%%
    function hplotaicompCallback(hObject, eventData, handles)
    % to turn on filtering panel and load previous filter
    % acts when a component is chosen on 'Options' panel

        % enable filter analysis
        set(B.plotaianalysis,'Enable','on');
    
    end
    %%%%%
    function hplotaianalysisCallback(hObject, eventData, handles)
    % to load profile filtering parameters
    % acts when an analysis type is chosen on 'Options' panel
        % get values
        nsFmem = get(B.selfile,'Value');
        naF = get(B.actfile,'Value');
        naC = get(B.plotaicomp,'Value');
        naA = get(B.plotaianalysis,'Value');
        nyvar = get(B.Y.var,'Value');
        Anames = get(B.filtanalysis,'String');
        % retrieve data from figure
        Configa=getappdata(plt.id,'Configa');
        Dataa=getappdata(plt.id,'Dataa');
        ydata = getappdata(plt.id,'ydata');
        Configanames = getappdata(plt.id,'Configanames');
        % isolate correct data
        Config = Configa{naF};
        Data = Dataa{naF};

        % get goodCells for the appropriate component
        % compi is name of component subfield in goodCells
        compi = char(Config.comp(naC));
        xvar = char(Anames(naA));
        goodCellsi = [];
        eval(['goodCellsi = Config.goodCells.',compi,';']);
        Datai = []; % must be declared in GUI file
        eval(['Datai = Data.',xvar,'.',compi,';']);
        aixdata = Data.timeStamp;
        ptitle.top = GUIControl.MITTdir(nsFmem(naF)).name;
        ptitle.xaxis = 'time (s)';
        ptitle.yaxis = ['Config.',Configanames{nyvar}];
        ptitle.legend = [' Data.',xvar,'.',compi,' (m/s)'];
        PlotTimeSpace(aixdata,ydata{naF},Datai,goodCellsi,ptitle)
    end
    %%%%%
    
    function hfiltarrayCallback(hObject, eventData, handles)
    % to turn on filtering panel and load previous filter
    % acts when 'Filter' button is pushed on 'Options' panel

        % enable filtering components dropdown menu
        set(B.filtanalysis,'Enable','on');
        
    end
    %%%%%
    function hfiltanalysisCallback(hObject, eventData, handles)
    % to load profile filtering parameters
    % acts when an analysis type is chosen on 'Options' panel
    
        % get file listed as the active array in 'set active array' window
        naF = get(B.actfile,'Value');
        naA = get(B.filtanalysis,'Value');
        nyvar = get(B.Y.var,'Value');
        Anames = get(B.filtanalysis,'String');
        
        % retrieve data from figure
        Configa = getappdata(plt.id,'Configa');
        Dataa = getappdata(plt.id,'Dataa');
        Configanames = getappdata(plt.id,'Configanames');
        
        % 
        GUIControl.X.var = Anames{naA};
        GUIControl.Y.var = Configanames{nyvar};
        %GUIControl.resetFilter = 0; % load previous analysis, if available
        
        Config = CalcGoodCells(Configa{naF},Dataa{naF},GUIControl);
        % plot table of classificaiton results
        PlotQCTable(Config);
        set(0,'currentfigure',plt.id);
        
        % set field values from Config data
        B.faQC = subSetValues(B.faQC,Config.faQC);        
        
        % draw new patches
        Dataanames = getappdata(plt.id,'Dataanames');
        hpatch = plotgreyp(Config.goodCells,Config.comp,Dataanames,B,plt,axe,naF);

        % attach data to figure
        setappdata(plt.id,'hpatch',hpatch);
        setappdata(plt.id,'faQC',Config.faQC);
        setappdata(plt.id,'goodCells',Config.goodCells);
        set(B.Filter,'Visible','on');
    end

%%%%%%%%%%
% Filter Options panel
%%%%%
    function hreClassifyCallback(hObject, eventData, handles)
    % 
        % get values
        naF = get(B.actfile,'Value');
        naA = get(B.filtanalysis,'Value');
        nyvar = get(B.Y.var,'Value');
        Anames = get(B.filtanalysis,'String');

        % retrieve data from figure
        Configa = getappdata(plt.id,'Configa');
        Dataa = getappdata(plt.id,'Dataa');
        Configanames = getappdata(plt.id,'Configanames');

        % set C values from Interactive Quality Control Plot
        GUIControl.faQC = subGetValues(B.faQC);
        GUIControl.X.var = Anames{naA};
        GUIControl.Y.var = Configanames{nyvar};
        GUIControl.resetFilter = 1;
        
        % send to subprogram to filter array based on faQC parameters
        Config = CalcGoodCells(Configa{naF},Dataa{naF},GUIControl);
        % plot table of classificaiton results
        PlotQCTable(Config);

        set(0,'currentfigure',plt.id);
        % draw new patches
        Dataanames = getappdata(plt.id,'Dataanames');
        hpatch = plotgreyp(Config.goodCells,Config.comp,Dataanames,B,plt,axe,naF);

        % attach data to figure
        setappdata(plt.id,'faQC',GUIControl.faQC);
        setappdata(plt.id,'goodCells',Config.goodCells);
        setappdata(plt.id,'hpatch',hpatch);
   
    end

    function hmanualGoodCellsCallback(hObject, eventData, handles)
        % get file listed as the active array in 'set active array' window
        naF = get(B.actfile,'Value');
        % retrieve data from figure
        goodCells=getappdata(plt.id,'goodCells');
        ydataa = getappdata(plt.id,'ydata');
        ydata = ydataa{naF};
        comp = fieldnames(goodCells);
        ncomptot = length(comp);
        [xselect,yselect] = ginput(1);
        % find nearest point
        [dum,nogoo] = min(abs(yselect-ydata));
        
        goodCellsm = ConvStruct2Multi(goodCells,comp);
        
%         % convert multi to struct (what the fuck is this about?)
%         commented out on June 17 2014
%         if length(ydata)>1
%             goodCellsm = ConvStruct2Multi(goodCells,comp)';
%         else
%             goodCellsm = ConvStruct2Multi(goodCells,comp);
%         end
        %switch it
        if all(goodCellsm(:,nogoo))
            goodCellsm(:,nogoo) = 0;
        else
            goodCellsm(:,nogoo) = 1;
        end
        for ncomp = 1:ncomptot
            goodCells.(comp{ncomp}) = goodCellsm(ncomp,:);
        end
       
        % draw new patches
        Dataanames = getappdata(plt.id,'Dataanames');
        hpatch = plotgreyp(goodCells,comp,Dataanames,B,plt,axe,naF);

        % attach data to figure
        setappdata(plt.id,'goodCells',goodCells);
        setappdata(plt.id,'hpatch',hpatch);
        
    end
    function hsaveQCCallback(hObject, eventData, handles)
        % function to save QC to output file
        
        % get values
        nsFmem = get(B.selfile,'Value');
        naF = get(B.actfile,'Value');
        % retrieve data from figure
        Configa = getappdata(plt.id,'Configa');
        goodCells=getappdata(plt.id,'goodCells');
        faQC = getappdata(plt.id,'faQC');

        Config = Configa{naF};
        Config.faQC = faQC;
        Config.goodCells = goodCells;

        Configa{naF} = Config;
        setappdata(plt.id,'Configa',Configa);

        % append Config to existing output file
        save([GUIControl.odir,'\',GUIControl.MITTdir(nsFmem(naF)).name],'Config','-append');
        
    end

%%%%%%%%%%
% y axis callbacks
    %%%%%
    % executes when y axis variable is changed
    function hyvarCallback(hObject, eventData, handles)
    % to get ydata values from Configa structure
        % get values
        nsFmem = get(B.selfile,'Value');
        nyvar = get(B.Y.var,'Value');
        % calc number of files selected
        nsFtot = length(nsFmem);
        % get data from figure
        Configa = getappdata(plt.id,'Configa');
        Configanames = getappdata(plt.id,'Configanames');

        % loop to get ydata for each file 
        ydata = cell(1,nsFtot);
        xdata = cell(plt.nxtot,nsFtot);
        for nsF = 1:nsFtot
            eval(['ydata{nsF} = Configa{',num2str(nsF),'}.',Configanames{nyvar},';']);
        end
        
        % attach data to figure
        setappdata(plt.id,'ydata',ydata);
        setappdata(plt.id,'xdata',xdata);
         % turn on fields
        set(B.X(1).panel,'Visible','on');
        set(B.X(1).var,'Enable','on');
        % set control
        uicontrol(B.X(1).var);

    end
    %%%%%
    % executes when either y minimum or y maximum editable box is changed
    function hyminCallback(hObject, eventData, handles)
    % to set y axis limits manually
        % get values
        ymin = str2double(get(B.Y.min,'String'));
        ymax = str2double(get(B.Y.max,'String'));
        % set y axis limits on all axes
        for nx = 1:plt.nxtot
            set(axe.id(nx),'YLim',[ymin ymax]);
        end
    end

%%%%%%%%%%
% xaxis callbacks
    %%%%%
    % executes when x variable is changed on axis nx
    function hxvarCallback(hObject, eventData, nx)
    % to turn on the x analysis field
        % turn on fields
        set(B.X(nx).analysis,'Enable','on');
        % set control
        uicontrol(B.X(nx).analysis); % set focus on the button bforward
    end
    %%%%%
    % executes when analysis is changed on axis nx
    function hxanalysisCallback(hObject, eventData, nx)
    % to plot xdata vs ydata for a given axis
        % get values
        nanalysis = get(B.X(nx).analysis,'Value');
        typeanalysis = get(B.X(nx).analysis,'String');
        nxvar = get(B.X(nx).var,'Value');% 
        % get data from figure
        Dataa=getappdata(plt.id,'Dataa');
        Dataanames = getappdata(plt.id,'Dataanames');
        ydata=getappdata(plt.id,'ydata');
        xdata=getappdata(plt.id,'xdata');
        % set current axes
        set(plt.id,'CurrentAxes',axe.id(nx))
        % empty array dat needs to be declared in GUI figure
        dat = [];
        % loop to plot Dataa
        nsFtot = length(Dataa);
        colline = getColline(nsFtot);
        for nsF = 1:nsFtot
            % get data from Dataa
            eval(['dat = Dataa{',num2str(nsF),'}.',Dataanames{nxvar},';']);
            % sub array analysis
            xdata{nx,nsF} = CalcArrayStats(dat,typeanalysis(nanalysis,:));
            if strcmp(typeanalysis(nanalysis,:),'box')
                serror = std(dat);
                meanx1 = mean(dat);
                lx = [meanx1-serror;meanx1+serror];
                ly = [ydata{nsF};ydata{nsF}];
                line(lx,ly,'Color',col1,'LineStyle','-','Marker','+');
            end
            % plot line
            h(nsF) = line(xdata{nx,nsF},ydata{nsF},'Color',colline(nsF,:),'LineStyle','none','Marker','*');
        end
        
        % get automatically determined limits to plot
        xlim = get(gca,'XLim');
        ylim = get(gca,'YLim');
        % write values to the appropriate editable boxes
        set(B.Y.min,'String',num2str(ylim(1)));
        set(B.Y.max,'String',num2str(ylim(2)));
        set(B.X(nx).min,'String',num2str(xlim(1)));
        set(B.X(nx).max,'String',num2str(xlim(2)));

        % attach data to figure
        setappdata(plt.id,'xdata',xdata)
        % turn on fields
        set(B.Y.min,'Enable','on');
        set(B.Y.max,'Enable','on');
        set(B.X(nx).min,'Enable','on');
        set(B.X(nx).max,'Enable','on');
        set(B.X(nx).clear,'Enable','on');
        if nx==1 
            set(B.Actions,'Visible','on');
            legend(h,get(B.actfile,'String'),...
                'TextColor','k',...
                'EdgeColor','k');
        end
        % enable next panel
        if nx<plt.nxtot
            set(B.X(nx+1).panel,'Visible','on');
            set(B.X(nx+1).var,'Enable','on');
        end
        % allow replacement of data on axes
        if nx == 1
            set(B.replace,'Enable','on')
        end
    end
    %%%%%
    % executes when either x minimum or x maximum editable box is changed
    function hxminCallback(hObject, eventData, nx)
    % to set x axis limits manually
        % get values
        xmin = str2double(get(B.X(nx).min,'String'));
        xmax = str2double(get(B.X(nx).max,'String'));
        % set axis x limits
        set(axe.id(nx),'XLim',[xmin xmax]);
    end
    %%%%%
    % executes when clear axis button is pushed
    function hxclearCallback(hObject, eventData, nx)
    % to clear all data and legends from axis
        % set current axis
        set(plt.id,'CurrentAxes',axe.id(nx))
        % allow axes limits to change automatically
        set(axe.id(nx),'XLimMode','auto');
        % clear axis
        cla
    end

end

%%%%%%%%%%
% subprograms
%%%%%

%%%%%
function [plt,axe]=qcFigure
% to create the Figure used for the interactive qc analysis.  
% Note, this subprogram only includes the figures and axes, not the buttons

% set figure properties
plt.id = figure;
plt.xi = 1; % corner position of figure
plt.yi = 1; 
plt.nxtot = 3; % number of axes in x direction
plt.nytot = 1; % number of axes in y direction
plt.titlespace = 8.5; % distance above plots (mostly filled later with buttons)
plt.col = [230 230 230]/255;
% create multiple axes
axe.xi = 1.1; % corner position of first axis
axe.yi = 0.6;
axe.scale = 8; % multiplier for axes
axe.y = 1*axe.scale;
axe.x = 1*axe.scale;
axe.space = .4; % space between axes

% size of figure
plt.x = axe.xi+plt.nxtot*(axe.x+axe.space);
plt.y = axe.yi+plt.nytot*(axe.y+axe.space)+plt.titlespace;

% set figure properties
set(plt.id,...
    'Name','MIFTT Interactive Quality Control Window',...
    'Units','centimeters',...
    'InvertHardcopy','off',...
    'Color',plt.col,...
    'Position',[plt.xi plt.yi plt.x plt.y],...
    'PaperPositionMode','auto');

% size of axes
axe.xin = axe.xi+(0:plt.nxtot-1)*(axe.x+axe.space);
axe.yin = axe.yi;

% create and set axes properties
for nx=1:plt.nxtot
    axe.id(nx) = axes('Units','centimeters',...
        'Position',[axe.xin(nx) axe.yin axe.x axe.y],...
        'Color','w',...
        'NextPlot','add');
    if nx>1
        set(axe.id(nx),'YTickLabel',[]);
    end
end

end
%%%%%
function hpatch = plotgreyp(goodCells,comp,Dataanames,B,plt,axe,naF)
% to draw grey 'patches' on all axes to indicate positions that have been
% judged to not be a goodCell
% hpatch is the handle for the patches

% create a multidimensional array from goodCells
ncomptot = length(comp);
nCells = length(goodCells.(comp{1}));
goodCellsm = ConvStruct2Multi(goodCells,comp);

% if patches exist already in the figure
if isappdata(plt.id,'hpatch')
    % get handles
    hpatch = getappdata(plt.id,'hpatch');
    % detect if graphic object handle
    % for each axes
    for nx = 1:plt.nxtot
        if hpatch(nx,1)>0
            % delete the patches
            delete(hpatch(nx,:));
        end
    end
    rmappdata(plt.id,'hpatch')
end

% get ylimits of the patches based on saved ydata and limits of the axes
ydataa = getappdata(plt.id,'ydata');
ylim = get(axe.id(1),'YLim');
ydata = ydataa{naF};
if nCells > 1
    ylimi = [ylim(end) ydata(1:end-1)+diff(ydata)/2 ylim(1)];
else
    ylimi = ylim;
end    
% zeromatrix for hpatch based on number of cells and axes
hpatch = zeros(plt.nxtot,nCells);

% set criteria for good cell display

% for each axes
for nx = 1:plt.nxtot;
    % get index value of x axis variable
    xvar = get(B.X(nx).var,'Value');
    % if xvar>1 (i.e. it is not an empty axis)
    if xvar>1
        % set current axis
        set(plt.id,'CurrentAxes',axe.id(nx))
        % get xname
        xname = Dataanames{xvar};
%         % initialize variable compy to get y component
%         compy = zeros(1,ncomptot);
%         
%         for ncomp = 1:ncomptot
%             compidx = strfind(xname,char(comp{ncomp}));
%             % if
%             if ~isempty(compidx)
%                 compy(ncomp) = 1;
%             else
%                 
%             end
%         end
%         ncompy = find(compy);
        xlim = get(axe.id(nx),'XLim');

        % all components must be good
        if ncomptot == 1
            ygood = goodCellsm;
        else
            goo2D=squeeze(goodCellsm(1,:,:));
            ygood = all(goo2D,2);
        end

        % for each cell in the array
        for ncell = 1:nCells
            % draw the patch and save the handle
            hpatch(nx,ncell) = patch([xlim fliplr(xlim)],...
                [ylimi(ncell) ylimi(ncell) ylimi(ncell+1) ylimi(ncell+1)],...
                [1 1 1]*ygood(ncell),...
                'AlphaDataMapping','direct',...
                'FaceAlpha',0.2,...
                'EdgeAlpha',0);
        end
    end
end

end

%%%%%
function colline = getColline(ntot)
% to create a color matrix with ntot number of different colors based on a matlab standard colormap
% create unique color values for each file
cmap = flipud(jet);%jet;% % jet coloring, could also be used with bone, autumn, etc.
njettot = length(cmap);
ngooc = floor(1:njettot/ntot:njettot);

colline = cmap(ngooc,:);

end

%%%%%
function B = qcButtons(plt,axe)
% to create buttons & fields on figure
% set colors for figure
backcol = [255 245 170]/255; % used on level 1 boxes
backcol2 = [210 255 255]/255; % used on axes boxes
btn.height = 0.7; % standard button height
btn.width = axe.x/3;
Fsize = 9;

% ui panel listing all filter array options and parameters
B.Select = uipanel(plt.id,'Title','Select arrays to plot',...
            'Units','centimeters',...
            'FontSize',Fsize,...
            'BackgroundColor',backcol,...
            'Position',[axe.xin(1),axe.yi+axe.y+3.8,axe.x+0.1,4.7]);
% file selection listbox             
B.selfile = uicontrol(plt.id,'Style','listbox',...
            'Units','centimeters',...
            'Parent',B.Select,...
            'Position',[0,0,btn.width*2,4],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Max',5);
% file selection 'Done' pushbutton
B.selfiledone = uicontrol(plt.id,'Style','pushbutton',...
            'Units','centimeters',...
            'Parent',B.Select,...
            'Position',[btn.width*2,btn.height,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Done');
% file selection 'Replace' pushbutton
B.replace = uicontrol(plt.id,'Style','pushbutton',...
            'Units','centimeters',...
            'Parent',B.Select,...
            'Position',[btn.width*2,0,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Replace');
% Y axis variables panel
B.Y.panel = uipanel(plt.id,'Title','y-axis Data',...
            'Units','centimeters',...
            'FontSize',Fsize,...
            'BackgroundColor',backcol2,...
            'Position',[axe.xin(1),axe.yi+axe.y+2.4,axe.x+0.1,1.3]);
% Y axis variable popupmenu
btn.num = 0;
B.Y.var = uicontrol(plt.id,'Style','popupmenu',...
            'Units','centimeters',...
            'Parent',B.Y.panel,...
            'Position',[0,btn.num*btn.height,btn.width*2,btn.height],...
            'FontSize',Fsize,...
            'Enable','off',...
            'BackgroundColor','w',...
            'String','y-axis Dataa');
% Y axis minimum value editable field
B.Y.min = uicontrol(plt.id,'Style','edit',...
            'Units','centimeters',...
            'Position',[btn.width*2,btn.num*btn.height,btn.width*0.5,btn.height],...
            'Parent',B.Y.panel,...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','ymin');
% Y axis maximum value editable field
B.Y.max = uicontrol(plt.id,'Style','edit',...
            'Units','centimeters',...
            'Position',[btn.width*2.5,btn.num*btn.height,btn.width*0.5,btn.height],...
            'Parent',B.Y.panel,...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','ymax');        

% Dataa selection dropdown
for nx = 1:plt.nxtot
    B.X(nx) = Createaxebuttongroup(plt.id,axe.xin(nx),axe.x,axe.yi+axe.y,nx,btn,Fsize);
    set(B.X(nx).panel,'BackgroundColor',backcol2)
end    

%
B.Actions = uipanel(plt.id,'Title','Actions',...
            'Units','centimeters',...
            'FontSize',Fsize,...
            'BackgroundColor',backcol,...
            'Position',[axe.xin(2),axe.yi+axe.y+3.8,axe.x+0.1,4.7]);

btn.num = 5;
% plot probe and sampling volume positions button
B.plotpositions = uicontrol('Style','pushbutton',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[0,btn.num*btn.height,btn.width*3,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Plot sampling volume positions');
btn.num = btn.num-1;
% active file dropdown
B.actfilename = uicontrol(plt.id,'Style','text',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[0,btn.num*btn.height,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Set active array');
B.actfile = uicontrol(plt.id,'Style','popupmenu',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[btn.width,btn.num*btn.height,btn.width*2,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','a');
btn.num = btn.num-1;
% plot one series radio button
B.plotone = uicontrol('Style','pushbutton',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[0,btn.num*btn.height,btn.width*3,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','Plot one series');
btn.num = btn.num-1;
% filter array radio button
B.plotarrayimage = uicontrol('Style','pushbutton',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[0,btn.num*btn.height,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','Plot Array Image');
B.plotaicomp = uicontrol('Style','popupmenu',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[btn.width,btn.num*btn.height,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','components');
B.plotaianalysis = uicontrol('Style','popupmenu',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[btn.width*2,btn.num*btn.height,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','analysis');

btn.num = btn.num-1;
% filter array radio button
B.filtarray = uicontrol('Style','pushbutton',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[0,btn.num*btn.height,btn.width,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','Classify data qual.');
B.filtanalysis = uicontrol('Style','popupmenu',...
            'Units','centimeters',...
            'Parent',B.Actions,...
            'Position',[btn.width,btn.num*btn.height,btn.width*2,btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','analysis');

% ui panel listing all filter array options and parameters
B.Filter = uipanel('Title','Classify Data Quality Options',...
            'Units','centimeters',...
            'FontSize',Fsize,...
            'BackgroundColor',backcol,...
            'Position',[axe.xin(3),axe.yi+axe.y+2.4,axe.x+0.1,6.1]);
% make faQC buttons
btn.num = 7;
B.faQC = makefaQCbuttons(B.Filter,btn,Fsize);

btn.num = 0;
% recalculate button for filter array
B.reClassify = uicontrol(plt.id,'Style','pushbutton',...
            'Parent',B.Filter,...
            'Units','centimeters',...
            'Position',[0 btn.num*btn.height btn.width btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Reclassify');
% manually adjust filter
B.manualGoodCells = uicontrol(plt.id,'Style','pushbutton',...
            'Parent',B.Filter,...
            'Units','centimeters',...
            'Position',[btn.width btn.num*btn.height btn.width btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Manually Adjust Classes');
% save button
B.saveQC = uicontrol(plt.id,'Style','pushbutton',...
            'Parent',B.Filter,...
            'Units','centimeters',...
            'Position',[btn.width*2 btn.num*btn.height btn.width btn.height],...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'String','Save Classification');

end
%%%%%
function X = Createaxebuttongroup(id,xin,x,y,nx,btn,Fsize);
% to create xaxis control fields for each axis
X.panel = uipanel(id,'Title',['x',num2str(nx),'-axis Data'],...
            'Units','centimeters',...
            'FontSize',Fsize,...
            'BackgroundColor','white',...
            'Position',[xin,y+0.2,x+0.1,2.1]);
btn.num = 1;
% variable to be analysed
X.var = uicontrol(id,'Style','popupmenu',...
            'Units','centimeters',...
            'Position',[0 btn.num*btn.height btn.width*2 btn.height],...
            'Parent',X.panel,...
            'FontSize',Fsize,...
            'Enable','off',...
            'BackgroundColor','w',...
            'String','dependant variable 1st axis');
% X axis minimum value editable field
X.min = uicontrol(id,'Style','edit',...
            'Units','centimeters',...
            'Position',[btn.width*2,btn.num*btn.height,btn.width*0.5,btn.height],...
            'Parent',X.panel,...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','xmin');
% X axis maximum value editable field
X.max = uicontrol(id,'Style','edit',...
            'Units','centimeters',...
            'Position',[btn.width*2.5,btn.num*btn.height,btn.width*0.5,btn.height],...
            'Parent',X.panel,...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','xmax');
btn.num = 0;
% analysis type
X.analysis = uicontrol(id,'Style','popupmenu',...
            'Units','centimeters',...
            'Position',[0,btn.num*btn.height,btn.width,btn.height],...
            'Parent',X.panel,...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','sum|mean|std|skew|kurt|box');
% clear axis
X.clear = uicontrol(id,'Style','pushbutton',...
            'Units','centimeters',...
            'Position',[btn.width*2,btn.num*btn.height,btn.width,btn.height],...
            'Parent',X.panel,...
            'FontSize',Fsize,...
            'BackgroundColor','w',...
            'Enable','off',...
            'String','clear axis');
end
