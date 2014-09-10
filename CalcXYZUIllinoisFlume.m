function Config = CalcXYZUIllinoisFlume(GUIControl,CSVControl,Config,Data)
% this version created from MasterUVPv2p3 subprograms to work with the data
% from Illinois as it was entered into the tables.  Additional parameters
% such as Control.tdist and Control.xadist will be moved to the tables because they change
% with different runs and their inclusion here makes the programs full of
% confusing exceptions

%Config = CalcProbePos(Config,Control,C);
for na = 1:Config(1).nArrays
    if CSVControl.theta == 0
        if CSVControl.phi == -60
            Config(na).orient = 1; % direction downstream with 60deg angle
            pdis = (na-1)*CSVControl.tdist/3; % distance between probes (aluminum frame)
            Config(na).xpos1 = round(10000*(CSVControl.xReading+CSVControl.xadis))/10000;% xpos is xpos1 - dist to probe center
            Config(na).ypos1 = round(10000*(CSVControl.yReading+pdis))/10000;% ypos determined by pdis 
            zbeam = interp1(GUIControl.oneD.xchannel,GUIControl.oneD.beamh,Config(na).xpos1);
            % zpos is from top of blue + dist to flume top + ProfPos + dist to 0 on lory - reading on lory - distance below 2.09 mark to the centre of the probe
            Config(na).zpos1 = round(10000*(zbeam-((CSVControl.elholder-CSVControl.zReading)*.3048+CSVControl.dhold2pb)-CSVControl.aheight))/10000; %9.4 cm is distance from top of holder to probe
        elseif CSVControl.phi == -90
            Config(na).orient = 5; % vertical probe pointing down
            pdis = floor(10000*(na-1)*CSVControl.tdist/3)/10000; % distance between probes (aluminum frame)
            Config(na).xpos1 = round(10000*(CSVControl.xReading+CSVControl.xadis))/10000;% xpos is xpos1 - dist to probe center
            Config(na).ypos1 = round(10000*(CSVControl.yReading+pdis))/10000;% ypos determined by pdis 
            zbeam = interp1(GUIControl.oneD.xchannel,GUIControl.oneD.beamh,Config(na).xpos1);
            % zpos is from top of blue + dist to flume top + ProfPos + dist to 0 on lory - reading on lory - distance below 2.09 mark to the centre of the probe
            Config(na).zpos1 = round(10000*(zbeam-((CSVControl.elholder-CSVControl.zReading)*.3048+CSVControl.dhold2pb)-CSVControl.aheight))/10000; %zbeam
        end
    elseif CSVControl.theta == 180
        Config(na).orient = 2; % direction upstream with 60deg angle
        pdis = (na-1)*CSVControl.tdist/3; % distance between probes (aluminum frame)
        Config(na).xpos1 = floor(10000*(CSVControl.xReading+CSVControl.xadis))/10000;% xpos is xpos1 + dist to probe center % check this distance
        Config(na).ypos1 = floor(10000*(CSVControl.yReading-pdis))/10000;% ypos determined by pdis 
        zbeam = interp1(GUIControl.oneD.xchannel,GUIControl.oneD.beamh,Config(na).xpos1);
        % zpos is from top of blue + dist to flume top + ProfPos + dist to 0 on lory - reading on lory - distance below 2.09 mark to the centre of the probe
        Config(na).zpos1 = floor(10000*(zbeam-((CSVControl.elholder-CSVControl.zReading)*.3048+CSVControl.dhold2pb)-CSVControl.aheight))/10000; 
    elseif CSVControl.theta == 90
        if CSVControl.phi == -60
            Config(na).orient = 3; % direction sideways with 60 deg angle
            pdis = (na-1)*CSVControl.tdist/3; % distance between probes (aluminum frame)
            Config(na).xpos1 = floor(10000*(CSVControl.xReading+pdis))/10000;% xpos is xpos1
            Config(na).ypos1 = floor(10000*(CSVControl.yReading))/10000;% ypos determined by pdis 
            zbeam = interp1(GUIControl.oneD.xchannel,GUIControl.oneD.beamh,probedata.x(npmem(2)));
            % zpos is from top of blue + dist to flume top + ProfPos + dist to 0 on lory - reading on lory - distance below 2.09 mark to the centre of the probe
            Config(na).zpos1 = floor(10000*(zbeam-((CSVControl.elholder-CSVControl.zReading)*.3048+CSVControl.dhold2pb-CSVControl.aheight)))/10000; 
        else
            Config(na).orient = 4; % through sidewall
            pdis = 0.0175+(na-1)*(0.1025-0.0175)/3; % distance between probes (sideways aluminum frame)
            Config(na).xpos1 = floor(10000*(CSVControl.xReading))/10000;% xpos is xpos1
            Config(na).ypos1 = floor(10000*(CSVControl.yReading))/10000;% ypos  
            zbeam = interp1(GUIControl.oneD.xchannel,GUIControl.oneD.beamh,Config(na).xpos1);
            Config(na).zpos1 = floor(10000*(zbeam-CSVControl.SDdiff-(CSVControl.elholder-CSVControl.zReading)*.3048-pdis))/10000; % zpos determined by pdis
        end
    end
