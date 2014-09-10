function [goodCellsi,QCor] = ClassifyCor(compi,Cor,Corthreshold)
% evaluate goodCells based on measured correlation threshold

compmem = fieldnames(Cor);
ncomptot = length(compmem);
compstr = cell(ncomptot,1);

for nc = 1:ncomptot
    % create a string with field names
    eval(['compstr(nc) = {''Beam',num2str(nc),'''};']);
end

COR = ConvStruct2Multi(Cor,compstr);
[nttot,nCells,ncomptot] = size(COR);

QCor = squeeze(mean(COR));

goodCor = QCor>Corthreshold;

% if 4 components, then a Nortek instrument is being used
if ncomptot == 4
    if any(strcmp(compi,{'u','w1'}))
        if nCells>1
            goodCellsi = goodCor(:,1) & goodCor(:,3);
        else
            goodCellsi = goodCor(1) & goodCor(3);
        end        
    else
        if nCells>1
            goodCellsi = goodCor(:,2) & goodCor(:,4);
        else
            goodCellsi = goodCor(2) & goodCor(4);
        end        
    end
% if three components then it is the Sontek instrument
elseif ncomptot == 3
    % then they are all entangled
    goodCellsi = all(goodCor);
% else this method is not relevant (for example, the ECM)
else
    goodCellsi = ones(1,nCells);
end
end
