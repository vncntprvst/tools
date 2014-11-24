function [coeffs,K] = rlsTrain(Ytrain,Xtrain,whichKernel,lambda,varargin)
%rlsTrain regularized least squares coefficient estimator
% function coeffs = rlsTrain(Ytain,Xtrain,whichKErnel,lambda)
%
% returns:
% optimal RLS coefficients in coeffs
% K Kernel matrix of training set
%
% takes
% Xtrain training input
% Ytrain training labels
% whichKErnel kernel to use
% lambda regularization weight
% (optional) kernel matrix K

%% compute kernel matrix
if size (varargin) ==1 % if kernel matrix is supplied
    K=varargin{1};
else % compute kernel matrix
    rlsAssignkernelfun;
    K = KernelMatrix(Xtrain,kernelfun);
end;

%% perform RLS fit

[N,d] = size(Xtrain);

coeffs  = ( K+ (eye(N)*lambda) )\Ytrain;