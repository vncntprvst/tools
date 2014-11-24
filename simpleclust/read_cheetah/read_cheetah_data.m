function [data] = read_cheetah_data(varargin)

%
% [data] = READ_CHEETAH_DATA(fname,ds_factor)
%
%   Josh Siegle - January 15, 2009 (Modified February 2, 2009)
%   MIT Department of Brain and Cognitive Sciences
%
%   Read in Neuralynx Cheetah (v5.1.0) data from file.
%
%   Inputs: fname = file name (string)
%           ds_factor = factor by which to downsample CSC data (integer)
%               [default value is 1, indicating no downsampling]
%
%       Examples:
%           Down-sample factor     Sample Hz (approx.)
%                   1                  30303
%                   2                  15152
%                   4                   7576
%                   8                   3788
%                   16                  1894
%                   32                   947
%                   64                   473
%
%
%   Outputs: data = structure with fields:
%      [for CSC files]
%       .ts = time stamp
%       .channel_num = channel number
%       .sample_Hz = sample frequency
%       .samples = data samples
%
%      [for NTT files]
%       .ts = spike times
%       .waveforms = spike waveforms [4 x 32 x nspikes]
%
%      [for NEV files]
%       .header = file header
%       .ts = event timestamp
%       .eventID = Cheetah event ID
%       .TTLval = event TTL value]
%       .event_string = 128-character string associated with each event
%
%      [for NVT files]
%       .header = file header
%       .ts = timestamp
%       .xval = x-position
%       .yval = y-position
%       .angle = heading angle
%
%   File dependencies: ts_interp.m
%

ncs_subset=0;

if nargin < 2
    fname = varargin{1};
    ds_factor = 1;
else
    if nargin < 3
        fname = varargin{1};
        ds_factor = varargin{2};
    else   % specified start and end samples for ncs file
        load_subset_from= varargin{3};
        load_subset_to= varargin{4};
        ncs_subset=1;
        if ~strcmp(ftype,'ncs')
            error('start and end samples were defined but a filetype other than .ncs was passed');
        end
    end;
end

% Step 1: identify file type
fname=strrep(fname,'//','/');

L = length(fname);
ftype = lower(fname(L-2:L));

if ~strcmp(ftype,'ncs') && ~strcmp(ftype,'nev') ...
        && ~strcmp(ftype,'ntt') && ~strcmp(ftype,'nst') ...
        && ~strcmp(ftype,'nvt') && ~strcmp(ftype,'nse')
    error('read_cheetah_data: This is an invalid file type.')
end

