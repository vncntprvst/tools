%%File converter: Converts the daq file to a bin file
function[]=fconvert(filename)
%filename=input('Which file do you want to convert? \n','s');

%Load DAQ file and information
info=daqread([filename '.daq'],'info');
[data time]=daqread([filename '.daq']);

%Create the file
binfile=[filename '.bin'];
fid=fopen(binfile,'a');

fwrite(fid,data','float'); %writes data to the file
fclose(fid);

end