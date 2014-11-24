clear all; close all; clc;

cd('e:\optogenetic Control of Synchrony\SI-SII Stim Data\11-27-2012');
n = LoadSpikeWF('Mouse4_StimSIFreq_121127_121711_Ch5ReRef.wf', [], 5);
[t, wv] = LoadSpikeWF('Mouse4_StimSIFreq_121127_121711_Ch5ReRef.wf', [1 n], 4);
cd('c:\matlab Work\simpleclust');

mua.waveforms = zeros(size(wv, 3), size(wv, 2), size(wv, 1));
for i = 1:size(wv, 1),
    mua.waveforms(:, :, i) = squeeze(wv(i, :, :))';
end
mua.ts = t;
mua.Nspikes = n;
mua.sourcechannel = 5;
save('test.mat', 'mua');
%%

clear all; close all; clc;
simple_clust