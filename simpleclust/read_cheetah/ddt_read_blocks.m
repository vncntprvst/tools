function [data,data_info] = ddt_read_blocks(filename, offset, nsamples, downsample_rate)

fid = fopen(filename, 'r');
plex_vers = fread(fid, 1, 'int');
data_offset = fread(fid, 1, 'int');
samp_rate = fread(fid, 1, 'double');
num_chan = fread(fid, 1, 'int');
year = fread(fid, 1, 'int');
month = fread(fid, 1, 'int');
day = fread(fid, 1, 'int');
hour = fread(fid, 1, 'int');
min = fread(fid, 1, 'int');
sec = fread(fid, 1, 'int');

preamp_gain = fread(fid, 1, 'int');

comment = fread(fid, 128, 'char');
char(comment(find(comment)))';

bit_per_samp = fread(fid, 1, 'uchar');
chan_gain = fread(fid, 64, 'uchar');

data_info.chan_gain=chan_gain;

fread(fid, 1, 'int8');  % missed placed byte
max_mag = fread(fid, 1, 'int16');

pad = fread(fid, 188, 'uchar')'; %one byte less because of missed placed


data_info.samp_rate=samp_rate;
data_info.num_chan=num_chan;
data_info.year=year;
data_info.month=month;
data_info.day=day;
data_info.hour=hour;
data_info.min=min;
data_info.preamp_gain=preamp_gain;
data_info.comment=char(comment(find(comment)))';





begin = ftell(fid);
fseek(fid, 0, 'eof');
last = ftell(fid);
sizedata = (last - begin);

data_info.sizedata =sizedata ;

data_chans = find(chan_gain < 255);
data_info.data_chans=data_chans;

down_samp = downsample_rate;
dt = down_samp/samp_rate;
%time = time*samp_rate/down_samp*num_chan;
%diff(time);



% data = zeros((chns), (time));
% size(data)

%skip1 = sizedata./num_chan;

%for chan_num = 1:4

fseek(fid, data_offset+(offset*2*num_chan), 'bof'); % need factor 2 here because seek is in bytes

skip = 0; %2*num_chan*down_samp;

%tmp = fread(fid, 16*4e4*60, 'int16', 0);%2*16);%2*16*16);
tmp = fread(fid, nsamples*num_chan, 'int16', 0);%2*16);%2*16*16); % read in int16 here so no factor 2 needed

nsamples= floor(numel(tmp)/num_chan);


data = reshape(tmp(1:nsamples*num_chan),num_chan,nsamples)';

nsamples=size(data,1);
data_info.nsamples=nsamples;
data_info.T= (offset+[0:nsamples-1])./samp_rate;

data_info.duration  = max(data_info.T);

%{
for chan_num = 1:num_chan
data(:,chan_num) = tmp(chan_num:num_chan:end);
    %data(:,chan_num) = tmp(chan_num:16:end);
end
%}

%end

%data = reshape(tmp, num_chan, []);
ncol = size(data,2);

%data = data ./ repmat(chan_gain(1:num_chan), 1, ncol);
%data = data * 5000 / (.5 * 2^bit_per_samp * preamp_gain);

ftell(fid);
fclose(fid);

