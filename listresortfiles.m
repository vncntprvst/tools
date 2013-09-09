%list re-sorted files 

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

    % Read data from database.
    e = exec(conn,['SELECT ALL Filename FROM "' Subjects{dirs} '$"']);
    e = fetch(e);
    close(e)

    % Assign data to output variable.
    filelist = e.Data;

    %lookup which files are missing from the list
    addfiles=FileNames(~ismember(FileNames,filelist));

    if ~isempty(addfiles)
        % Write data to database.
        insert(conn,['"' Subjects{dirs} '$"'],{'Filename'},addfiles)
    end

end


%% Close database connection.
close(conn)


