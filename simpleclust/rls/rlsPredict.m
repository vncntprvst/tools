function Ytest = rlsPredict(Xtest,Xtrain,coeffs,whichKernel)
%prediction from RLS coeffs from rlsTrain
% function Ytest = rlsPredict(Xtest,Xtrain,coeffs,whichKernel)
%
% returns:
% Ytest prediction
%
% takes
% Xtest points on which to test
% Xtrain training dataset
% coeffs coefficient from rlsTrain
% whichKErnel kernel to use

rlsAssignkernelfun;

[N,d] = size(Xtrain);
Nt=size(Xtest,1);

for i=1:Nt
   % s=0;
    %for j=1:N
   %     s=s+coeffs(j)*kernelfun(Xtrain(j,:),Xtest(i,:));
    %end;
    Ytest(i)=sum(coeffs.*kernelfun(Xtrain(:,:),Xtest(i,:)));
    %Ytest(i) = sum((Xtrain,Xtest(i,:)')*coeffs);
end;
    
%Ytest = (Xtest*Xtrain')*coeffs;



