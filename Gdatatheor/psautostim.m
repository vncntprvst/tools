function [f,Pxxn,tvect,Cxx] = psautostim(stim,tstep,nfft,window,noverlap,dflag)
% psautostim: function which returns the autocorrelation function and power
% spectral density of a random stimulus. If called without output
% parameters, the function plots the power spectrum and
% autocorrelation of the stimulus. 
%  
%   [f,Pxxn,tvect,Cxx] = psautostim(stim,tstep)
%
%   where
%       stim = random stimulus
%	tstep = sampling time step (in msec)
%   
%   The function may also be called as follows:
%
%   [f,Pxxn,tvect,Cxx] = psautostim(stim,tstep,nfft,window,noverlap,dflag)
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
%   	f = frequency samples
%	Pxxn = power spectral density at the frequency samples
%	tvect = time domain samples
%	Cxx = autocorrelation function at the time domain samples
%

if ( (nargin ~= 6) & (nargin ~= 2) )
  disp(' ');
  disp('usage1: psautostim(stim,tstep) ');
  disp(' ');
  disp('usage2: psautostim(stim,tstep,nfft,window,noverlap,dflag) ');
  disp(' ');
  disp('       for more information type "help psautostim" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;


%The parameters are setup with the following simulations in mind:
%a sampling rate of 0.5 msec and a 
%simulation time of 135 msec so that a reliable estimate of the power
%spectrum can usually be  obtained at a resolution of approx. 1Hz. 
if ( nargin == 2 )
  nfft = 2048;
  window = bartlett(nfft);
  noverlap = 1024;
  dflag = 'none';
end;

%computes the sampling frequency in Hz
tstep_s = tstep*1e-3;  %converts to sec
Fs = 1/tstep_s; %in Hz

%computes and subtracts the mean stimulus value
stim = stim(:); %converts to column vector if necessary
l_stim = length(stim);
s_stim = sum(stim);
m_stim = s_stim/l_stim;
stim = stim - m_stim;

[Pxx,f] = psd(stim,nfft,Fs,window,noverlap,dflag);

%converts to units of (nA/Hz)^2
Pxxn = Pxx * tstep_s;

%prepares the data to compute the autocorrelation
Pxxx = zeros(nfft,1);
Pxxx(1:nfft/2+1,1) = Pxx(1:nfft/2+1,1);
for k = 2:nfft/2
  Pxxx(nfft+2-k,1) = Pxx(k,1);
end;

%computes the autocorrelation function
Cxxx = fft(Pxxx,nfft);
%normalizes to get the usual definition of autocorrelation
Cxxx = Cxxx/nfft;

tvect = -(nfft/2)*tstep:tstep:(nfft/2)*tstep;
Cxx = zeros(nfft+1,1);
for k = 1:nfft/2
  Cxx(k,1) = real(Cxxx(nfft/2 + k,1));
end;
Cxx(nfft/2+1,1) = real(Cxxx(1,1));
for k = nfft/2+2:nfft+1
  Cxx(k,1) = real(Cxxx(k-nfft/2,1));
end;

if ( nargout == 0 )
%looks for the figure 'psautostim', otherwise creates it
%and sets it to current
  fig_name = 'psautostim';
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

%sets decorations and plots the power spectrum and autocorrelation
  subplot(2,1,1);
  plot(f,Pxxn,'y');
  title('Power spectrum of the stimulus');
  xlabel('Frequency [Hz]');
  ylabel('Power spectral density [nA^2/Hz]');
  subplot(2,1,2);
  plot(tvect,Cxx,'y');
  title('Autocorrelation function');
  xlabel('time lag [msec]');
  ylabel('Autocorrelation [nA^2]');
  clear f Pxxn tvect Cxx;
end;
