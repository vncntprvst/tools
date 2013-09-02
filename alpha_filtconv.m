function  filtvals = alpha_filtconv(vector,sigma)
% 8/2013 - VP. Based on formula from Abbott and Dayan 
% Neural Encoding I: Firing Rates and Spike Statistics
% Using alpha function to create causal kernel:
% firing rate at time t only depends on spikes fired before t

if nargin < 2 || isempty(sigma)
     sigma = 5;
end

size = 6*sigma;
x = linspace(-size / 2, size / 2, size);
alpha = 1/sigma;
alphaFilter = ((alpha^2)*x) .* exp(-alpha*x);
alphaFilter(alphaFilter<0)=0; 
alphaFilter = alphaFilter / sum (alphaFilter); % normalize
% rectify shift 

filtvals = conv (vector, alphaFilter, 'same');