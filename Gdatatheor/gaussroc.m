function [pd, pf] = gaussroc(mean0,std0,mean1,std1)
% gaussroc: function which returns the receiver-operating
% characteristic curve describing the ability of an ideal observer to 
% discriminate between the two gaussian distributions of given means
% and variances. If called without output arguments, the receiver
% operating characteristic curve and the probability densities of the
% two Gaussian distributions are plotted. 
%
%	[pd, pf] = gaussroc(mean0,std0,mean1,std1)
%
%	where 
%	  mean0 = mean value of the first (null) probability distribution
%	  std0 = corresponding standard deviation
%	  mean1 = mean value of the second probability distribution
%	  std1 = corresponding standard deviation
%
% The return parameters are:
%	pd = probability of correct detection
%	pf = probability of false-alarm
%
%N.B. This function does not test for theneed of multiple
%discrimination thresholds (such as for two gaussian distributions
%having identical means but different variances). 
%

if ( nargin ~= 4 )
  disp(' ');
  disp('usage: gaussroc(mean0,std0,mean1,std1) ');
  disp('       for more information type "help gaussroc" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
dx0 = mean0/(10*std0);
x0 = [mean0-3*std0:dx0:mean0+3*std0]';
pd0 = sqrt(2*pi)^(-1)*exp(-(x0-mean0).^2./(2*std0));
dx1 = mean1/(10*std1);
x1 = [mean1-3*std1:dx1:mean1+3*std1]';
pd1 = sqrt(2*pi)^(-1)*exp(-(x1-mean1).^2./(2*std1));

pf = [0:0.025:1];
r = std0/std1;
d = (mean1-mean0)/std1;
alpha = sqrt(2)*erfinv(1-2*pf);
beta = r*alpha-d;
pd = 1 - 0.5*(1+erf(beta/sqrt(2)));

if ( nargout == 0) 
%looks if the figure 'gaussroc' already exists, otherwise creates one
%and sets it to current
  fig_name = 'gaussroc';
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
  plot(x0,pd0,'g',x1,pd1,'y');
  title('Gaussian distributions');
  xlabel('independent variable [arbitrary]');
  ylabel('probability density');
  clear pf pd;
end;

