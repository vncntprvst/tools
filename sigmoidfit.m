function [fitresult, gof] = sigmoidfit(narssdbins, probaresp)
%CREATEFIT(NARSSDBINS,PROBARESP)
%  Create a fit.
%
%  Data for 'sigmoid' fit:
%      X Input : narssdbins
%      Y Output: probaresp
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  MATLAB auto-generated on 15-Nov-2012 00:26:53 by VP


%% Fit: 'sigmoid'.
[xData, yData] = prepareCurveData( narssdbins, probaresp );

% Set up fittype and options.
ft = fittype( '1./(1+exp(-(x/2-a)/(10)))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( ft );
opts.Display = 'Off';
opts.Lower = -Inf;
opts.StartPoint = 0.251083857976031;
opts.Upper = Inf;

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
% figure( 'Name', 'sigmoid' );
% h = plot( fitresult, xData, yData );
% legend( h, 'probaresp vs. narssdbins', 'sigmoid', 'Location', 'NorthEast' );
% % Label axes
% xlabel( 'narssdbins' );
% ylabel( 'probaresp' );
% grid on


