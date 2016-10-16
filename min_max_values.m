function colIdx=min_max_values(values,option)
if strcmp(option,'min')
    colIdx=arrayfun(@(row) find(values(row,:)==min(values(row,:)),1),1:size(values,1));
elseif strcmp(option,'max')
    colIdx=arrayfun(@(row) find(values(row,:)==max(values(row,:)),1),1:size(values,1));
end