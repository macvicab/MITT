function Config = PositionXYZSpree(GUIControl,CSVControl)

    Config.zpos = [0.28 CSVControl.zpos2];
    Config.xpos = [0 CSVControl.xpos2];
    Config.ypos = [0 CSVControl.ypos2];
    Config.waterDepth = [CSVControl.waterDepth1 CSVControl.waterDepth2];
end