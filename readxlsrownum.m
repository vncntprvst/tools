% Set preferences with setdbprefs.
s.DataReturnFormat = 'cellarray';
s.ErrorHandling = 'store';
s.NullNumberRead = 'NaN';
s.NullNumberWrite = 'NaN';
s.NullStringRead = 'null';
s.NullStringWrite = 'null';
s.JDBCDataSourceFile = '';
s.UseRegistryForSources = 'yes';
s.TempDirForRegistryOutput = 'C:\Users\DANGER~1\AppData\Local\Temp';
s.DefaultRowPreFetch = '10000';
setdbprefs(s)

% Make connection to database.  Note that the password has been omitted.
% Using ODBC driver.
conn = database('Excel Files','','password');

% Read data from database.
e = exec(conn,'SELECT COUNT(*) FROM "Sixx$"');
e = fetch(e);
close(e)

% Assign data to output variable.
count = e.Data;

% Close database connection.
close(conn)
