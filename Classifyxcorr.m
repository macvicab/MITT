function [goodCellsii,Qxcorr] = Classifyxcorr(dat,xcorrthreshold)
% calculates goodCells based on cross correlation between adjacent data cells

% calculate size of Data matrix
[nttot,nrtot] = size(dat);
cmax = zeros(2,nrtot);
% if there is more than one cell
if nrtot>1
    for nr = 2:nrtot
        c = xcorr(dat(:,nr),dat(:,nr-1),50,'coeff');
        cmax(2,nr-1) = max(c);
        cmax(1,nr) = max(c);
    end
    Qxcorr = nanmax(cmax)'*100;
    goodCellsii = Qxcorr > xcorrthreshold;
else
    Qxcorr = NaN;
    goodCellsii = 1;
end
    
end