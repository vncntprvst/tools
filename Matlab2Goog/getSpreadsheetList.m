function userSpreadsheets=getSpreadsheetList(aToken)

import java.io.*;
import java.net.*;
import java.lang.*;
com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings;

userSpreadsheets=[];

MAXITER=10;
success=false;

getURLStringList='https://spreadsheets.google.com/feeds/spreadsheets/private/full';
safeguard=0;

while (~success && safeguard<MAXITER)
    safeguard=safeguard+1;
    con = urlreadwrite(mfilename,getURLStringList);
    con.setInstanceFollowRedirects(false);
    con.setRequestMethod( 'GET' );
    con.setDoInput( true );
    con.setRequestProperty('Content-Type','application/atom+xml;charset=UTF-8');
    con.setRequestProperty('Authorization',String('GoogleLogin ').concat(aToken));
    if (con.getResponseCode()~=200)
        con.disconnect();
        continue;
    end
    success=true;
end
if success
    xmlData=xmlread(con.getInputStream());
    con.disconnect(); clear con;
    for genericIndex=0:xmlData.getElementsByTagName('entry').getLength-1
        userSpreadsheets(genericIndex+1).spreadsheetKey=xmlData.getElementsByTagName('entry').item(genericIndex).getElementsByTagName('link').item(1).getAttribute('href').toCharArray';
        userSpreadsheets(genericIndex+1).spreadsheetKey(1:length('https://spreadsheets.google.com/ccc?key='))=[];
%         userSpreadsheets(genericIndex+1).spreadsheetID= xmlData.getElementsByTagName('entry').item(genericIndex).getElementsByTagName('id').item(0).getFirstChild.getData.toCharArray';
%         userSpreadsheets(genericIndex+1).spreadsheetID(1:length([getURLStringList '/']))=[];
        userSpreadsheets(genericIndex+1).spreadsheetTitle=xmlData.getElementsByTagName('entry').item(genericIndex).getElementsByTagName('title').item(0).getFirstChild.getData.toCharArray';
    end
    clear xmlData;
else
    display(['Last response was: ' num2str(con.getResponseCode) '/' con.getResponseMessage().toCharArray()']);
    clear con;
    return;
end