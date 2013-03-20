% export SpikeHound (.daq) files to text file, for import to Spike2

dir='E:\Data\Recordings\Sixx\SHrec\';
file='S115L4A6_12871';

datainfo=daqread([dir file],'info');
data=daqread([dir file]);
% export trigger channel into _t file as a structure with title 'trigger',
% then remove channel

% write only data channel for export to spike2
csvwrite('S115L4A6_12871.csv',data);

% can one call the spike2 import script?
% C:\Spike7\scripts\IMPTEXT.S2S
