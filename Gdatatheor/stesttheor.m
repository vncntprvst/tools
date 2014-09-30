function [mf, cf] = stesttheor(std,fc,tau,minf,maxf,df)
% stesttheor: function which returns the coding fraction as a function
% of the mean firing rate for two half-wave rectified Poisson neurons
% which low-pass filter their input with an exponential filter. If
% called without output parameters, the coding fraction is plotted as
% a function of the mean firing rate. 
%
%	[mf, cf] = stesttheor(std,fc,tau,minf,maxf,df)
%
%	where 
%	  std = standard deviation of the white noise current (nA)
%	  fc = cut-off frequency (Hz)
%	  tau = exponential low-pass filter time constant (msec)
%	  minf = minimum firing frequency for a single neuron (Hz)
%	  maxf = maximum firing frequency for a single neuron (Hz)
%	  df = increment step in firing frequency

%
% The return parameters are:
%
%	mf = vector of mean firing rates.
%	cf = coding fraction. 
%
% The formulas used are derived in Gabbiani and Koch (Neur. Comput.,
% 8, pp. 44-66, 1996) and Gabbiani (Network: Comput. in Neur. Syst.,
% 7, pp. 61-85, 1996).
%
if ( nargin ~= 6 )
  disp(' ');
  disp('usage: stesttheor(std,fc,tau,minf,maxf,df) ');
  disp('       for more information type "help stesttheor" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
tau = tau*1e-3; %converts from msec to sec

mf = [minf:df:maxf]';
cf = zeros(1,length(mf));

for i=1:length(mf)
  gamma = (pi^2/2)*(tau*2*mf(i))/atan(tau*2*pi*fc);
  sqrtg = sqrt(1+gamma);
  epsilon2 = (std^2/(2*pi*fc))*(2*pi*fc -...
	        (1/tau)*(gamma/sqrtg)*atan(tau*2*pi*fc/sqrtg));
  cf(i) = 1 - sqrt(epsilon2)/std;
end;

if ( nargout == 0 )
%looks for the figure 'stestf', otherwise creates it
%and sets it to current
  fig_name = 'stestf';
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
    h_fig = figure('Name',fig_name);
  end;

%sets decorations and plots the isi distribution
  plot(mf,cf,'g');
  title('Fraction of encoded stimulus vs. mean firing rate');
  xlabel('mean firing rate per neuron [Hz]');
  ylabel('coding fraction');
  clear mf, cf;
end;

