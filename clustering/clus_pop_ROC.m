%Cluster neurons according to their response profiles

%input: reponse data (cell array of n neurons)
%       baseline data (cell array of n neurons)
%       [optional] clusternumber: intended number of clustered to be created

%output: clusterind (indices assigning each row to a cluster)
%output plot: silhouette analysis on clustered data

function clusterIdx = clusterROC(respData,baselineData,clusterNumber)
%concatenate baseline and response data and calculate AUC
ROCarray=cellfun(@(x,y) calcAUROC([x,y],[1 size(y,2)]),respData,baselineData, 'UniformOutput',false); 
%ROCarray: ROC data formatted in an mxn matrix, where m equals number of
%neurons, n = rows of ROC data calculated by running calcAUROC on data
clusterIdx = kmeans(1-corr(cat(1,ROCarray{:})'),5,'dist','cityblock');
% silhouette(1-corr(cell2mat(temp')'),clust)
end