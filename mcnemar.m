function [pval,chisquare]=mcnemar(varargin)
%MCNEMAR: Permorm McNemar's chi square on a 2x2 matrix
% In statistics, McNemar's test is a non-parametric method used on nominal
% data to determine whether the row and column marginal frequencies are
% equal. It is named after Q. McNemar, who introduced it in 1947. It is
% applied to 2x2 contingency tables with a dichotomous trait with matched
% pairs of subjects.
%
% Syntax: 	mcnemar(x,alpha)
%      
%     Inputs:
%           X - 2x2 data matrix 
%           ALPHA (default 0.05) 
%     Outputs:
%           - Chi Square critical value
%           - Chi square value
%           - p-value
%           - Power
%   Example:
% In the following example, a researcher attempts to determine if a drug
% has an effect on a particular disease. 
%
%                      Drug
%                  +         -
%             --------------------
%         +   |   101   |   59   |
% Placebo     |-------------------           
%         -   |   121   |   33   |
%             --------------------
%                                       
%
%   x=[101 59; 121 33];
%
%   Calling on Matlab the function: 
%             mcnemar(x)
%
%   Answer is:
%
% Critical value at 95% fiducial level = 3.8415
% McNemar chi-square (with Yates'es correction) = 20.672222    p = 0.000005
% alpha = 0.0500  Zb = 2.7566  Power (2-tails) = 0.0058
%
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
%
% To cite this file, this would be an appropriate format:
% Cardillo G. (2007) McNemar test: perform the McNemar test on a 2x2
% matrix. 
% http://www.mathworks.com/matlabcentral/fileexchange/15472

%Input error handling
args=cell(varargin);
nu=numel(args);
if isempty(nu)
    error('Warning: Matrix of data is missed...')
elseif nu>2
    error('Warning: Max two input data are required')
end
default.values = {[],0.05};
default.values(1:nu) = args;
[x alpha] = deal(default.values{:});
%check if x is a 2x2 matrix
if ~isequal(size(x),[2 2])
    error('Input matrix must be a 2x2 matrix')
end
if ~all(isfinite(x(:))) || ~all(isnumeric(x(:)))
    error('Warning: all X values must be numeric and finite')
end
if ~isequal(x(:),round(x(:)))
    error('Warning: X data matrix values must be whole numbers')
end
if nu==2 %if necessary check alpha
    if ~isscalar(alpha) || ~isnumeric(alpha) || ~isfinite(alpha) || isempty(alpha)
        error('Warning: it is required a numeric, finite and scalar ALPHA value.');
    end
    if alpha <= 0 || alpha >= 1 %check if alpha is between 0 and 1
        error('Warning: ALPHA must be comprised between 0 and 1.')
    end
end
clear args default nu

%observed subjects with only one reaction
ob=diag(fliplr(x));

%perform chi-square whith Yates'es correction and 1 degree of freedom
chisquare=(abs(diff(ob))-1)^2/sum(ob);
pval=1-chi2cdf(chisquare,1);

%Compute power
% Za=abs(-realsqrt(2)*erfcinv(alpha));
% N=sum(x(:));
% p=min(ob./N);
% pp=max(ob(1)/ob(2),ob(2)/ob(1));
% num=abs(realsqrt(N*p*(pp-1)^2)-realsqrt(Za^2*(pp+1)));
% denom=realsqrt(pp+1-p*(pp-1)^2);
% Zb=num/denom;
% pwr=(1-0.5*erfc(-Zb/realsqrt(2)))*2;
% 
% %display results
% disp(['Critical value at ' num2str((1-alpha)*100) '% significance level = ' num2str(chi2inv(1-alpha,1))])
% fprintf('McNemar chi-square (with Yates'' correction) = %0.6f    p = %0.6f\n',chisquare,1-chi2cdf(chisquare,1))
% fprintf('alpha = %0.4f  Zb = %0.4f  Power (2-tails) = %0.4f\n',alpha,Zb,pwr)