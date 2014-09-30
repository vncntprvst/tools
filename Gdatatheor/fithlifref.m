function [meanrate] = fithlifref(thres,C,R,ref,values)
% fithlifref: function which returns the theoretical firing frequency of
% a leaky integrate and fire neuron with refractory period for 
% different values of a constant input current. If no output arguments
% are passed, the function plots the mean firing rate as a function of
% input current. The parameters are:
%
%	[meanrate] = fithlifref(thres,C,R,ref,values)
%
%	thres = threshold (mV)
%	C = capacity of the model neuron (nF)
%	R = resistance of the model neuron (MOhms)
%	ref = refractory period (msec)
%	values = vector of constant current  values (nA)
%  
% The return parameter meanrate is the mean firing rate vector
% corresponding to the input vector of constant current values.
%
if ( nargin ~= 5 )
  disp(' ');
  disp('usage: fithlifref(thres,c,r,ref,values) ');
  disp('       for more information type "help fithlifref" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

values = values(:);
ppsize = length(values);
meanrate = zeros(ppsize,1);
I_rh = thres/R;

for k=1:ppsize
  if ( values(k,1) <= I_rh )
    meanrate(k,1) = 0;
  else                    %converts from kHz to Hz
    meanrate(k,1) = 1e3/(ref - R*C*log(1-(thres/(values(k,1)*R))));
  end;
end;


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
