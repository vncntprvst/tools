function [h, tvect] = wiener1(stim,spk,tstep,n,nfft,window,noverlap,dflag)
% wiener1: function which estimates the transfer function between
% stimulus and spike train by cross-correlation. If the function is
% called with no output arguments, the properties of the Wiener kernel
% in the time domain and frequency domain are plotted. 
%  
%   [h, tvect] = wiener1(stim,spk,tstep)
%
%   where
%       stim = random stimulus
%	spk = spike train
%	tstep = sampling time step (in msec)
%   
%   The function may also be called as follows:
%
%   [h, tvect] = wiener1(stim,spk,tstep,n)
%
%   The parameter n determines the subsampling rate (every n-th point is
%   conserved). A reduction in the sampling rate allows  to eliminate 
%   high frequency components outside of the range encoded by the cell and
%   thus eliminates unnecessary noise. 
%
%   Supplementary parameters can be passed by calling:
%
%   [h, tvect] = wiener1(stim,spk,tstep,n,nfft,window,noverlap,dflag)
%
%   where the additional parameters control the power spectrum calculation
%   (see matlab psd function) and replace the default values:
%
%       nfft = number of points used for a single fft operation (default: 2048)
%       window = window function (default: bartlett(nfft))
%       noverlap = number of overlapping points per segment (default: 1024)
%       dflag = detrending option flag (default:'none')
%
%   The return parameters are:
%
%   	tvect = vector of time values
%	h = estimate of the transfer function
%

if ( (nargin ~= 8) & (nargin ~= 3) & (nargin ~= 4) )
  disp(' ');
  disp('usage1: wiener1(stim,spk,tstep) ');
  disp(' ');
  disp('usage2: wiener1(stim,spk,tstep,n)');
  disp(' ');
  disp('usage3: wiener1(stim,spk,tstep,n,nfft,window,noverlap,dflag) ');
  disp(' ');
  disp('       for more information type "help wiener1" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;


%The parameters are setup with the following simulations in mind:
%a sampling rate of 0.5 msec and a 
%simulation time of 135 msec so that a reliable estimate of the power
%spectrum can usually be obtained at a resolution of approx. 1Hz. 
if ( nargin < 7 )
  nfft = 2048;
  window = bartlett(nfft);
  noverlap = 1024;
  dflag = 'none';
end;

if ( nargin == 3 )
  n = 1;
end;

stim = stim(:); %converts to column vector if necessary

if ( n > 1) %we need to resample
  disp(' ');
  disp('resampling the data...');
  stim1 = resample(stim,1,n);
  l_stim1 = length(stim1);
  spk1 = zeros(l_stim1,1);
  for k=1:l_stim1
    spk1(k,1) = sum(spk((k-1)*n+1:k*n,1));
  end;   
  clear stim spk;
  stim = stim1;
  spk = spk1;
  clear stim1 spk1;
  tstep = n*tstep;
end;

%computes the sampling frequency in Hz
tstep_s = tstep*1e-3;  %converts to sec
Fs = 1/tstep_s; %in Hz

%computes and subtracts the mean stimulus value
l_stim = length(stim);
s_stim = sum(stim);
m_stim = s_stim/l_stim;
stim = stim - m_stim;

%computes and subtracts the mean firing rate
spk = spk(:); %convertes to column vector if necessary
spk = spk*Fs; %converts to units of spikes/sec
l_spk = length(spk);
s_spk = sum(spk);
m_spk = s_spk/l_spk;
spk = spk - m_spk;

%Estimates the transfer function 
disp(' ');
disp('computing the transfer function...');
[Tfft_short, f] = tfe(stim,spk,nfft,Fs,window,noverlap,dflag);
Tmag = abs(Tfft_short);   
Tphase = phase(Tfft_short');

Tfft_long = zeros(nfft,1);
Tfft_long(1:nfft/2+1,1) = Tfft_short(1:nfft/2+1,1);
for k = 2:nfft/2
  Tfft_long(nfft+2-k,1) = conj(Tfft_short(k,1));
end;

T = real(ifft(Tfft_long,nfft))*nfft;

%unwraps the filter
tvect = -(nfft/2)*tstep:tstep:(nfft/2)*tstep;
h = zeros(nfft+1,1);
h(1:nfft/2,1) = T(nfft/2+1:nfft,1);
h(nfft/2+1:nfft+1,1) = T(1:nfft/2+1,1);

if ( nargout == 0 ) 
%looks for the figure 'wiener', otherwise creates it
%and sets it to current
  fig_name = 'wiener';
  Figures = get(0,'Chil');
  new_fig = 1;
  for i=1:length(Figures)
    if strcmp(get(Figures(i),'Type'),'figure')
      if strcmp(get(Figures(i),'Name'),fig_name)
        new_fig = 0;
        h_fig = Figures(i);
        set(0,'CurrentFigure',h_fig);
      end;
    end;
  end;
  if (new_fig == 1)
    h_fig = figure('Name',fig_name,'Position',[296 420 560 800]);
  end;

%sets decorations and plots the coherence
  subplot(2,2,1);
  plot(f,20*log10(Tmag),'y');
  title('Filter magnitude');
  xlabel('Frequency [Hz]');
  ylabel('Filter magnitude [dB]');
  subplot(2,2,2);
  plot(f,Tmag.^2,'y');
  title('Filter power');
  xlabel('Frequency [Hz]');
  ylabel('Power [(1/(nA sec^2)^2/Hz]');
  subplot(2,2,3);
  plot(f,(180/pi)*unwrap(Tphase));
  title('Filter phase');
  xlabel('Frequency [Hz]');
  ylabel('Phase [deg]');
  subplot(2,2,4);
  plot(tvect,h);
  title('Impulse response');
  xlabel('Time [msec]');
  ylabel('Filter value [1/(nA sec^2)]');
  clear h tvect;
end;
