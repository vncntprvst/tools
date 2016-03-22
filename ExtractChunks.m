% splitting arrays: create index of chunks to extract
% then something like that

% ne0 = find(A~=0);                                   % Nonzero Elements
% ix0 = unique([ne0(1) ne0(diff([0 ne0])>1)]);        % Non-Zero Segment Start Indices
% eq0 = find(A==0);                                   % Zero Elements
% ix1 = unique([eq0(1) eq0(diff([0 eq0])>1)]);        % Zero Segment Start Indices
% ixv = sort([ix0 ix1 length(A)]);                    % Consecutive Indices Vector
% for k1 = 1:length(ixv)-1
%     section{k1} = A(ixv(k1):ixv(k1+1)-1);
% end
% celldisp(section)