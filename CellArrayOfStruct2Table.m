% convert cell array of similar structures to table

% data=load([dataset '.mat']); %cDn_cmdata.mat  top_cortex_cmdata.mat
data.cmdata.alldb=cellfun(@(x) struct2table(x), data.cmdata.alldb,'UniformOutput',false);
data.cmdata.alldb=vertcat(data.cmdata.alldb{:});

% save(dataset,'data','-v7.3')