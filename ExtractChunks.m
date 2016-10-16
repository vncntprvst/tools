% splits vector in multiple equal chunks at specified index
function chuncks=ExtractChunks(data,chunkIndex,chunkSize,timewindow)

if strcmp(timewindow,'tzero')
   chunkWindow=int64(1:chunkSize); 
elseif strcmp(timewindow,'tshifted') 
   chunkWindow=int64(-round(chunkSize/3):round(chunkSize/3*2)-1);
elseif strcmp(timewindow,'tmiddle') 
   chunkWindow=int64(-round(chunkSize/2):round(chunkSize/2)-1);
end

% brute force loop
% chuncks=nan(length(chunkIndex),length(chunkWindow));
% for chunkNum=1:length(chunkIndex)
%     chuncks(chunkNum,:)=data(chunkIndex(chunkNum)-round(chunkSize/2):chunkIndex(chunkNum)+round(chunkSize/2)-1);
% end

%slightly better loop (fastest)
chuncks=nan(length(chunkIndex),length(chunkWindow));
for chunkBits=1:length(chunkWindow)
    %check that chunks are within boundaries
    inBounds=int64(chunkIndex)+chunkWindow(chunkBits)>0 & ...
        int64(chunkIndex)+chunkWindow(chunkBits)<=length(data);
    % get data
    chuncks(inBounds,chunkBits)=data(int64(chunkIndex(inBounds))+...
        chunkWindow(chunkBits))';
end
chuncks(isnan(chuncks))=0;
% chuncks=rot90(chuncks,2);
%no loop, but slightly slower
% chunkFullIdx=arrayfun(@(x) x+chunkIndex,chunkWindow,'UniformOutput',false);
% chuncks=data(reshape([chunkFullIdx{:}],1,length(chunkIndex)*chunkSize));
% chuncks=reshape(chuncks,length(chunkIndex),chunkSize);

% much slower
% chuncks=cell2mat(arrayfun(@(x) data(x+chunkWindow),chunkIndex,'UniformOutput',false));
% much much slower
% chuncks=cell2mat(cellfun(@(x) data(x+chunkWindow),mat2cell(chunkIndex,ones(size(chunkIndex,1),1)),'UniformOutput',false));

% figure; plot(mean(chuncks))
end
