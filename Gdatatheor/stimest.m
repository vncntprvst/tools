function [h, tvect, cf] = stimest(stim,spk,tstep,n,nfft,window,noverlap,dflag)
% stimest: function which estimates the stimulus from the spike train
% using the Wiener-Kolmogorov algorithm. It returns the Wiener-Kolmogorov
% filter and the coding fraction which measures the accuracy of the 
% stimulus estimation from the spike train. If the function is called
% without output arguments, the time domain and frequency domain
% characteristics of the estimation are plotted. 
%  
%   [h, tvect, cf] = stimest(stim,spk,tstep)
%
%   where
%       stim = random stimulus
%	spk = spike train
%	tstep = sampling time step (in msec)
%   
%   The function may also be called as follows:
%
%   [h, tvect, cf] = stimest(stim,spk,tstep,n)
%
%   The parameter n determines the subsampling rate (every n-th point is
%   conserved). A reduction in the sampling rate allows  to eliminate 
%   high frequency components outside of the range encoded by the cell and
%   thus eliminates unnecessary noise. 
%
%   Supplementary parameters can be passed by calling:
%
%   [h, tvect, cf] = stimest(stim,spk,tstep,n,nfft,window,noverlap,dflag)
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
%	h = Wiener-Kolmogorov filter
%	cf = coding fraction
%


if ( (nargin ~= 8) & (nargin ~= 3)  & (nargin ~= 4) )
  disp(' ');
  disp('usage1: stimest(stim,spk,tstep) ');
  disp(' ');
  disp('usage2: stimest(stim,spk,tstep,n) ');
  disp(' ');
  disp('usage3: stimest(stim,spk,tstep,n,nfft,window,noverlap,dflag) ');
  disp(' ');
  disp('       for more information type "help psautostim" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;


%These parameters are setup with the following simulations in mind:
%a sampling rate of 0.5 msec and a 
%simulation time of 100 sec so that a good estimate of the power
%spectrum is obtained at a resolution of approx. 1Hz. 
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
  stim = stim1;
  clear stim1;
  l_stim = length(stim);
  spk1 = zeros(l_stim,1);
  for k=1:l_stim
    spk1(k,1) = sum(spk((k-1)*n+1:k*n,1));
  end;   
  spk = spk1;
  clear spk1;
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
spk = spk(:); %converts to column vector if necessary
spk = spk*Fs; %converts to units of spikes/sec
l_spk = length(spk);
s_spk = sum(spk);
m_spk = s_spk/l_spk;
spk = spk - m_spk;

disp(' ');
disp('computing the power spectrum of the stimulus...');
[Pstim,f] = psd(stim,nfft,Fs,window,noverlap,dflag);

disp('computing the power spectrum of the spike train...');
[Pspk,f] = psd(spk,nfft,Fs,window,noverlap,dflag);

disp('cross-correlating the spike train with the stimulus...');
[Pstimspk, f] = csd(spk,stim,nfft,Fs,window,noverlap,dflag);


%computes the coherence and signal-to-noise ratio
disp('computing the coherence and signal-to-noise ratio...');
Cstimspk = abs(Pstimspk).^2./(Pstim.*Pspk);
SNRstimspk = 1./(1 - Cstimspk);

%Estimates the transfer function 
disp('computing the Wiener-Kolmogorov filter...');
Tfft_short = Pstimspk./Pspk;

Tfft_long = zeros(nfft,1);
Tfft_long(1:nfft/2+1,1) = Tfft_short(1:nfft/2+1,1);
for k = 2:nfft/2
  Tfft_long(nfft+2-k,1) = conj(Tfft_short(k,1));
end;

T = real(ifft(Tfft_long,nfft))*nfft; %Fourier transform with negative phase

%unwraps the filter
tvect = -(nfft/2)*tstep:tstep:(nfft/2)*tstep;
h = zeros(nfft+1,1);
h(1:nfft/2,1) = T(nfft/2+1:nfft,1);
h(nfft/2+1:nfft+1,1) = T(1:nfft/2+1,1);

disp('computing the coding fraction...');
stimest = fftfilt(h*tstep_s,spk);
%compensates for the delay in the filter
err2 = mean( (stimest(nfft+1:length(stimest)) - ...
              stim(nfft/2+1:length(stim)-nfft/2)).^2);

errmax = std(stim);
cf = 1 - sqrt(err2)/errmax;

if ( nargout == 0 )
%looks if the figure 'stimest1' already exists, otherwise creates one
%and sets it to current
  fig_name = 'stimest1';
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
  plot(f,Cstimspk,'y');
  title('Coherence function');
  xlabel('Frequency [Hz]');
  ylabel('Coherence value [normalized units]');
  subplot(2,2,2);
  plot(f,SNRstimspk,'y');
  title('Signal-to-Noise Ratio');
  xlabel('Frequency [Hz]');
  ylabel('Signal-to-Noise Ratio [arbitrary units]');
  subplot(2,2,3);
  plot(tvect,h);
  title('Filter');
  xlabel('Time [msec]');
  ylabel('Filter value [nA]');
  subplot(2,2,4);
  plot((0:tstep:500*tstep),stim(nfft/2+1:nfft/2+1+500),'y',...
       (0:tstep:500*tstep),stimest(nfft+1:nfft+1+500),'g');
  title('Stimulus estimation');
  xlabel('Time [msec]');
  ylabel('Current [nA]');

  xlim = get(gca,'XLim');
  xtot = xlim(1,2)-xlim(1,1);
  ylim = get(gca,'YLim');
  ytot = ylim(1,2) - ylim(1,1);

  xl1 = [ xlim(1,1)+0.15*xtot xlim(1,1)+0.25*xtot ];
  yl1 = [ ylim(1,1)+0.1*ytot ylim(1,1)+0.1*ytot ];
  yl2 = [ ylim(1,1)+0.05*ytot ylim(1,1)+0.05*ytot ];
  line(xl1,yl1,'Color','y');
  line(xl1,yl2,'Color','g');
  sttext = sprintf('stimulus');
  stesttext = sprintf('est. stimulus');
  cftext = sprintf('cf = %.2g',cf);
  text(xl1(1,2)+0.1*xtot,yl1(1,2),sttext);
  text(xl1(1,2)+0.1*xtot,yl2(1,2),stesttext);
  text(xlim(1,2)-0.3*xtot,ylim(1,2)-0.1*ytot,cftext);
  clear h tvect cf;
end;
