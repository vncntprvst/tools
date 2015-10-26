function [commoncells,fileidx]=compare_db_filelists(queries,conn)

% conn = connect2DB('vp_sldata');

%get file lists
% filelist{1} =fetch(conn,'select r.a_file, r.recording_id FROM recordings r WHERE r.task=''gapstop'' AND r.recloc=''dentate'''); %dentate %top_cortex

filelist{1}=fetch(conn,queries{1});
filelist{2}=fetch(conn,queries{2});

%removing A and last digit
filelist{1}(:,1)=cellfun(@(x) x(1:end-2), filelist{1}(:,1),'UniformOutput',false);
filelist{2}(:,1)=cellfun(@(x) x(1:end-2), filelist{2}(:,1),'UniformOutput',false);

%% matching files
fileidx{1}=ismember(filelist{1}(:,1),filelist{2});
fileidx{2}=ismember(filelist{2},filelist{1}(:,1));
commoncells=filelist{2}(fileidx{2});
% nmatching_files=filelist{2}(~ismember(filelist{2}(:,1),filelist{1}));

%% by cluster type
if size(filelist{1},2)>1
    clussorts=fetch(conn,['SELECT s.sort_id, processed_mat, recording_id_fk FROM sorts s WHERE recording_id_fk IN (' ...
        sprintf('%.0f,' ,[filelist{1}{1:end-1,2}]) num2str(filelist{1}{end,2}) ')']);
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
    profiles = fetch(conn, ['SELECT c.profile, c.profile_type, c.sort_id_fk FROM clusters c WHERE sort_id_fk IN (' ...
        sprintf('%.0f,' ,[clussorts{1:end-1,1}]) num2str(clussorts{end,1}) ')']);
    %sort profiles by increasing sort_id idx
    [~,sort_id_idx]=sort([profiles{:,3}]);
    profiles=profiles(sort_id_idx,:);
    clussorts(:,3:4)=profiles(:,1:2);
    
    clus1_dfiles=clussorts([clussorts{:,4}]==101,:);
    matchingclus1_dfiles=clus1_dfiles(ismember(clus1_dfiles(:,2),filelist{2}),2);
    nmatchingclus1_dfiles=clus1_dfiles(~ismember(clus1_dfiles(:,2),filelist{2}),2);
end
end