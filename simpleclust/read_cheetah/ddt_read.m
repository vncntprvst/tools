function data = ddt_read(filename, chns, time, downsample_rate)

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

fread(fid, 1, 'int8');  % missed placed byte
max_mag = fread(fid, 1, 'int16');

pad = fread(fid, 188, 'uchar')'; %one byte less because of missed placed

begin = ftell(fid);
fseek(fid, 0, 'eof');
last = ftell(fid);
sizedata = (last - begin)/2;

data_chans = find(chan_gain < 255);

down_samp = downsample_rate;
dt = down_samp/samp_rate;
time = time*samp_rate/down_samp*num_chan;
diff(time);

% data = zeros(length(chns), diff(time));
% size(data)

fseek(fid, 432 + time(1)*2, 'bof');

skip = 2*num_chan*down_samp;

tmp = fread(fid, 'int16', skip);

data = reshape(tmp, num_chan, []);
ncol = size(data,2);

data = data ./ repmat(chan_gain(1:num_chan), 1, ncol);
data = data * 5000 / (.5 * 2^bit_per_samp * preamp_gain);

ftell(fid)
fclose(fid);

