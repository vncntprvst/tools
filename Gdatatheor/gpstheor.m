function [f,Pxxn,tvect,Cxx] = gpstheor(c,thres,i,ref,n,tstep,npoints)
% gpstheor: function which returns the theoretical power spectral density
% for a I&F neuron with random threshold  in response to a constant
% current pulse and the corresponding autocorrelation function. This
% is the power spectrum and autocorrelation function of a gamma
% distributed equilibrium renewal process.  If
% called without output arguments, the power spectrum and
% autocorrelation function are plotted. 
%
%	[f,Pxxn,tvect,Cxx] = gpstheor(c,thres,i,ref,n,tstep,npoints)
%
%	where 
%	  c = capacity of the model neuron (nF)
%	  thres = threshold (mV)
%	  i = constant input current (nA)
%	  ref = refractory period (msec)
%	  n = threshold gamma distribution order
%	  tstep = discretization time step (msec)
%	  npoints = resolution (number of sample points between 0 and the
%                   Nyquist frequency)
%
% Remark: the resolution obtained by using the function psautospk is nfft/2 
% (i.e., npoints = 1024 if the default value for nfft = 2048 is used).
%
%	The return parameters are:
%
%	  f = frequency samples
%	  Pxxn = power spectral density at the frequency samples
%	  tvect = time domain samples
%	  Cxx = autocorrelation function at the time domain samples
%
% The formulas for the power spectrum are derived, e.g., in Franklin and Bair
% (SIAM J. App. Math., 55, pp. 1074-1093, 1995).
% 

if ( nargin ~= 7 )
  disp(' ');
  disp('usage: gpstheor(c,thres,i,ref,n,tstep,npoints) ');
  disp('       for more information type "help gpstheor" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
tstep_s = tstep*1e-3; %converts to sec
f_nyquist = 1/(2*tstep_s); %in Hz
mean_isi0 = max(0,ref*1e-3); %converts to sec
mean_isi1 = (c*thres/i)*1e-3; %in sec
mean_isi = mean_isi0 + mean_isi1; %mean isi, including the ref. period
mean_ff = 1/mean_isi; 
f = (0:f_nyquist/npoints:f_nyquist)';
w = 2*pi*f; %circular frequency

b = mean_isi1/n;
rho = 1./sqrt(1+(b*w).^2);
phi = atan2(-b*w,1);
psi = -mean_isi0*w;
mu = rho.^n;
lambda = n*phi + psi;

num = mu.*(cos(lambda).*(1-mu.*cos(lambda))-mu.*sin(lambda).^2);
den = (1-mu.*cos(lambda)).^2 + (mu.*sin(lambda)).^2;

Pxxn = mean_ff*(1 + 2*num./den);

%sets by hand the correct limit for f = 0 Hz.
Pxxn(1,1) = mean_ff*(mean_isi1^2/(n*mean_isi^2)); 

%computes the autocorrelation function by Fourier transforming the 
%power spectral density and taking into account the various normalization
%factors.
nfft = 2*npoints;
Pxx = Pxxn/tstep_s; %density per grid point

%prepares the data to compute the autocorrelation
Pxxx = zeros(nfft,1);
Pxxx(1:nfft/2+1,1) = Pxx(1:nfft/2+1,1);
for k = 2:nfft/2
  Pxxx(nfft+2-k,1) = Pxx(k,1);
end;

%computes the autocorrelation function
Cxxx = fft(Pxxx,nfft);
%normalizes to get the usual definition
Cxxx = Cxxx/nfft;

tvect = -(nfft/2)*tstep:tstep:(nfft/2)*tstep;
tvect = tvect';
Cxx = zeros(nfft+1,1);
for k = 1:nfft/2
  Cxx(k,1) = real(Cxxx(nfft/2 + k,1));
end;
Cxx(nfft/2+1,1) = real(Cxxx(1,1));
for k = nfft/2+2:nfft+1
  Cxx(k,1) = real(Cxxx(k-nfft/2,1));
end;

if ( nargout == 0 )
%looks for the figure 'psautospk', otherwise creates it
%and sets it to current
  fig_name = 'psautospk';
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

%sets decorations and plots the theoretical power spectrum and autocorrelation
  subplot(2,1,1);
  plot(f,Pxxn,'g');
  title('Power spectrum of the spike train');
  xlabel('Frequency [Hz]');
  ylabel('Power spectral density [(spk/sec)^2/Hz]');
  subplot(2,1,2);
  plot(tvect,Cxx,'g');
  title('Autocorrelation function');
  xlabel('time lag [msec]');
  ylabel('Autocorrelation [(spk/sec)^2]');
  clear f Pxxn tvect Cxx;
end;
