function  filtvals = gauss_filtconv(vector,sigma)
% Smoothing with simple gaussian filtering, using limited kernel that lacks
% denominator (such as 1/(sqrt(2*pi)*fixedsigma) in front of the exponential)
% -> simply have kernel with much wider area under curve.
% Results after filtering are typically similar, though. 
% For conversion to spike rate, see spike_density

if nargin < 2 || isempty(sigma)
     sigma = 5;
end

size = 6*sigma;
x = linspace(-size / 2, size / 2, size);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

filtvals = conv (vector, gaussFilter, 'same');