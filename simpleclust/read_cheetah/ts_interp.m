function ts = ts_interp(timestamp,samples_per_record)

% 
% [timestamp_out] = TS_INTERP(timestamp_in,samples_per_record)
%
%   Interpolates <samples_per_record> times between the points
%     in the variable <timestamp_in>.
%
%

s = size(timestamp);

if s(1) > s(2)
    timestamp = double(timestamp);
else
    timestamp = double(timestamp)';
end

n_records = numel(timestamp);

step_size = mean(diff(timestamp(1:1000)))./samples_per_record;

rate_matrix = ones(n_records,samples_per_record-1).*step_size;

rate_matrix = [timestamp rate_matrix];

ts_matrix = cumsum(rate_matrix,2);

ts = reshape(ts_matrix',numel(ts_matrix),1);
