function val = subGetValues(B,val)
% get values from buttons, editable fields and other GUI input fields
% called from MITT and ClassifyArrayGUI
% modified May 25 2016 to work with setARMAopts by BM

checkval = isempty(val);
Bname = subFieldnames(B);
%set display filter parameters from BC
nBtot = length(Bname);
% get faQC parameters from figure
for nB = 1:nBtot
    Bnamei = Bname{nB};
    if isfield(val,Bnamei)||checkval;
        eval(['Bstyle = get(B.',Bnamei,',''Style'');']);
        switch Bstyle
            case 'edit'
                eval(['temp = get(B.',Bnamei,',''String'');']);
                % if a str2num transformation is not empty it is a number
                if ~isempty(str2num(temp))
                    eval(['val.',Bnamei,' = str2num(temp);']);
                % elseif it is not empty without a transformation it is a string
                elseif ~isempty(temp)
                    eval(['val.',Bnamei,' = get(B.',Bnamei,',''String'');']);
                % else it is just empty
                else
                    eval(['val.',Bnamei,' = [];']);
                end
            case 'text'
                eval(['val.',Bnamei,' = get(B.',Bnamei,',''String'');']);
            case 'checkbox'
                eval(['val.',Bnamei,' = get(B.',Bnamei,',''Value'');']);
            case 'listbox'
                eval(['val.',Bnamei,' = get(B.',Bnamei,',''Value'');']);
            case 'popupmenu'
                eval(['val.',Bnamei,' = get(B.',Bnamei,',''Value'');']);
        end
    end
end

