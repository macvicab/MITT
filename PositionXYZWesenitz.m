function Config = PositionXYZSpree(GUIControl,CSVControl)

    Config.zpos = [CSVControl.zpos1 CSVControl.zpos1];
    Config.xpos = [CSVControl.xpos1 CSVControl.xpos1];
    Config.ypos = [CSVControl.ypos1+CSVControl.deltaypos CSVControl.ypos1];
    Config.waterDepth = [CSVControl.waterDepth1 CSVControl.waterDepth2];
end