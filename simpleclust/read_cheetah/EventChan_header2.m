function [header index] = EventChan_header2(fid, index)

[header.Name index] = myread(fid, 32, 'char', index);
[header.Chan index] = myread(fid, 1, 'int', index);
[header.comment index] = myread(fid, 128, 'char', index);
[header.Pad index] = myread(fid, 33, 'int', index);