function Config = CalcXYZUWFlume(Config);
% determine xyz position of sampled volumes
% this subprogram will likely have to be modified for different
% experimental setups.  Key measurements can be passed to this function via
% the Control *.csv file

% calculate distances from the probe head for all cells
Config.cellDist = Config.cellStart+ Config.cellInterval*(0:Config.nCells-1);
% if orientation == 1 the probe was deployed vertically
if Config.Orientation == 1
    Config.zpos = Config.zpos1-Config.cellDist;
    Config.xpos = Config.xpos1*ones(1,Config.nCells);
    Config.ypos = Config.ypos1*ones(1,Config.nCells);
end

end