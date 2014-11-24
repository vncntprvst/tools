function [looe,coeffs] = rlsLOO(Ytrain,Ktrain,lambdas)
%efficient leave one out error for a set of lambdas
% function looe = rlsLOO(Ytrain,Ktrain,lambdas)
%
% returns:
% looe vector of loo errors, one per supplied lambda
% coeffs optimal RLS coefficients for all lambdas
%
% takes:
% Ytrain training labels
% Ktrain Kernel Matrix of training set
% lambdas set of resularization parameters

%% eigendecompose Ktrain
[Q,v]=eig(Ktrain);
N=size(Ktrain,2);

%% run different lambdas:
for l=1:length(lambdas)
    
    % get coeffs
    Ginv = Q*diag(1./(diag(v)+lambdas(l)))*Q'; 
    coeffs(:,l)=Ginv*Ytrain;
    
    % compute leave-one-out error
    looe(l)= sum( ( coeffs(:,l)./diag(Ginv)  ).^2 );
    
    %{
    %sanitycheck
    KGinv=Ktrain*Ginv;
    KGinvy=KGinv*Ytrain;
    for i=1:N
        y(i) = (KGinvy(i)-KGinv(i,i)*Ytrain(i))./(1-KGinv(i,i));
    end;
    looe(l)= sum(      ( Ytrain-y'  ).^2         );
    %}
end;