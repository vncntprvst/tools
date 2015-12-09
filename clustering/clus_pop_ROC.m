%Cluster neurons according to their response profiles

%input: reponse data (cell array of n neurons)
%       baseline data (cell array of n neurons)
%       [optional] clusternumber: intended number of clustered to be created

%output: clusterind (indices assigning each row to a cluster)
%output plot: silhouette analysis on clustered data

function clusterIdx = clus_pop_ROC(respData,baselineData,optimClusNum)
switch nargin
    case 2
        optimClusNum=0;
end
%concatenate baseline and response data and calculate AUC
ROCarray=cellfun(@(x,y) calcAUROC([x,y],[1 size(y,2)]),respData,baselineData, 'UniformOutput',false);
%ROCarray: ROC data formatted in an mxn matrix, where m equals number of
%neurons, n = rows of ROC data calculated by running calcAUROC on data

if ~optimClusNum
    %evaluate optimal number of clusters
    davies_index = [999 zeros(1,14)];
    for num_clusters = 2:15
        [cluster_ids,cluster_centroids,cluster_distances] = kmeans(1-corr(cat(1,ROCarray{:})'),num_clusters,'Distance','sqEuclidean');
        
        pairwise_cluster_distances = squareform(pdist(cluster_centroids,'Euclidean'));
        cluster_populations = arrayfun(@(x) numel(find(cluster_ids == x)),1:num_clusters);
        intracluster_distances = cluster_distances./cluster_populations';
        
        davies_per_cluster = zeros(1,num_clusters);
        for clusnb = 1:num_clusters
            davies_temp = zeros(1,num_clusters);
            for j= setxor(1:num_clusters,clusnb)
                davies_temp(j) = (intracluster_distances(clusnb)+intracluster_distances(j))./pairwise_cluster_distances(j,clusnb);
            end
            davies_per_cluster(clusnb) = max(davies_temp);
        end
        davies_index(num_clusters) = 1./num_clusters*sum(davies_per_cluster);
    end
    % figure; plot(davies_index(2:end),'r','linewidth',2)
    optimClusNum=find(davies_index(2:end)==max(davies_index(2:end)))+1;
end
% change to optimClusNum+1
clusterIdx = kmeans(1-corr(cat(1,ROCarray{:})'),optimClusNum,'dist','cityblock');
% silhouette(1-corr(cell2mat(temp')'),clust)
end