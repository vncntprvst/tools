function  filtvals = fullgauss_filtconv(vector,sigma,causal)
% Smoothing with gaussian filtering
% Same as gauss_filtconv, but with added denominator in front of the 
% exponential. Result is identical to using normpdf. 
% vector is binned data (i.e., spike train)
% sigma is SD
% causal is for using causal kernel 
% For conversion to spike rate, see spike_density

if nargin < 2 || isempty(sigma)
     sigma = 5;
end

bin_size=1; %millisecond precision

ksize = 6*sigma;
x = linspace(-ksize / 2, ksize / 2, ksize+1);
gaussFilter = (1/(sqrt(2*pi)*sigma)) * exp(-x .^ 2 / (2 * sigma ^ 2)); % same as normpdf(x,0,sigma)
if causal
    gaussFilter(x<0)=0; % causal kernel
end
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

% if size(vector,1)>1
%     gaussFilter=repmat(gaussFilter,size(vector,1),1);
% end
filtvals = conv (vector, gaussFilter, 'same'); % filter vector data
