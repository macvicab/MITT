function Dataanames = subFieldnames(Dataa)
% to extract field names from substructures within a structure

% get structure fieldnames
Dataanames = fieldnames(Dataa);
% initialize loop to list substructure fieldnames (e.g. Vel.x)
ndntot = length(Dataanames);
% set up logical array to keep track of fields with substructures
subfieldsY = zeros(ndntot,1);
Dataanamesi = [];
% for each fieldname in Dataa
for ndn=1:ndntot
    % check if if has substructure fieldnames and save
     eval(['subfieldsY(ndn) = isstruct(Dataa.',Dataanames{ndn},');']);
     % if it has substructure fields
     if subfieldsY(ndn)
         % get names of substructure fields
         eval(['Dataanamesi = fieldnames(Dataa.',Dataanames{ndn},');']);
         % get the number of substructure fieldnames
         ndnitot = length(Dataanamesi);
         % add
         subfieldsY = [subfieldsY;zeros(ndnitot,1)];
         for ndni = 1:ndnitot
             % get subfieldnames
             ndniname = [Dataanames{ndn},'.',Dataanamesi{ndni}];
             % add to list of fieldnames
             Dataanames = [Dataanames;ndniname];
         end
     end
end
% erase fields with subfields from the list of fieldnames
Dataanames(subfieldsY>0) = [];
end
