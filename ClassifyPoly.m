function goodCellsii = ClassifyPoly(ydata,dat,goodCellsi,zscore)
% get Udata along with goodCellsi - analysis of good cells from other analyses
% output goodCellsii - analysis of remaining good cells using polynomial fit

% minimum number of cells required to calculate polynomial fits
nCellcrit = 5;

% initialize output
goodCellsii = goodCellsi;

% calculate statistics
Umean = mean(dat);
Ustd = std(dat);
Uskew = skewness(dat);

% find only the non nan values
nanmem = isnan(Umean)|isnan(Ustd)|isnan(Uskew);

%% outlier removal algorithm
outlier=1;
% while there may be an outlier
while outlier
    % if there are a minimum of 5 points in the profile
    goodCellsiimem = find(goodCellsii&~nanmem');
    if length(goodCellsiimem)>nCellcrit
        % find outliers on Umean profile
        [fresult,gof,output]=fit(ydata(goodCellsiimem)',Umean(goodCellsiimem)','poly3');
        % assuming zscore of 2.58 or 99%
        b=abs(output.residuals)>zscore*std(output.residuals);

        % find outliers on Ustd profile
        [fresult,gof,output]=fit(log(ydata(goodCellsiimem)'),Ustd(goodCellsiimem)','poly3');
        c=abs(output.residuals)>zscore*std(output.residuals);

        % find outliers on Uskew profile
        [fresult,gof,output]=fit(log(ydata(goodCellsiimem)'),Uskew(goodCellsiimem)','poly3');
        d=abs(output.residuals)>zscore*std(output.residuals);

        e=b|c|d;

        outlier = sum(e)>1;
        goodCellsii(goodCellsiimem(e))=0;
    else
        outlier = 0;
    end
end

end