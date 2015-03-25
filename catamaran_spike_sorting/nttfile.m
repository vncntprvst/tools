classdef nttfile < handle
%nttfile: Class for reading Neuralynx NTT files.

% Written by Douglas M. Schwarz
% Version 2.0, 15 February 2012
	
	properties
		filename = '';
		fid = -1;
		isopen = false;
		bytes = 0;
		size = 0;
		true_size = 0;
		position = 0;
		header = '';
		record_length = 304;
		class = 'int16';
		num_samples = 32;
		header_length = 0;
	end
	
	properties (Constant)
		true_header_length = 16384;
	end
	
	properties (Hidden)
		block_size = 10000;
	end
	
	properties (Hidden, Constant)
		num_wires = 4;
		spike_samples = 32;
		bytes_per_sample = 2;
	end
	
	methods
		
		function obj = nttfile(filename,output_class,num_samples)
			%nttfile: Object representing an NTT file.
			%  ntt = nttfile(filename,class,num_samples);
			%  will open an NTT file by the name of <filename> and return
			%  an object representing it.  Subsequent read operations on
			%  the object will return spikes with a class of <class>
			%  (default = 'int16') and have <num_samples> samples (max. =
			%  default = 32).
			
			if nargin > 1 && ~isempty(output_class)
				obj.class = output_class;
			end
			
			if nargin > 2 && ~isempty(num_samples)
				obj.num_samples = num_samples;
			end
			
			% Open the file.
			obj.filename = filename;
			[obj.fid,message] = fopen(filename,'rb','ieee-le');
			obj.isopen = obj.fid ~= -1;
			if ~obj.isopen
				error(message)
			end
			
			% Get file size in bytes.
			fseek(obj.fid,0,'eof');
			obj.bytes = ftell(obj.fid);
			frewind(obj.fid);
			
			% Read the header (first 16384 bytes).
			obj.header_length = obj.true_header_length;
			obj.header = fread(obj.fid,[1 obj.true_header_length],'*char');
			obj.position = 0;
			
			% Parse record size (in bytes) from the header.  Defaults to
			% 304 bytes if not specified in header.
			record_size_cell = regexp(obj.header,'-RecordSize\s+(\d+)',...
				'tokens');
			if ~isempty(record_size_cell)
				obj.record_length = sscanf(record_size_cell{1}{1},'%f');
			end
			
			obj.size = (obj.bytes - obj.header_length)/obj.record_length;
			obj.true_size = obj.size;
		end
		
		function close(obj)
			%close: close the nttfile object.
			fclose(obj.fid);
			obj.isopen = false;
		end
		
		function seek(obj,position)
			%seek: Set the position of the next record to be read.
			%  seek(position)
			%  where <position> is an integer from 0 to <number of
			%  records>.
			if position > obj.size
				error('Attempt to seek past the end of the file.')
			end
			obj.position = position;
			pos = obj.record_length*position + obj.header_length;
			fseek(obj.fid,pos,'bof');
		end
		
