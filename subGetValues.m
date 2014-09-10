function val = subGetValues(B,val)
% get values from buttons, editable fields and other GUI input fields
% called from MITT and ClassifyArrayGUI

Bname = subFieldnames(B);
%set display filter parameters from BC
nBtot = length(Bname);
% get faQC parameters from figure
for nB = 1:nBtot
    eval(['Bstyle = get(B.',Bname{nB},',''Style'');']);
    switch Bstyle
        case 'edit'
            eval(['val.',Bname{nB},' = str2num(get(B.',Bname{nB},',''String''));']);
        case 'text'
            eval(['val.',Bname{nB},' = get(B.',Bname{nB},',''String'');']);
        case 'checkbox'
            eval(['val.',Bname{nB},' = get(B.',Bname{nB},',''Value'');']);
        case 'listbox'
            eval(['val.',Bname{nB},' = get(B.',Bname{nB},',''Value'');']);
        case 'popupmenu'
            eval(['val.',Bname{nB},' = get(B.',Bname{nB},',''Value'');']);
    end
end

