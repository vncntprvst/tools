function spreadsheetNew=createSpreadsheet(spreadsheetTitle,aToken)

import java.io.*;
import java.net.*;
import java.lang.*;
com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings;
spreadsheetNew=[];

MAXITER=10;
success=false;

getURLStringList='https://docs.google.com/feeds/default/private/full';
safeguard=0;

while (~success && safeguard<MAXITER)
    safeguard=safeguard+1;
    con = urlreadwrite(mfilename,getURLStringList);
    con.setInstanceFollowRedirects(false);
    con.setRequestMethod( 'POST' );
    con.setDoOutput( true );
    con.setDoInput( true );
    con.setRequestProperty('GData-Version','3.0');
    con.setRequestProperty('Authorization',String('GoogleLogin ').concat(aToken));
    con.setRequestProperty('Content-Type','application/atom+xml;charset=UTF-8');        
    event=['<entry xmlns=''http://www.w3.org/2005/Atom''>'...
        '<category scheme=''http://schemas.google.com/g/2005#kind''' ...
        ' term=''http://schemas.google.com/docs/2007#spreadsheet''/>' ...
        '<title type=''text''>' spreadsheetTitle '</title>' ...
        '</entry>'];
    ps = PrintStream(con.getOutputStream());
    ps.print(event);
    ps.close();  clear ps event;  
    if (con.getResponseCode()~=201)
        con.disconnect();
        continue;
    end
    success=true;
end
if success
    xmlData=xmlread(con.getInputStream());
    con.disconnect(); clear con;
    spreadsheetNew.spreadsheetKey=xmlData.getElementsByTagName('gd:resourceId').item(0).getFirstChild.getData.toCharArray';
    spreadsheetNew.spreadsheetKey(1:length('spreadsheet:'))=[];
    spreadsheetNew.spreadsheetTitle=xmlData.getElementsByTagName('title').item(0).getFirstChild.getData.toCharArray';
    clear xmlData;
else
    display(['Last response was: ' num2str(con.getResponseCode) '/' con.getResponseMessage().toCharArray()']);
    clear con;
    return;
end