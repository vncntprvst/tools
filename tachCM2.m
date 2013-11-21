function [xctr xtach tach rPTc rPTe] = tachCM2(data, wbin, rect, crng)

%tachCM2 Empirical tachometric curve for the countermanding task
%
%   [xctr xtach tach rPTc rPTe] = tachCM2(data, [wbin], [rect], [crng])
%
% This function takes behavioral data from the countermanding task ---
% reaction times (RTs) and hits/errors for each stop-signal delay
% (SSD) tested --- and generates a tachometric curve based on them;
% that is, the probability of a correct cancellation as a function of
% processing time (or cue-viewing time).  The curve is slightly
% broader than the ideal curve obtained with the accelerated
% rise-to-threshold model, but has the same properties. 
%
% Inputs:
%
%  data --> Nt x 3 matrix with SSD, RT and hit/error (1,0) values for
%           each trial; Nt is the total number of trials. No-stop
%           trials must have SSD = Inf.
%
%  wbin --> bin size used for the tachometric curve
%           default: wbin = 20 ms
%
%  rect --> {0,1} do (0) or do not (1) allow negative values
%           default: rect = 1
% 
%  crng --> 1 x 2 center range of the tachometric curve, where the
%           center point and the maximum should be found
%           default: crng = [-20 170];
%
% Outputs:
%
%  xctr --> rPT interval containing the centerpoint of the 
%           tachometric curve
%
%  xtach --> x-axis corresponding to all possible rPT values
%
%  tach --> tachometric curve; i.e, P(saccade cancellation | rPT)
%
%  rPTc --> distribution of rPT values for correct stop trials 
%           (i.e., from cancelled saccades) 
%
%  rPTe --> distribution of rPT values for incorrect stop trials
%           (i.e., from non-cancelled saccades) 
%
% The key quantity to compute is rPTc. This is done by `subtracting'
% the distribution of inferred RT times for cancelled trials from the
% full RT distribution, which is that seen in no-stop trials. The
% subtraction is quite literal here: the RT histogram for
% non-cancelled trials is subtracted, bin by bin, from the RT
% histogram of the no-stop trials, scaled so that the total numbers
% of trials are the same.
%
% The distribution rPTe is straightforward to compute, as it is
% derived from the standard RTs measured in non-cancelled trials. The
% tachometric curve is equal to rPTc./(rPTc + rPTe).
%
% When called without output arguments, the function simply plots the
% results.
%
% See also: tachCM1

% Emilio Salinas, May 2011
% VP - slight edit on elimination of values before final upswing, for
% better detection xctr with noisy data, Nov 2013

 %
 % default values
 %
 if nargin < 2 | isempty(wbin)
     wbin = 20;
 end
 if nargin < 3 | isempty(rect)
     rect= 1;
 end
 if nargin < 4 | isempty(crng)
     crng = [-20 170];
 end

 %
 % extract data; data columns are
 %
 %  ssd (stop-signal delay) | RT | hit {0,1} 
 %
 ssd1 = data(:,1);
 rt = data(:,2);
 hit = data(:,3);

 ssd = [unique(ssd1)]';
 Nssd = length(ssd);

 %
 % find numbers of correct and error trials per SSD
 %
 Nc = zeros(1,Nssd);  
 Nt = zeros(1,Nssd);  
 for j=1:Nssd
     ii = (ssd1 == ssd(j));
     Nt(j) = sum(ii);
     Nc(j) = sum(hit(ii));
 end
 Ne = Nt - Nc;

 %
 % set aside RTs from no-stop trials
 %
 ii = find(ssd1 == Inf & hit == 1);
 rtns = rt(ii);
 Nns = length(rtns);
 xlo = min(rtns) - floor(max(ssd(ssd < Inf))) - 50;
 xhi = ceil(max(rtns));
 xtach = [xlo:1:xhi];

 %
 % get rPT distributions in stop and no-stop trials
 %
 rPTce = zeros(size(xtach));
 rPTe = zeros(size(xtach));
 for j=1:Nssd
     if ssd(j) < Inf
         % get rPT distribution from non-cancelled trials
         ii = find(ssd1 == ssd(j) & hit == 0);
         rPT = rt(ii) - ssd(j);
         rPT1 = local_hist(rPT, xtach, wbin);
         rPTe = rPTe + rPT1;
         % rPTs in no-stop distributions include both correct and errors
         rPT = rtns - ssd(j);
         rPT2 = local_hist(rPT, xtach, wbin);
         % scale to actual number of stop trials attempted
         rPT2 = rPT2*Nt(j)/Nns;
         rPTce = rPTce + rPT2;
     end
 end
 
 %
 % distribution of rPTs for correct (cancelled) stop trials
 rPTc = rPTce - rPTe;

 %
 % compute the tachometric curve this way; it's less noisy;
 % we want rc/(rc + re) = rc/rns, so 
 %
 y = rPTe./(rPTce);
 tach = 1 - y;

 %
 % eliminate values before final upswing
 %
 lastnegv=find(rPTc < 0, 1, 'last'); %last negative value
 pmax = max(rPTc(lastnegv:end));
 imax = lastnegv + find(rPTc(lastnegv:end) == pmax, 1, 'first') -1;
 if rect > 0
     izero = imax - find(rPTc(imax:-1:1) < 0, 1, 'first') +1;
     tach(1:izero) = 0;
 end

 %
 % locate the centerpoint
 %
 igood = find(xtach >= crng(1) & xtach <= min(crng(2), xtach(imax)));
 xtach1 = xtach(igood);
 tach1 = tach(igood);
 pctr = mean([0 max(tach1)]);
 %ictr = [find(tach1 < pctr, 1, 'last') find(tach1 > pctr, 1, 'first')];
 % this works best because top part of tach curve is much more reliable
 ictr = find(tach1 <= pctr, 1, 'last');
 if ictr < length(tach1)
     ictr = [ictr ictr+1];
 else
     ictr = [ictr ictr];
 end
 ictr = [ictr ictr+1];
 xctr = xtach1(ictr);

 % 
 % plot the results if no outputs are requested
 % 
 if nargout < 1
     clf
     hold on
     nfac = max(rPTc);
     plot(xtach, tach, 'c.-')
     plot(xtach, rPTe/nfac, 'r-')
     plot(xtach, rPTc/nfac, 'b-')
     plot(xtach, rPTce/nfac, 'y-')
     plot(xctr(1)*[1 1], ylim, 'w:')
     plot(xctr(2)*[1 1], ylim, 'w:')
     plot(xlim, pctr*[1 1], 'w:')
     yaxis(-0.1, 1.05)
     xlabel('Raw processing time (ms)')
     ylabel('P(cancelled | rPT)')
     mssg = ['Tachometric curve and rPT distributions' char(10) ...
             'xctr = [' num2str(xctr) ']'];
     title(mssg)
     clear
 end

 %
 % compute running histogram: each point gives the number of counts in
 % a window of width wbin
 %
 function [nx] = local_hist(x, xbin, wid)

 nx = NaN(size(xbin));
 hwid = wid/2;
 Nxbin = length(xbin);
 for j=1:Nxbin
     xlo = xbin(j) - hwid;
     xhi = xbin(j) + hwid;
     if j == 1
         xlo = -Inf;
     elseif j == Nxbin
         xhi = Inf;
     end
     ii = (x > xlo) & (x <= xhi);
     nx(j) = sum(ii);
 end

 

