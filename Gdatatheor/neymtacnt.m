function [cnt, pd] = neymtacnt(mean_count,a,max_count)
% neymtacnt: function which returns the probability density for the 
% the Neyman type A distribution with mean mean_count and multiplication
% parameter a. If called without output arguments, the distribution is
% plotted.
%
%	[cnt, pd] = neymtacnt(mean_count,a,max_count)
%
%	where 
%	  mean_count = mean count value
%	  a = multiplication parameter
%	  maxcount = maximal count taken into account
%
% The return parameters are:
%	cnt = vector of spike counts.
%	pd = corresponding probability distribution.
%
% The recursive formula for the distribution of spike count is derived
% for example in Saleh and Teich (Proc. IEEE, 70, pp. 229-245, 1982).
%

if ( nargin ~= 3 )
  disp(' ');
  disp('usage: neymtacnt(mean_count,a,max_count) ');
  disp('       for more information type "help neymtacnt" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
cnt = (0:1:max_count)';
pd = zeros(max_count+1,1);
gk = gamma((1:max_count));

pd(1,1) = exp( (mean_count/a)*(exp(-a)-1) );
for k = 2:max_count+1
  ps = 0;
  for l = 1:k-1
    ps = ps + (a^(l-1)/gk(l))*pd(k-l,1);
  end; 
  pd(k,1) = (mean_count*exp(-a)/(k-1))*ps;
end;

if ( nargout == 0 )  
%looks for the figure 'countprob', otherwise creates it
%and sets it to current
  fig_name = 'countprob';
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
  plot(cnt,pd,'g');
  if (new_fig == 1)
    titt = sprintf('Neyman type A distribution');
    title(titt);
  end;
  xlabel('spike count');
  ylabel('probability');
  clear cnt, pd;
end;


