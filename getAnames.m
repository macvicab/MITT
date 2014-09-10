function Anames = getAnames(Data)
% get names of all analyses that have been performed
% called from ClassifyArrayGUI

Anamesi = {'Vel','Despiked','Filtered'};
nAtot = length(Anamesi);
nidx = 1;            
% get other analysese and save in Pdata
for nA = 1:nAtot
    % check if analysis was completed
    eval(['chk = isfield(Data,''',char(Anamesi{nA}),''');']);
    if chk
        % convert structure to multidimensional array format
        Anames{nidx} = Anamesi{nA};
        nidx = nidx+1;
    end
end

end