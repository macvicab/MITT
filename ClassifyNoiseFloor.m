function [goodCellsii,QSis] = ClassifyNoiseFloor(dat,InertialSlopeThreshold,Hz,zpos,samplingVolume);
% classifies GoodCells based on slope of inertial subrange

% calculate regression slope within the inertial subrange
QSis=Noise53trend(dat,Hz,zpos,samplingVolume);

% compare with user defined threshold (bad cells have relatively flat
% slopes)
goodCellsii = QSis<=InertialSlopeThreshold;

end

%%%%%
function QSis = Noise53trend(dat,Hz,zpos,samplingVolume)
% Calculates slope of power spectra in inertial subrange based on limits
% calculated from Stapleton, K.R. and Huntley, D.A., 1995. 
% Seabed stress determinations using the inertial dissipation method and 
% the turbulent kinetic energy method. Earth Surface Processes and Landforms, 20(9): 807-815.

B=[log(.1) -5/3] ;
% calculate mean
Ubar=abs(mean(dat));
% detrend data
Spk=detrend(dat);

%% find limits of the inertial subrange
LowFreqLim = Ubar./zpos;%Equation 11a Stapleton & Huntley (1995)
UpFreqLim = 2.3*Ubar./(2*pi()*samplingVolume/1000);% %Equation 11b Stapleton & Huntley (1995)

[nttot,nCells] = size(dat);

QSis = zeros(1,nCells);

for nC = 1:nCells
    %% calculate slope
    % calculate periodogram
    [PowPx,fx]=periodogram(Spk(:,nC),[],[],Hz);
    %[PowPx(:,n),fx(:,n)]=pwelch(Spk(:,n),[],[],[], Config.Hz);

    RegVals= fx < UpFreqLim(nC) & fx > LowFreqLim(nC);

    LogX=log(fx(RegVals));
    LogY=log(PowPx(RegVals));
    if ~isempty(LogX) && ~isempty(LogY)
        notinf = isfinite(LogX) & isfinite(LogY);
        beta=nlinfit(LogX(notinf),LogY(notinf),@SpecReg2,B); %regression function
        QSis(nC)=beta(2);
    end
end
end

%%%%%
function yhat2 = SpecReg2(B,LogX)
yhat2 = B(1) +LogX.*(B(2));
end


