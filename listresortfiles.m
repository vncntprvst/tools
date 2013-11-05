%list re-sorted files

% listing subjects (NB: in xls file, subjects are now pooled together)
Subjects={'Rigel','Sixx','Hilda'};

AllResortDir='Y:\Team Cerebellum\Resorted Files\';

%% Set preferences with setdbprefs.
s.DataReturnFormat = 'cellarray';
s.ErrorHandling = 'store';
s.NullNumberRead = 'NaN';
s.NullNumberWrite = 'NaN';
s.NullStringRead = 'null';
s.NullStringWrite = 'null';
s.JDBCDataSourceFile = '';
s.UseRegistryForSources = 'yes';
s.TempDirForRegistryOutput = ['C:\Users\' getenv('username') '\AppData\Local\Temp'];
s.DefaultRowPreFetch = '10000';
setdbprefs(s)

% Make connection to database.  Note that the password has been omitted.
% Using ODBC driver.
conn = database('Excel Files','','password');

%% write file names to xls file
for dirs=1:length(Subjects)
    %get file names
    ResortDirInfo=dir([AllResortDir Subjects{dirs}]);
    FileNames={ResortDirInfo.name};
    if ~isempty(find(~cellfun('isempty',regexp(FileNames,'^\d','match')), 1))
        disp('File(s) need Initial letter')
        dirs
        return;
    end
    FileNames=FileNames(~cellfun('isempty',strfind(FileNames,'smr')) | ~cellfun('isempty',strfind(FileNames,'SMR')));
    FileNames=regexprep(FileNames, '(.SMR$)|(.smr$)','')';
    
    %Look filenames in the list
    
    % Read filenames from xls file.
    e = exec(conn,['SELECT ALL Filename FROM "allfiles$"']); % previously Subjects{dirs} instead of allfiles, when files where split in three sheets
    e = fetch(e);
    close(e)
    
    % Assign data to output variable.
    filelist = e.Data(:,1);
    
    %lookup which files are missing from the list
    addfiles=FileNames(~ismember(FileNames,filelist));
    
    if ~isempty(addfiles)
        % Write data to database.
        insert(conn,['"allfiles$"'],{'Filename'},addfiles)
    end
    
    %check segmentation. Write crude segmentation if missing
    % set depth limits for top cortex / dentate / bottom cortex
    
        % Read filenames from xls file.
    e = exec(conn,['SELECT ALL Filename,"Presumed location (depth based)" FROM "allfiles$"']); % previously Subjects{dirs} instead of allfiles, when files where split in three sheets
    e = fetch(e);
    close(e)
    
    % Assign data to output variable
    filelist = e.Data(:,1); %updated filelist
    presumeddepth = e.Data(:,2);
    compart=cell(size(filelist,1),1);
    
    if strcmp('Rigel',Subjects{dirs})
        cdn_depth=19000;
        bcx_depth=22000;
    elseif strcmp('Sixx',Subjects{dirs})
        cdn_depth=11000;
        bcx_depth=17000;
    elseif strcmp('Hilda',Subjects{dirs})
        cdn_depth=19000;
        bcx_depth=26000;
    end
    
    %get depth
    recdepth=regexp(filelist,'_\d\d+','match');
    recdepth=cellfun(@(x) regexp(x{:},'\d+','match'), recdepth,'UniformOutput',false);
    compart(cellfun(@(x) str2double(x)<cdn_depth, recdepth) & ismember(filelist,FileNames))={'top_cortex'};
    compart(cellfun(@(x) (str2double(x)>=cdn_depth && str2double(x)<=bcx_depth), recdepth) & ismember(filelist,FileNames))={'dentate'};
    compart(cellfun(@(x) str2double(x)>bcx_depth, recdepth) & ismember(filelist,FileNames))={'bottom_cortex'};
    fileidx=cellfun(@(x) strfind(filelist,x),FileNames,'UniformOutput', false);
    fileptr=cell2mat(cellfun(@(x) find(~cellfun('isempty',x),1), fileidx,'UniformOutput', false));
    compart=compart(fileptr); 
    
     % Write depth to xls file.
     update(conn,'"allfiles$"',{'"Presumed location (depth based)"'},compart,cellfun(@(x) ['where Filename = ' '''' x ''''],FileNames, 'UniformOutput', false));
        ...['WHERE ID BETWEEN ' num2str(find(ismember(filelist,FileNames),1)) ' AND ' num2str(find(ismember(filelist,FileNames),1,'last'))])
%      ['where Filename =' FileNames]) % ismember(filelist,FileNames)
         
end


%% Close database connection.
close(conn)


