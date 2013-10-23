%Compute the cross covariance between x and y.
%
%INPUT
%  x = signal #1.
%  y = signal #2.
%
%OUTPUT
%  rxy = the cross covariance between x and y.
%  lag = the lag axis, useful for plotting.

function [rxy, lag] = my_cc_circ_shift(x,y)

  N = length(x);                %The size of the data.
  rxyP = zeros(1,N-1);          %The cross covariance at positive shifts.
  rxyN = zeros(1,N-1);          %The cross covariance at negative shifts.
  lagP = zeros(1,N-1);          %Lag axis for positive shifts.
  lagN = zeros(1,N-1);          %Lag axis for negative shifts.
  
  for h=1:N-1                           %Positive shifts.
      temp = sum(circshift(x,[1,h]).*y);
      rxyP(h)=temp;
      lagP(h)=h;
  end
  
  for h=1:N-1                           %Negative shifts.
      temp = sum(circshift(x,[1,-h]).*y);
      rxyN(N-1-(h-1))=temp;
      lagN(N-1-(h-1))=-h;
  end
  
  temp = sum(x.*y);                     %Zero shift.
  rxy0 = temp;
  
  rxy = [rxyN rxy0 rxyP]/N;             %Organize the results for output.
  lag = [lagN 0 lagP];
  
end