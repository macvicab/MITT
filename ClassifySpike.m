function [goodCellsi,QSpike] = ClassifySpike(SpikeY,Spikethreshold)
% evaluate goodCells based on frequency of spikes threshold

QSpike = sum(SpikeY)/length(SpikeY)*100;

goodCellsi = QSpike<Spikethreshold;

end
