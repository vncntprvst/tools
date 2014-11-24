function [l,c] =  sc_sxcorr(a,b,lag,N);
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
        n = histc(y,t);
        if ~isempty(n)
            crosscorr_result = crosscorr_result + reshape(n,1,length(crosscorr_result));
        end
    end
end
l = t + binwidth/2;
c = crosscorr_result ./ (sum(crosscorr_result));


% l=linspace(-lag,lag,N*2);
% h=zeros(size(l));
% %h_null=zeros(size(l));
% 
% 
% for i=1:numel(a)
%     h=h+histc(b-a(i),l);
% end;
% c=h./(sum(h)*N);
