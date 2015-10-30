function pkCc=siglag(sig1,sig2,option)
% find lag between two signals through cross-correlation
switch nargin
    case 1
        return
    case 2
        option='none';
end

[crossCor,lag] = xcorr(sig1,sig2,option);
[~,pkIdx] = max(abs(crossCor));
pkCc = lag(pkIdx);

% home made version
%         crosscor=xcorr(peth{rec,1}(trial,:),peth{rec,2},'unbiased');
%         pkcc(trial)=find(crosscor==max(crosscor))-length(peth{rec,2});

end