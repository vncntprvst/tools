function features =addnoisetoquantiledfeatures(features)

np=size(features.data,2);
for i=1:size(features.data,1)
    
    q=numel(unique((features.data(i,:))));
    
    if  q<np./30 % heuristic time!
        features.data(i,:)=features.data(i,:)+rand(1,np)./q; % add noise!
    end;
        
end;