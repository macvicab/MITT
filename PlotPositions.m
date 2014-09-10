function PlotPositions(Config,outname)

natot = length(Config);
colline = getColline(natot);

load(outname,'GUIControl')

% create mesh for water and bed surfaces
figure
mesh(GUIControl.twoD.xchannel,GUIControl.twoD.ychannel,GUIControl.twoD.waterElevation,'EdgeColor','g','FaceColor','b','FaceAlpha',0.5)
hold on
mesh(GUIControl.twoD.xchannel,GUIControl.twoD.ychannel,GUIControl.twoD.bedElevation,'EdgeColor',[0.7 0.7 0.7],'FaceColor',[0.3 0.3 0.3],'FaceAlpha',0.5)
xlabel('xpos')
ylabel('ypos')
zlabel('zpos')

% add sampling positions
for na = 1:natot
    line(Config{na}.xpos,Config{na}.ypos,Config{na}.zposGlobal,'LineStyle','none','Marker','*','Color',colline(na,:));    
end

end

%%%%%
function colline = getColline(ntot)
% to create a color matrix with ntot number of different colors based on a matlab standard colormap
% create unique color values for each file
cmap = flipud(jet);%jet;% % jet coloring, could also be used with bone, autumn, etc.
njettot = length(cmap);
ngooc = floor(1:njettot/ntot:njettot);

colline = cmap(ngooc,:);

end