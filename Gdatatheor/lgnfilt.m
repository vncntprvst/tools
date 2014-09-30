function [filt,tvect] = lgnfilt(tau,fc,tstep,n)
% lgnfilt: function which return the transfer function of a LGN
% thalamic relay cell, as derived by D. Dong and J. Atick (Network:
% Comput. Neur. Syst., 6, pp. 159-178, 1995). The low-frequency
% behavior is modified as explained in Gabbiani (Network:
% Comput. Neur. Syst., 7, pp. 61-85, 1996) to take into account the
% low-frequency cut-off in the power spectrum of natural stimuli. If
% called without output parameters, the transfer function and its
% frequency characteristics are plotted. 
%  
%   [filt,tvect] = lgnfilt(tau,fc,tstep)
%
%   where
%	tau = time-constant of decay for stimulus ensemble (in msec)
%	fc = cut-off frequency of the filter (in Hz)
%	tstep = sampling time step (in msec)
%
%   The values of tau and fc matching experimental data (see Dong and
%   Atick, op. cit.) are fc = 5.5 Hz and tau = 1500 msec.
%   
%   The return parameters are:
%
%   	tvect = vector of time sample points 
%	filt = filter values at the sample points
%
%   An additional parameter can be passed:
%
%   [filt,tvect] = lgnfilt(tau,fc,tstep,n)
%   
%   where n is the number of points for the filter. The default value
%   is n = 512.

if ( (nargin ~= 3) & (nargin ~= 4) ) 
  disp(' ');
  disp('usage1: lgnfilt(tau,fc,tstep)');
  disp(' ');
  disp('usage2: lgnfilt(tau,fc,tstep,n)');
  disp(' ');
  disp('       for more information type "help lgnfilt" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

if ( nargin == 3 )
  n = 512;
end;

%sampling frequency in Hz
Fs = 1/(tstep*1e-3);
tau = tau*1e-3; %in sec
omega_c = 2*pi*fc; %circular frequency
beta = sqrt(omega_c^2 + (tau)^(-2));

%computes the filter with norm  normalized to 1
tvect = [0:tstep:n-1];
tvect_s = tvect*1e-3; %in sec
filt = tvect_s.*(tau + 0.5*(1-tau*beta)*tvect_s).*exp(-beta*tvect_s);
filt = filt/norm(filt);% normalizes to a norm of 1
nfft = 2^nextpow2(tvect);

%Frequency response
freq = [0:Fs/nfft:Fs/2];
filtfft = fft(filt,nfft);

fs = size(filtfft);

%modulus and phase
m = abs(filtfft);
p = angle(filtfft);

ms = size(m);
ps = size(p);

if ( nargout == 0 )
%looks if the figure 'lgnfilt' already exists, otherwise creates one
%and sets it to current
  fig_name = 'firfilt';
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

%sets decorations and plots the time domain filter and its frequency
%response 
  subplot(2,2,1);
  plot(tvect,filt,'y');
  grid;
  title('LGN filter in the time domain');
  xlabel('Time lag [msec]');
  ylabel('Filter value [normalized units');
  subplot(2,2,2);
  plot(freq,(180/pi)*unwrap(p(1,1:(nfft/2)+1)));
  grid;
  title('Filter phase');
  xlabel('Frequency [Hz]');
  ylabel('Phase [deg]');
  subplot(2,2,3);
  plot(freq,m(1,1:(nfft/2)+1).^2,'y');
  grid;
  title('Frequency response');
  xlabel('Frequency [Hz]');
  ylabel('Power [linear units]');
  subplot(2,2,4);
  plot(freq,20*log10(m(1,1:(nfft/2)+1)),'y');
  grid;
  title('Frequency response');
  xlabel('Frequency [Hz]');
  ylabel('Magnitude [dB]');
  clear tvect filt;
end;