% 		function true_seek(obj,position)
% 		end
		
		function position = tell(obj)
			%tell: Return the position of the next record to be read.
			position = obj.position;
		end
		
		function [spikes,timestamps] = read(obj,num_events)
			%read: Read spike waveforms and timestamps from an NTT file.
			%  ntt = nttfile(filename);
			%  spikes = ntt.read(count);
			%  reads <count> tetrodes of spike waveforms from <filename>.
			%  The reads are sequential and the nttfile object keeps track
			%  of the position in the file much like fread.
			%
			%  [spikes,timestamps] = ntt.read(...) also reads the
			%  timestamps for the events.
			
			% In order to conserve memory we will read the file in blocks.
			
			% Compute actual number of events to read.
			events_left = obj.size - obj.position;
			num_events = min(num_events,events_left);
			
			% Allocate spikes array.
			spikes = zeros(obj.num_samples,obj.num_wires,num_events,...
				obj.class);
			
			% Compute the number of blocks.
			num_blocks = ceil(num_events/obj.block_size);
			
			% Position file pointer at beginning of first block.
			% Number of bytes allocated to spike data in one record.
			spike_bytes = obj.num_wires * obj.spike_samples * ...
				obj.bytes_per_sample;
			fseek(obj.fid,obj.record_length - spike_bytes,'cof');
			
			% Compute number of bytes to skip between reads and precision
			% argument.
			skip_bytes = obj.record_length - ...
				obj.num_wires * obj.num_samples * obj.bytes_per_sample;
			precision = sprintf('%d*int16=>%s',...
				obj.num_samples*obj.num_wires,obj.class);
			
			i2 = 0;
			for block = 1:num_blocks
				this_block_size = min(obj.block_size,num_events - i2);
				this_block = fread(obj.fid,...
					[obj.num_samples*obj.num_wires this_block_size],...
					precision,skip_bytes);
				this_block = reshape(this_block,obj.num_wires,...
					obj.num_samples,[]);
				i1 = (block - 1)*obj.block_size + 1;
				i2 = min(block*obj.block_size,num_events);
				spikes(:,:,i1:i2) = permute(this_block,[2 1 3]);
			end
			
			if nargout > 1
				obj.seek(obj.position)
				item_bytes = 8; % uint64 = 8 bytes
				skip_bytes = obj.record_length - item_bytes;
				timestamps = fread(obj.fid,[1 num_events],'uint64',...
					skip_bytes);
			end
			
			% Set position.
			obj.seek(obj.position + num_events)
		end
		
		function timestamps = read_timestamps(obj,num_events)
			%read_timestamps: Read timestamps from an NTT file.
			%  ntt = nttfile(filename);
			%  timestamps = ntt.read_timestamps(count);
			%  reads <count> timestamps from <filename>.
			%  The reads are sequential and the nttfile object keeps track
			%  of the position in the file much like fread.
			
			% Compute actual number of events to read.
			events_left = obj.size - obj.position;
			num_events = min(num_events,events_left);
			
			% Seek to proper position and read time stamps.
			obj.seek(obj.position)
			item_bytes = 8; % uint64 = 8 bytes
			skip_bytes = obj.record_length - item_bytes;
			timestamps = fread(obj.fid,[1 num_events],'uint64',...
				skip_bytes);
			
			% Set position.
			obj.seek(obj.position + num_events)
		end
		
		function [spikes,timestamps] = read_distributed(obj,num_events,range)
			%read_distributed: Read spike waveforms distributed across NTT file.
			%
			%  ntt = nttfile(filename);
			%  [spikes,timestamps] = ntt.read_distributed(count,range);
			%
			%  reads <count> tetrodes of spike waveforms from <filename>
			%  distibuted across <range> of the whole data set.  <range> is
			%  a two-element vector and specifies the relative range of the
			%  data, e.g., the default is [0 1] and means to span the full
			%  set of data.  The number of events returned is limited by
			%  the number of events in the file.
			%
			%  The particular events read are grouped into segments, e.g.,
			%  10000 events are grouped into 100 segments of 100 events
			%  each.  You can specify the distribution by passing in a
			%  two-element vector for count = [<number of segments>,
			%  <events per segment>]
			%
			%  This function can be run any time and will not affect the
			%  current position of the file.
			
			% Default range is to span the whole data set.
			if nargin < 3
				range = [0 1];
			end
			
			% Compute number of events to be read for each segment.
			if numel(num_events) == 1
				% Only total number of events was specified.
				num_events = min(num_events,obj.size);
				num_segs = round(sqrt(num_events));
				evts = diff(round((num_events/num_segs)*(0:num_segs)));
			elseif numel(num_events) == 2
				% User specified [<number of blocks>,<events per block>].
				num_segs = num_events(1);
				evts = repmat(num_events(2),1,num_segs);
				num_events = prod(num_events);
			else
				error('num_events must have 1 or 2 elements.')
			end
			
			% Preallocate the spikes and timestamps arrays.
			spikes = zeros(obj.num_samples,obj.num_wires,num_events,...
				obj.class);
			timestamps = zeros(1,num_events);
			
			% Return the empty arrays if num_events is zero.
			if num_events == 0
				return
			end
			
			% Compute indices of the beginnings of segments.
			i_1 = round(range(1)*(obj.size - 1));
			i_n = round(range(2)*(obj.size - 1) - evts(end) + 1);
			ievts1 = round(linspace(i_1,i_n,num_segs));
			
			% Save the current position of the file.
			saved_position = obj.position;
			
			% Read one segment at a time.
			idx1 = 1;
			for seg = 1:num_segs
				idx2 = idx1 + evts(seg) - 1;
				obj.seek(ievts1(seg))
				[spikes(:,:,idx1:idx2),timestamps(idx1:idx2)] = ...
					obj.read(evts(seg));
				timestamps(idx1) = -timestamps(idx1);
				idx1 = idx2 + 1;
			end
			
			% Return file to original position.
			obj.seek(saved_position)
			
		end
		
		function limit_span(obj,time_span)
			% Reset header_length and size.
			obj.header_length = obj.true_header_length;
			obj.size = obj.true_size;
			
			% Find the position of the first spike that is greater than
			% or equal to min(span).
			t = min(time_span);
			obj.seek(0)
			t0 = obj.read_timestamps(1);
			if t <= t0
				pos1 = 0;
			else
				lo = 0;
				hi = obj.size - 1;
				while hi > lo + 1
					mid = floor((lo + hi)/2);
					obj.seek(mid)
					tmid = obj.read_timestamps(1);
					if t <= tmid
						hi = mid;
					else
						lo = mid;
					end
				end
				pos1 = hi;
			end
			
			% Find the position of the last spike that is less than or
			% equal to max(span).
			t = max(time_span);
			obj.seek(obj.size - 1)
			t_end = obj.read_timestamps(1);
			if t >= t_end
				pos2 = obj.size - 1;
			else
				lo = 0;
				hi = obj.size - 1;
				while hi > lo + 1
					mid = floor((lo + hi)/2);
					obj.seek(mid)
					tmid = obj.read_timestamps(1);
					if t >= tmid
						lo = mid;
					else
						hi = mid;
					end
				end
				pos2 = lo;
			end
			
			% Set new values.
			obj.header_length = obj.true_header_length + ...
				obj.record_length*pos1;
			obj.size = pos2 - pos1 + 1;
			obj.seek(0)
		end
		
		function unlimit_span(obj)
			% Reset header_length and size.
			obj.header_length = obj.true_header_length;
			obj.size = obj.true_size;
			obj.seek(0)
		end
		
	end
end
