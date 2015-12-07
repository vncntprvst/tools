%function which clustered data
%input: 
%ROCarray: ROC data formatted in an mxn matrix, where m equals number of
%neurons, n = rows of ROC data calculated by running calcAUROC on data
% clusternumber: intended number of clustered to be created

%output: clusterind (indices assigning each row to a cluster)
%output plot: silhouette analysis on clustered data

function [clusterind] = clusterROC(ROCarray,clusternumber)
clustind = kmeans(1-corr(ROCarray'),5,'dist','cityblock');
silhouette(1-corr(cell2mat(temp')'),clust)
end