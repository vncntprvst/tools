function  filtvals = gauss_filtconv(vector,sigma)
% Smoothing with simple gaussian filtering, using limited kernel that lacks
% denominator (such as 1/(sqrt(2*pi)*fixedsigma) in front of the exponential)
% Results are typically identical, though. 
% For conversion to spike rate, see spike_density

if nargin < 2 || isempty(sigma)
     sigma = 5;
end

size = 6*sigma;
x = linspace(-size / 2, size / 2, size);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter(1:length(x)/2)=0; 
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

filtvals = conv (vector, gaussFilter, 'same');