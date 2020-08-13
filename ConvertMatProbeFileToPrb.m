function ConvertMatProbeFileToPrb(probeFileName)
probeLayout=load(probeFileName);
flnm=fieldnames(probeLayout); probeLayout=probeLayout.(flnm{:});

% remove file format from name
if any(regexpi(probeFileName,'.mat$')); probeFileName=probeFileName(1:end-4); end

% number of channels
probeParams.numChannels=numel({probeLayout.Electrode});

% number of channels
probeParams.numShank=numel(unique([probeLayout.Shank]));

% pad size
if any(regexpi(probeFileName,'^CNT')) %Cambridge Neurotech probe
    probeParams.surfaceDim=[15 11]; % Dimensions of the recording pad (height by width in micrometers).
elseif any(regexpi(probeFileName,'^NN'))
    probeParams.surfaceDim=[16 10];
else
    probeParams.surfaceDim=[];
end

% merging space
probeParams.maxSite=4; % Max number of sites to consider for merging

% get mapping and geometry
flnm=fieldnames(probeLayout);
for fldNum=1:numel(flnm)
    probeParams.(flnm{fldNum})=[probeLayout.(flnm{fldNum})];
end

% unconnected / bad channels
if ~isfield(probeParams,'connected')
    probeParams.connected=ones(size([probeParams.Electrode]));
end

% adjust number of effective channels
probeParams.numChannels=sum(probeParams.connected);

%geometry:
%         Location of each site in micrometers. The first column corresponds
%         to the width dimension and the second column corresponds to the depth
%         dimension (parallel to the probe shank).


if isfield(probeLayout,'x_geom')
    xcoords=[probeLayout.x_geom];
    ycoords=[probeLayout.y_geom];
else
    xcoords = zeros(1,probeParams.numChannels);
    ycoords = 200 * ones(1,probeParams.numChannels);
    groups=unique(probeParams.shanks);
    for elGroup=1:length(groups)
        if isnan(groups(elGroup)) || groups(elGroup)==0
            continue;
        end
        groupIdx=find(probeParams.shanks==groups(elGroup));
        xcoords(groupIdx(2:2:end))=20;
        xcoords(groupIdx)=xcoords(groupIdx)+(0:length(groupIdx)-1);
        ycoords(groupIdx)=...
            ycoords(groupIdx)*(elGroup-1);
        ycoords(groupIdx(round(end/2)+1:end))=...
            ycoords(groupIdx(round(end/2)+1:end))+20;
    end
end
probeParams.geometry=[xcoords;ycoords]';

probeParams=jsonencode(probeParams);
probeParams=regexprep(probeParams,'(?<={)"','\r\n\t"');
probeParams=regexprep(probeParams,'(?<=,)"','\r\n\t"');
probeParams=regexprep(probeParams,'(?<="):',':\t');
probeParams=regexprep(probeParams,'(?<=,)[','\r\n\t\t\t\t[');
probeParams=regexprep(probeParams,'(?<=])}','\r\n\}');
fid  = fopen([probeFileName '.json'],'w');
fprintf(fid,'%s',probeParams);
fclose(fid);

% to read output file:
% probeParams = fileread('probename.json');
% probeParams = jsondecode(probeParams)

    
    
