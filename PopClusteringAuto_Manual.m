function success=PopClusteringAuto_Manual
global directory slash;
%% settings
userinfo=SetUserDir;
directory=userinfo.directory;
slash=userinfo.slash;
% userinfo.user,userinfo.dbldir,userinfo.mapdr,userinfo.servrep,userinfo.mapddataf
conn = connect2DB('vp_sldata');

cd(userinfo.syncdir);
dataset='top_cortex_gsdata.mat'; %cDn_gsdata.mat  top_cortex_gsdata.mat
data=load(dataset);
% curVars=whos;
% curVars(~cellfun('isempty',cellfun(@(x) strfind(x,'data.(dataField)'), {curVars.name},'UniformOutput',false))).name
dataField=cell2mat(fieldnames(data));

%% compute saccade responses
[sacresps,bnorm_sacresps,rnorm_sacresps,sacrespsTrials,bslrespsTrials]=comp_sacresp(data,dataField);

%% cluster population
% method 1/ (mine)
unit_ids=cellfun(@(x) x.unit_id,data.(dataField).alldb);

method='hclus';
[clusterIdx{1},clustypes]=clus_pop(sacresps,bnorm_sacresps,rnorm_sacresps,method);
[~,sortidx{1}]=sort(clusterIdx{1});
clusid{1}=unique(clusterIdx{1});

% method 2/ (Manu's)
% clusterIdx{2} = clus_pop_ROC(sacrespsTrials,bslrespsTrials);
% [~,sortidx{2}]=sort(clusterIdx{2});
% clusid{2}=unique(clusterIdx{2});
% % figure; plot(mean(sacresps(clusterIdx{2}==1,:)))
% % length(find(clusterIdx{2}==1))

% sort junk with ROC method
clusterIdx{2}=clusterIdx{1};
junkClus=clus_pop_ROC(sacrespsTrials(clusterIdx{2}==-1),bslrespsTrials(clusterIdx{2}==-1));
% [foo,sortJkIdx]=sort(junkClus);
% figure('name','population raster')
% jkRnormSacResps=rnorm_sacresps(clusterIdx{1}==-1,:);
% subplot(1,2,1)
% imagesc(1:size(jkRnormSacResps,2),1:size(jkRnormSacResps,1),jkRnormSacResps)
% subplot(1,2,2)
% imagesc(1:size(jkRnormSacResps,2),1:size(jkRnormSacResps,1),jkRnormSacResps(sortJkIdx,:))
%
clusterIdx{2}(clusterIdx{2}==-1)=junkClus;
% plot(nanmean(bnorm_sacresps(clusterIdx{2}==1,:)));
% get rid of cluster categories with insuficient activity change
clusid{2}=unique(clusterIdx{2});
for ClusNum=1:numel(clusid{2})
    AvgClusWf=nanmean(bnorm_sacresps(clusterIdx{2}==clusid{2}(ClusNum),:));
    if abs(diff([max(AvgClusWf) min(AvgClusWf)]))<2
        clusterIdx{2}(clusterIdx{2}==clusid{2}(ClusNum))=-1;
    end
end
[~,sortidx{2}]=sort(clusterIdx{2});
clusid{2}=unique(clusterIdx{2});

%re-assign cluster types following Method 2
% [clustypes{clusterIdx{2}==2}]=deal('earlyPk');
% [clustypes{cellfun(@(x) strcmp(x,'ramp_to_reward'),clustypes)}]=deal('rampAllTheWay');
% [clustypes{cellfun(@(x) strcmp(x,'sacburst'),clustypes)}]=deal('sacBurst');
% [clustypes{cellfun(@(x) strcmp(x,'rampup'),clustypes)}]=deal('rampThenFall');
keepData.cellprofile.sacresps=sacresps;
keepData.cellprofile.bnorm_sacresps=bnorm_sacresps;
keepData.cellprofile.rnorm_sacresps=rnorm_sacresps;
keepData.clusteridx=clusterIdx{2};
keepData.dbinfo=data.gsdata.alldb;
keepData.dbconn=conn;

clearvars -except dataset keepData 

%% call GUI
PopClustering_GUI(dataset,keepData)

%% [optional] add / change unit's profile in db
% success = addProfile(clustypes, clusterIdx{2}, unit_ids, conn );

end



