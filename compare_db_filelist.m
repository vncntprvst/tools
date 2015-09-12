CCNdb = connect2DB('vp_sldata');
%get file lists
dentatefiles =fetch(CCNdb,'select r.a_file, r.recording_id FROM recordings r WHERE r.task=''gapstop'' AND r.recloc=''dentate'''); %dentate %top_cortex
dentatelist_manu = fetch(CCNdb,'SELECT Filename FROM dentate_manulist');

%removing A and last digit
dentatefiles(:,1)=cellfun(@(x) x(1:end-2), dentatefiles(:,1),'UniformOutput',false);
%just need to remove last digit
dentatelist_manu=cellfun(@(x) x(1:end-1), dentatelist_manu,'UniformOutput',false);

%% files classified as from dentate in data, that are classified as such by Manu
matching_dfiles=dentatefiles(ismember(dentatefiles(:,1),dentatelist_manu));
nmatching_dfiles=dentatefiles(~ismember(dentatefiles(:,1),dentatelist_manu));

%% by cluster type
clussorts=fetch(CCNdb,['SELECT s.sort_id, processed_mat, recording_id_fk FROM sorts s WHERE recording_id_fk IN (' ...
    sprintf('%.0f,' ,[dentatefiles{1:end-1,2}]) num2str(dentatefiles{end,2}) ')']);
%remove extra sorts
[~,clussorts_uidx]=unique([clussorts{:,3}]');
clussorts=clussorts(clussorts_uidx,:);
%sort by increasing sort_id values
[~,sort_id_idx]=sort([clussorts{:,1}]);
clussorts=clussorts(sort_id_idx,:);
%just keep file name
clussorts(:,2)=cellfun(@(x) regexp(x,'(?<=\\\w+\\)\w+','match'),clussorts(:,2));
%remove last digit
clussorts(:,2)=cellfun(@(x) x(1:end-1), clussorts(:,2),'UniformOutput',false);
%get profiles
profiles = fetch(CCNdb, ['SELECT c.profile, c.profile_type, c.sort_id_fk FROM clusters c WHERE sort_id_fk IN (' ...
    sprintf('%.0f,' ,[clussorts{1:end-1,1}]) num2str(clussorts{end,1}) ')']);
%sort profiles by increasing sort_id idx
[~,sort_id_idx]=sort([profiles{:,3}]);
profiles=profiles(sort_id_idx,:);
clussorts(:,3:4)=profiles(:,1:2);

clus1_dfiles=clussorts([clussorts{:,4}]==101,:);
matchingclus1_dfiles=clus1_dfiles(ismember(clus1_dfiles(:,2),dentatelist_manu),2);
nmatchingclus1_dfiles=clus1_dfiles(~ismember(clus1_dfiles(:,2),dentatelist_manu),2);

