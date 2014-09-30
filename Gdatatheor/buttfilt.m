function [filt,tvect] = buttfilt(fc,n,tstep)
% buttfilt: function which returns the time domain response of a
% Butterworth low-pass filter. If the function is called without 
% output parameters, the time domain response of the 
% filter as well as its frequency domain characteristics are plotted.
%  
%   [filt,tvect] = buttfilt(fc,n,tstep)
%
%   where
%	fc = cut-off frequency of the filter (in Hz)
%       n = order of the filter 
%	tstep = sampling time step (in msec)
%   
%   The return parameters are:
%
%   	tvect = vector of time sample points 
%	filt = filter values at the sample points
%

if ( nargin ~= 3) 
  disp(' ');
  disp('usage: buttfilt(fc,n,tstep)');
  disp(' ');
  disp('       for more information type "help buttfilt" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%sampling frequency in Hz
Fs = 1/(tstep*1e-3); 

%computes the filter and normalizes it
[b,a] = butter(n,(2*fc)/Fs);
h = freqz(b,a);
nfac = sum(h.*conj(h))/length(h);
b = b/sqrt(nfac);
a = a;

%computes the impulse response
[filt,tvect] = impz(b,a,[],Fs);

%Fourier transforms
[h,freq] = freqz(b,a,1025,Fs);
%modulus and phase
m =  abs(h);
p = angle(h);

if ( nargout == 0 )
%looks for the figure 'firfilt', otherwise creates it
%and sets it to current
  fig_name = 'buttfilt';
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
  subplot(2,2,1);
  plot(tvect*1e3,filt,'y');
  grid;
  title('Low-Pass filter in the time domain');
  xlabel('Time lag [msec]');
  ylabel('Filter value [arbitrary units');
  subplot(2,2,2);
  plot(freq,(180/pi)*unwrap(p));
  grid;
  title('Filter phase');
  xlabel('Frequency [Hz]');
  ylabel('Phase [deg]');
  subplot(2,2,3);
  plot(freq,m.^2,'y');
  grid;
  title('Frequency response');
  xlabel('Frequency [Hz]');
  ylabel('Power [linear units]');
  subplot(2,2,4);
  plot(freq,20*log10(m),'y');
  grid;
  title('Frequency response');
  xlabel('Frequency [Hz]');
  ylabel('Magnitude [dB]');
  clear tvect filt;
end;

