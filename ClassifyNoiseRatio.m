function [goodCellsii,QNRW] = ClassifyNoiseRatio(dat,w1w2xcorrthreshold,transformationMatrix)
% classifies goodCells based on HurtherLemmin 2001 criteria of noise ratio
% from redundant vertical velocity measurements

comp = fieldnames(dat);

datm = ConvStruct2Multi(dat,comp);
[nttot,nCells,ncomptot] = size(datm);


if nCells == 1
    [varHL,Noise,QNRW]=NoiseHurtherLemmin(squeeze(datm(:,1,:)),transformationMatrix);
else    
    varHL = zeros(nCells,ncomptot);
    Noise = zeros(nCells,ncomptot);
    QNRW = zeros(nCells,1);
    for nr = 1:nCells
        transformationMatrixi = reshape(transformationMatrix(nr,:),4,4)';
        [varHL(nr,:),Noise(nr,:),QNRW(nr)]=NoiseHurtherLemmin(squeeze(datm(:,nr,:)),transformationMatrixi);
    end
end
goodCellsii = QNRW<w1w2xcorrthreshold;

end

%%%%%
function [varHL,Noise,QNRW]=NoiseHurtherLemmin(Raw,transformationMatrixi)
%Calculates noise from cross-spectra evaluations using Hurther and Lemmin (2001) algorithm
% from Hurther, D., and Lemmin, U. (2001). 
% "A correction method for turbulence measurements with a 3D acoustic doppler velocity profiler." 
% Journal of Atmospheric and Oceanic Technology, 18(3), 446-458.


Udet = detrend(Raw,'constant');
Noise = zeros(1,4); % four element term with the part of the variance attibuted to noise for the four component (U, V, W1, W2) 
%
W1W2=Udet(:,3).*Udet(:,4); % covariance of redundant vertical velocity components

varUdet = var(Udet); % variance of ra

% noise in vertical components as difference between variance and covariance of vertical components
Noise(3:4)= varUdet(3:4)-mean(W1W2);
QNRW=mean(Noise(3:4))/mean(W1W2)*100; % noise ratio for vertical signals

A = sum(transformationMatrixi.^2,2); %
angle1 = A(1)/A(3);
angle2 = A(2)/A(4);
    
% calculates noise in u and lateral - Voulgaris and Trowbridge
Noise(1)=angle1*mean(Noise(3:4));
Noise(2)=angle2*mean(Noise(3:4));
  
varHL = varUdet-Noise;

end