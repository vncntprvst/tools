function [meanrate] = fithifref(thres,c,ref,values)
% fithifref: function which returns the theoretical firing frequency of
% an integrate and fire neuron with refractory period for 
% different values of a constant input current. If called without
% output arguments, the mean rate is plotted as a function of the
% input current. The parameters are:
%
%	[meanrate] = fithifref(thres,c,ref,values)
%
%	thres = threshold (mV)
%	c = capacity of the model neuron (nF)
%	ref = refractory period (msec)
%	values = vector of constant current  values (nA)
%  
% The return parameter meanrate is the mean firing rate vector
% corresponding to the input vector of constant current values.
%

if ( nargin ~= 4 )
  disp(' ');
  disp('usage: fithifref(thres,c,ref,values) ');
  disp('       for more information type "help fithifref" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

values = values(:);
meanrate = 1e3*values./(c*thres+ref*values);
%converts from kHz to Hz

if ( nargout == 0 )
%looks for the figure 'ficurve', otherwise creates it
%and sets it to current
  fig_name = 'ficurve';
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
  plot(values,meanrate,'y--',values,meanrate,'go');
  title('F-I curve');
  xlabel('current [nA]');
  ylabel('mean firing frequency [Hz]');
  clear meanrate;
end;