% Step 1: read in data from header
%disp(fname);
fid = fopen(fname);
a = fread(fid,771,'char');
header = char(a');
data.header = header;
%k = strfind(header,'ADBitVolts ');
k = strfind(header,'ADBitVolts');

bytes_per_header = 2^14; %default for all Neuralynx files

switch ftype
    
    case 'ncs' % Continuously sampled channel
        
        %data.bit_volts = str2num(header(k+10:k+22));
        data.bit_volts = str2num(header(k+11:k+24));
        
        bytes_per_block = 1044;
        
        if ncs_subset % read subset of file
            
            %implement here
            
        else % read whole file
            % read in data
            status = fseek(fid,bytes_per_header+8+4+4+4,'bof');
            data.samples = fread(fid,inf,'512*int16=>int16',bytes_per_block-512*2);
            
            % read in timestamps
            status = fseek(fid,bytes_per_header,'bof');
            data.ts = fread(fid,inf,'int64',bytes_per_block-8)*1e-6;
            
            % check for invalid samples
            status = fseek(fid,bytes_per_header+8+4+4,'bof');
            numValid = fread(fid,inf,'int32=>int32',bytes_per_block-4);
            if any(numValid(:)~=512)
                warning('Not all samples valid')
            end
            clear numValid
            
        end
        % read in sample frequency
        status = fseek(fid,bytes_per_header+8+4,'bof');
        data.sample_Hz = fread(fid,1,'uint32');
        
        interp_factor = 512./ds_factor;
        data.sample_Hz = data.sample_Hz / ds_factor;
        
        L = numel(data.ts);
        
        % interpolated time points
        data.tsI = ts_interp(data.ts',interp_factor);
        
        if max(abs(diff(data.ts)))>1
            warning('>1s jump in timestamps, tsI interpolation likely corrupted!!!');
        end;
        
        % downsampled data, scaled to the proper range
        data.samples = double(downsample(data.samples,ds_factor));
        
        
    case 'ntt'
        
        bytes_per_block = 304;
        offset = 8+4+4+4*8;
        
        %read in data
        status = fseek(fid,bytes_per_header,'bof');
        data.ts = fread(fid,inf,'*uint64',bytes_per_block-8);
        
        status = fseek(fid,bytes_per_header+offset,'bof');
        data.waveforms = reshape(fread(fid,inf,'128*int16=>int16',bytes_per_block-128*2),4,[]);
        
        nspikes = length(data.ts);
        
        data.waveforms = reshape(data.waveforms,4,32,nspikes);
        
        % convert to double and convert to seconds
        data.ts = double(data.ts)./1e6;
        data.waveforms = double(data.waveforms);
        
        
    case 'nst'
        
        bytes_per_block = 176;
        offset = 8+4+4+4*8;
        
        %read in data
        status = fseek(fid,bytes_per_header,'bof');
        data.ts = fread(fid,inf,'*uint64',bytes_per_block-8);
        
        status = fseek(fid,bytes_per_header+offset,'bof');
        data.waveforms = reshape(fread(fid,inf,'64*int16=>int16',bytes_per_block-64*2),2,[]);
        
        nspikes = length(data.ts);
        
        data.waveforms = reshape(data.waveforms,2,32,nspikes);
        
        % convert to double and convert to seconds
        data.ts = double(data.ts)./1e6;
        data.waveforms = double(data.waveforms);
        
        
        
    case 'nse'
        
        bytes_per_block = 112;
        offset = 8+4+4+4*8;
        
        %read in data
        status = fseek(fid,bytes_per_header,'bof');
        data.ts = fread(fid,inf,'*uint64',bytes_per_block-8);
        
        status = fseek(fid,bytes_per_header+offset,'bof');
        data.waveforms = reshape(fread(fid,inf,'32*int16=>int16',bytes_per_block-32*2),1,[]);
        
        nspikes = length(data.ts);
        
        data.waveforms = reshape(data.waveforms,1,32,nspikes);
        
        % convert to double and convert to seconds
        data.ts = double(data.ts)./1e6;
        data.waveforms = double(data.waveforms);
        
    case 'nev' % Event record
        
        bytes_per_block = 184;
        
        status = fseek(fid,bytes_per_header+6,'bof');
        
        data.ts = fread(fid,inf,'int64',bytes_per_block-8)*1e-6;
        
        status = fseek(fid,bytes_per_header+6+8,'bof');
        
        data.eventID = fread(fid,inf,'uint16',bytes_per_block-2);
        
        status = fseek(fid,bytes_per_header+6+8+2,'bof');
        
        data.TTLval = fread(fid,inf,'uint16',bytes_per_block-2);
        
        % read in character strings for all events
        for n = 1:numel(data.ts)
            status = fseek(fid,bytes_per_header+bytes_per_block*(n-1)+6+8+42,'bof');
            
            readstr = fread(fid,128,'char');
            
            data.event_string{n} = char(readstr');
        end
        
    case 'nvt' % Video tracker file
        
        bytes_per_block = 2+2+2+8+400*4+2+4+4+4+50*4;
        
        status = fseek(fid,bytes_per_header,'bof');
        % data.sxstx = fread(fid,inf,'uint16',bytes_per_block-2);
        
        status = fseek(fid,bytes_per_header+2,'bof');
        %data.systemID = fread(fid,inf,'uint16',bytes_per_block-2);
        
        status = fseek(fid,bytes_per_header+2+2,'bof');
        %data.recSize = fread(fid,inf,'uint16',bytes_per_block-2);
        
        status = fseek(fid,bytes_per_header+2+2+2,'bof');
        data.ts = fread(fid,inf,'int64',bytes_per_block-8)*1e-6;
        
        status = fseek(fid,bytes_per_header+2+2+2+8,'bof');
        %data.bitfield = fread(fid,inf,'400*uint32=>uint32',bytes_per_block-400*4);
        
        status = fseek(fid,bytes_per_header+2+2+2+8+400*4+2,'bof');
        data.xval = fread(fid,inf,'uint32',bytes_per_block-4);
        
        status = fseek(fid,bytes_per_header+2+2+2+8+400*4+2+4,'bof');
        data.yval = fread(fid,inf,'uint32',bytes_per_block-4);
        
        status = fseek(fid,bytes_per_header+2+2+2+8+400*4+2+4+4,'bof');
        data.angle = fread(fid,inf,'uint32',bytes_per_block-4);
        
end

% close file
status = fclose(fid);
