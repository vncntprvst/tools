
% convert cell array of similar structures to table

data.gsdata.alldb=cellfun(@(x) struct2table(x), data.gsdata.alldb,'UniformOutput',false);
data.gsdata.alldb=vertcat(data.gsdata.alldb{:});