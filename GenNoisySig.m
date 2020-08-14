function noisySig=GenNoisySig(sigDur,sigFreq,sampFreq,phaseShift,numCh)

% parameters
% sigDur = 3;        % Duration (sec)
% sigFreq   = 9;    % Frequency (Hz)                                 
% sampFreq  = 250;   % Sampling Frequency (Hz) 
% phaseShift = pi/2;
sigAmp = 3;
sigOffset = 0; %1.5;
noiseAmp = 0.5;
               
timeVec   = linspace(0, sigDur, sampFreq*sigDur); % Time Vector

% sampInterv = 1/sampFreq;
% timeVec = 0:sampInterv:1-sampInterv;     % 1s signal

%generate signal
for chNum=1:numCh
    sig = sigOffset + sigAmp*sin(((2*pi*sigFreq*timeVec))+(phaseShift*chNum));  %                 % Signal (10 kHz sine)
    noisySig(chNum,:) = sig + noiseAmp*(randn(size(sig)));%-0.5
end

% figure; hold on
% plot(noisySig(1,:))
% plot(noisySig(end,:))

% figure;
% imagesc(noisySig)


%% cool effects:
% for chNum=1:64
%     sig = sigOffset + sigAmp*sin(2*(pi+0.5*chNum*pi)*sigFreq*timeVec);                         % Signal (10 kHz sine)
%     noisySig(chNum,:) = sig + noiseAmp*(randn(size(sig))-0.5);
% end
% 

% for chNum=1:64
%     sig = sigOffset + sigAmp*sin((2*pi+0.5*chNum)*sigFreq*timeVec);                         % Signal (10 kHz sine)
%     noisySig(chNum,:) = sig + noiseAmp*(randn(size(sig))-0.5);
% end

% for chNum=1:64
%     sig = sigOffset + sigAmp*sin(((2*pi*sigFreq)+(pi/2*chNum))*timeVec);                         % Signal (10 kHz sine)
%     noisySig(chNum,:) = sig + noiseAmp*(randn(size(sig))-0.5);
% end
% 
% figure;
% imagesc(noisySig)