function B = subSetValues(B,val)
% set values for buttons, editable fields and other GUI input fields
% called from MITT and ClassifyArrayGUI
% modified May 25 2016 to work with setARMAopts by BM

Bname = subFieldnames(val);
%set display filter parameters from BC
nBtot = length(Bname);
% get faQC parameters from figure
for nB = 1:nBtot
    Bnamei = Bname{nB};
    if isfield(B,Bnamei);
        eval(['Bstyle = get(B.',Bname{nB},',''Style'');']);
        switch Bstyle
            case 'edit'
                eval(['set(B.',Bnamei,',''String'',num2str(val.',Bnamei,'));']);
            case 'text'
                eval(['set(B.',Bnamei,',''String'',val.',Bnamei,'));']);
            case 'checkbox'
                eval(['set(B.',Bnamei,',''Value'',val.',Bnamei,');']);
            case 'listbox'
                eval(['set(B.',Bnamei,',''Value'',val.',Bnamei,');']);
            case 'popupmenu'
                eval(['set(B.',Bnamei,',''Value'',val.',Bnamei,');']);
        end
    end
end
