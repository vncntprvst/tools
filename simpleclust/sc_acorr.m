function [t, c] = sc_acorr(a, lag, N)
% function [l,c] =  sc_acorr(a,lag,N);
% trying it the easy way... may be too slow to work out, but the code was
% already written...

% defaults - need to figure out how to make specifiable
binwidth = 1;
win = [-50 50];
t = win(1):binwidth:win(2);

crosscorr_result = zeros(size(t));
for s = 1:length(a)
    x = a(a(:) >= a(s) + win(1) & a(:) <= a(s) + win(end));
    y = x - a(s);
    if ~isempty(x)
        n = histc(y(y~=0),t);
        if ~isempty(n)
            crosscorr_result = crosscorr_result + reshape(n,1,length(crosscorr_result));
        end
    end
end
t = t + binwidth/2;
c = crosscorr_result ./ (sum(crosscorr_result));

% l=linspace(0,lag,N);
% 
% d=diff(a);
% 
% h=histc(d,l);
% 
% c=h./(sum(h)*N);
