function GUIControl = CalcChannelMesh(GUIControl,CSVControl)
% 3rd level program for organization of calculation of test volume
% topography and water surface grid
% Called from OrganizeInput
% Calls InterpolateUniformChannel, InterpolateNonUniformChannel, or custom subprogram

% check how channel information will be input
% if it is a uniform channel
if GUIControl.IsUniform == 1
    % send to subprogram
    [oneD,twoD] = InterpUniformChan(GUIControl.Slope,GUIControl.Width,GUIControl.Depth,GUIControl.Length,GUIControl.Sideslope,GUIControl.Widthgrid,GUIControl.Depthgrid,GUIControl.Lengthgrid);
% if it is non-uniform
else
    % get
    if GUIControl.Channel == 1 % a *.csv file has been specified
        filename1 = [GUIControl.CalcChannelpathname,GUIControl.CalcChannelfile];
        [oneD,twoD] = InterpNonUniformChan(filename1);
    elseif GUIControl.Channel == 2 % a subprogram has been specified
        eval(['[oneD,twoD] = ',GUIControl.CalcChannelfile(1:end-2),'(GUIControl,CSVControl);']);

    end
end

% save one and two dimensional meshes to C for safekeeping
GUIControl.oneD = oneD;
GUIControl.twoD = twoD;

end