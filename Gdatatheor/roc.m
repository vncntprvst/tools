function [pd, pf] = roc(cnt,prob1,prob2)
% roc: function which returns the receiver-operating characteristics and
% the error rate characterizing the ability of an ideal observer to
% discriminate between the two distributions.
%
%	[pd, pf] = roc(cnt,prob1,prob2)
%
%	where 
%	  cnt = vector of spike counts for both distributions
%	  prob1 = first (null) probability distribution of counts
%	  prob2 = second probability distribution of counts
%
% The return parameters are:
%	pd = probability of correct detection
%	pf = probability of false-alarm
%
% N.B. No attempts are made to detect the need for multiple thresholds
% and the null distribution is assumed to be displaced to lower values
% of the independent variable.
%

if ( nargin ~= 3 )
  disp(' ');
  disp('usage: roc(cnt,prob1,prob2) ');
  disp('       for more information type "help roc" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
prob1 = prob1(:);
prob2 = prob2(:);
n_cnt = length(cnt);
pd = zeros(n_cnt+2,1);
pf = zeros(n_cnt+2,1);
err = zeros(n_cnt+2,1);

for k = 1:n_cnt
  pf(k+1,1) = sum(prob1(k:n_cnt,1));
  pd(k+1,1) = sum(prob2(k:n_cnt,1));
end;

pf(1,1) = 1;
pd(1,1) = 1;

err = 0.5*(pf + 1 - pd);

if ( nargout == 0 ) 
%looks for the figure 'roc', otherwise creates it
%and sets it to current
  fig_name = 'roc';
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

%sets decorations and plots the isi distribution
  subplot(2,1,1);
  plot(pf,pd,'g',(0:0.1:1),(0:0.1:1),'y--');
  titt = sprintf('ROC curve');
  title(titt);
  xlabel('probability of false alarm');
  ylabel('probability of correct detection');
  subplot(2,1,2);
  plot(pf,err,'g',(0:0.1:1),ones(11,1)*0.5,'y--');
  title('Error rate');
  xlabel('probability of false alarm');
  ylabel('probability of error');
  clear pf pd;
end;

