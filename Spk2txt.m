function Spk2txt(filename,chn)
%test file
%filename='H30L6A0_15050';

if nargin<2
    %specify which channel was exported from Spike2
    chn=6;
end

%load data from file
try
    load([filename '_Ch' num2str(chn,'%d')],'-mat');
catch wrongdir
    dir='E:\Data\WaveSorter\';
    load([dir filename '_Ch' num2str(chn,'%d')],'-mat');
end

%copy data into new variable named data
eval(['data = ' filename '_Ch' num2str(chn,'%d')]);

%remove old variable from memory
vars=who;
evalin('base',['clear ',cell2mat(vars(~cellfun('isempty',regexp(who,filename))))]);
clear vars;

%adjust voltage traces toward positiveness and, if needed, resample
data.values=data.values+ceil(abs(min(min(data.values)))*100)/100;
rsvals=data.values; %no resampling. For resampling to keep 25 values: (resample((data.values)',25,size(data.values,2)))';

%build matrix of data to export. column 1: electrode number, column 2: time stamp, column 3: voltage value 
% datexport=[zeros(size(data.times))...
%     round(data.times*50000)...
%     rsvals]; 

%print header for WaveSorter
txtfilename = [filename '.txt'];
fid = fopen(txtfilename, 'w');
fprintf(fid, '%d\t%d\tet\n',size(rsvals,1),size(rsvals,2));

eno = 0;
data.times = round(data.times.*50000);

for a = 1:size(rsvals,1)
        newrow = [];
    for b = 1:size(rsvals,2)
        if (b == size(rsvals,2))
        newrow = [newrow sprintf('%7.7f',rsvals(a,b))];  
        else
        newrow = [newrow sprintf('%7.7f\t',rsvals(a,b))];  
        end
    end
    if a == size(rsvals,1)
    fprintf(fid, ['%d\t%d\t' newrow],eno,data.times(a));
    else
    fprintf(fid, ['%d\t%d\t' newrow '\n'],eno,data.times(a));    
    end
end

fclose(fid);

%print data proper
%dlmwrite(txtfilename, datexport, '-append', 'delimiter', '\t', 'precision', 8)
end