end


%Config = CalcCellPos(Config,Control,C);
%% calc cell pos
% cell pos (x,y,z), radius, volume, touchside, touchbed
% max and min positions corrected - removed rtallow which was not
% functioning as intended
ang = 2.2; % spread angle of beam
natot = Config(1).nArrays;

bedzi = zeros(1,natot);
for na = 1:natot
    % 2nd approach - use amp data to check bed position
    Amp = ConvStruct2Multi(Data(na).Amp,Config(na).comp);
    % find where amp > 200 for the first time after the first bit
    bednogoo = abs(mean(Amp))>300;
    ab = find(bednogoo(:,10:end),1,'first')+8;
    if ~isempty(ab)
        bedzi(na) = ab;
    else
        bedzi(na) = NaN;
    end
end
bedz = round(nanmean(bedzi));

for na = 1:natot

    % distance along beam to cell
    xt = (0:Config(na).nCells-1)*Config(na).cellInterval + Config(na).cellStart;

    % calculate position of cell
    [dx,dy,dz] = sph2cart(deg2rad(CSVControl.theta),deg2rad(CSVControl.phi),xt);
    Config(na).xpos = floor(10000*(Config(na).xpos1+dx))/10000;
    Config(na).ypos = floor(10000*(Config(na).ypos1+dy))/10000;
    Config(na).zposGlobalm = floor(10000*(Config(na).zpos1+dz))/10000;

    % calculate radius of cell
    Config(na).cellRadius = xt*tan(deg2rad(ang))+0.0025;
    % calculate cell volume
    Config(na).samplingVolume = pi*Config(na).cellRadius.^2.*Config(na).cellWidth;

    % find max/min y positions to check for side touch
    % allow some touching - added on May 10, 2010 - say 25 % touch
    rtallow = 0.75;
    miny = Config(na).ypos - rtallow*Config(na).cellRadius;
    maxy = Config(na).ypos + rtallow*Config(na).cellRadius;
    Config(na).Y = interp1(GUIControl.oneD.xchannel,GUIControl.oneD.Y,Config(na).xpos); %
    Config(na).touchingSide = miny<0 | maxy>CSVControl.Y;
    Config(na).yY = floor(10000*(Config(na).ypos./Config(na).Y))/10000;

    %find max/min z position to check for surface or bed touch
    [dx,dy,dzmi] = sph2cart(deg2rad(CSVControl.theta),deg2rad(CSVControl.phi-ang),xt);
    minz = floor(10000*(Config(na).zpos1+dzmi))/10000;
    [dx,dy,dzma] = sph2cart(deg2rad(CSVControl.theta),deg2rad(CSVControl.phi+ang),xt);
    maxz = floor(10000*(Config(na).zpos1+dzma))/10000;

    % interpolate bed and water surfaces using Fbed and Fwater 2D interpolants
    Config(na).bedElevation = floor(10000*(GUIControl.twoD.Fbed(Config(na).xpos,Config(na).ypos)))/10000; % use
    Config(na).waterElevation = floor(10000*(GUIControl.twoD.Fwater(Config(na).xpos,Config(na).ypos)))/10000;
    Config(na).waterDepth = floor(10000*(Config(na).waterElevation-Config(na).bedElevation))/10000;
    Config(na).zposm = floor(10000*(Config(na).zposGlobalm-Config(na).bedElevation))/10000;
    Config(na).zZm = floor(10000*(Config(na).zposm./Config(na).waterDepth))/10000;
    if Config(na).orient~=4 && ~isnan(bedz)
        % calc zposb
        Config(na).zpos = -dz(bedz)+dz;
        % calc zpos as bedElevation + zposb
        Config(na).zposGlobal = Config(na).bedElevation + Config(na).zpos;
        % calc zZ as zpos/waterDepth
        Config(na).zZ = Config(na).zpos./Config(na).waterDepth;
    
    else
        Config(na).zpos = Config(na).zposm;
        Config(na).zZ = Config(na).zZm;
    end
    
    Config(na).touchingBed = minz<Config(na).bedElevation; 
    Config(na).touchingWaterSurface = maxz>Config(na).waterElevation;

end
end



