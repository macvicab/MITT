function xdat = CalcArrayStats(dat,typeanalysisi)
% calculates a statistical parameter from a data array
% called from AFiltArrayGUI

% 
switch typeanalysisi
    case 'sum '
        xdat = sum(dat);
    case 'mean'
        xdat = mean(dat);
    case 'std '
        xdat = std(dat);
    case 'skew'
        xdat = skewness(dat);
    case 'kurt'
        xdat = kurtosis(dat);
    case 'box '
        xdat = mean(dat);
end

end
