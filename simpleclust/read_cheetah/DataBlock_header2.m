function [header index] = DataBlock_header2(fid, index)

[header.Type index] = myread(fid, 1, 'int16', index);
[header.UpperTS index] = myread(fid, 1, 'uint16', index); %Time stame 8 bits of 40
[header.LowerTS index] = myread(fid, 1, 'uint', index); %Time stamp 32 bits of 40
[header.Chan index] = myread(fid, 1, 'int16', index);
[header.Unit index] = myread(fid, 1, 'int16', index);
[header.NumWavfrm index] = myread(fid, 1, 'int16', index);

[header.NumWordsNWavfrm index] = myread(fid, 1, 'int16', index);