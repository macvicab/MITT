function Structure = ConvCSV2Struct(fname,planeorganization)
% fname must be a text file with two header lines
% plane organization = 1 if the output is in plane organization
% = 0 if output is in element by element organization
% first header line has the fieldnames for each column of data
% second header line has the format (e.g. %f and %s for floating point and script formats, respectively)

% open file
fileID = fopen(fname);

% read headerlines 
rawhead = textscan(fileID, '%s %*[^\n]',2);

% create cell matrix of field names from first headerline
fieldnames = textscan(char(rawhead{1}(1)),'%s','Delimiter',',');

% create string of formatting from second headerline
fieldformat = char(rawhead{1}(2));
bad = strfind(fieldformat,',');
fieldformat(bad) = ' ';

% read the data
rawdat = textscan(fileID,fieldformat,'Delimiter',',');

% close file
fclose(fileID);

% find number of parameters
nptot = length(rawdat);
nftot = length(rawdat{1});
% convert to element by element organization if planeorganization = 0
if planeorganization
    % for each parameter create a structure array field in Config
    for np = 1:nptot
        eval(['Structure.',char(fieldnames{1}(np)),'=rawdat{',num2str(np),'};']);
    end
else
    Structure = struct;
    for nf = 1:nftot
        % for each parameter create a structure array field in Config
        for np = 1:nptot
            if iscell(rawdat{np}) 
                eval(['Structure(',num2str(nf),').',char(fieldnames{1}(np)),'=char(rawdat{',num2str(np),'}(',num2str(nf),'));'])
            else
                eval(['Structure(',num2str(nf),').',char(fieldnames{1}(np)),'=rawdat{',num2str(np),'}(',num2str(nf),');'])
            end
        end
    end
end


end 
