function [goodCellsi,Modepct] = ClassifyMode(vel,pctmode)
% determines goodCells based on the frequency of the mode.  
% time series with a very frequent mode are not likely to be turbulent data
% written by S.Dilling 2014, modified by B. MacVicar 2015

[nttot,nCtot] = size(vel);
goodCellsi = true(nCtot,1);
nmaxmode = nttot*pctmode;

[~,nummode,~] = mode(vel);
flat = nummode' > nmaxmode;
if any(flat)
    goodCellsi(flat) = 0;
end
Modepct = nummode'/nttot*100;
end