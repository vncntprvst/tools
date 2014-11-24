function [header index] = ContChan_header2(fid, index)

[header.Name index] = myread(fid, 32, 'char', index);
[header.Chan index] = myread(fid, 1, 'int', index);
[header.ADFreq index] = myread(fid, 1, 'int', index);
[header.Gain index] = myread(fid, 1, 'int', index);
[header.Enabled index] = myread(fid, 1, 'int', index);
[header.PreAmpGain index] = myread(fid, 1, 'int', index);
[header.SpikeChan index] = myread(fid, 1, 'int', index);

[header.comment index] = myread(fid, 128, 'char', index);
[header.Pad index] = myread(fid, 28, 'int', index);