function MultiData = ConvStruct2Multi(StructData,comp);
% 4th level function to put components from a structured array into a
% multidimensional array

nctot = length(comp);

eval(['[nrowtot,ncoltot] = size(StructData.',comp{1},');']);

MultiData = zeros(nrowtot,ncoltot,nctot);

for nc = 1:nctot
    eval(['MultiData(:,:,nc) = StructData.',comp{nc},';']);
end

end