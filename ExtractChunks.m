% splits vector in multiple equal chunks at specified index
function chuncks=ExtractChunks(data,chunkIndex,chunkSize)

chunkWindow=int32(-round(chunkSize/2):round(chunkSize/2)-1);

% brute force loop
% chuncks=nan(length(chunkIndex),length(chunkWindow));
% for chunkNum=1:length(chunkIndex)
%     chuncks(chunkNum,:)=data(chunkIndex(chunkNum)-round(chunkSize/2):chunkIndex(chunkNum)+round(chunkSize/2)-1);
% end

%slightly better loop (fastest)
chuncks=nan(length(chunkIndex),length(chunkWindow));
for chunkBits=1:length(chunkWindow)
    chuncks(:,chunkBits)=data(chunkIndex+chunkWindow(chunkBits))';
end

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
