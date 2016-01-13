function [ifr,tt] = instantfr(t_spk,tt)
% INSTANTFR - Instantaneous firing rate of a spike train
%   ifr = INSTANTFR(t_spk, tt) calculates the instantaneous firing rate
%   at times TT of a spike train with spikes at times T_SPK.
%   In the interval between two spikes I and I+1, the instanteous firing
%   rate IFR is defined as:
%
%      IFR = 1 / (T_SPK(I+1) - T_SPK(I).
%
%   Even though there is no natural definition for the IFR before the first
%   spike or after the last spike in a train, this function sets IFR to zero
%   in those intervals.
%
%   [ifr,tt] = INSTANTFR(t_spk) automatically picks suitable time points,
%   in practice, just before and just after each spike.

epsi = 1e-6;

tt0 = [t_spk(:)' - epsi; t_spk(:)' + epsi];
idt = [diff([0 t_spk(:)']); diff([t_spk(:)' inf])];
tt0 = tt0(:)';
idt = idt(:)';
if nargin<2
  ifr = 1./idt(2:end-1);
  tt = tt0(2:end-1);
  if size(t_spk,1)~=1
    ifr=ifr';
    tt=tt';
  end
else
  if isempty(t_spk)
    ifr=0*tt;
    return;
  end
  idt1 = inf;%tt0(1)-tt(1);
  idtn = inf;%tt(end)-tt0(end);
  ifr0 = 1./[idt1 idt1 idt(2:end-1) idtn idtn];
  tt0 = [tt(1) tt0 tt(end)];
  ifr = interp1(tt0,ifr0,tt,'linear');
  if size(tt,1)~=1
    ifr=ifr';
  end
end
if nargout<2
  clear tt
end
