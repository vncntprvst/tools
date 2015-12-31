function [Inhibition] = InhCumWeib(Params,Data)
%% InhCumWeib
%     Fun(gama,XData,alpha,beta,delta) = gama-((exp(-((XData./alpha).^beta))).*(gama-delta))
%     Params: Initial Guess [alpha beta gamma delta];

% 1. Get data
if length(Params)<3
    Params(3)=1; Params(4)=0;
end

% 2. Compute Values
% Inhibition = 1 - (Params(3)-((exp(-((Data./Params(1)).^Params(2)))).*(Params(3)-Params(4))));

% L Boucher made the following change from the above equation.
Inhibition = (Params(3)-((exp(-((Data./Params(1)).^Params(2)))).*(Params(3)-Params(4))));