function deleteSpreadsheet(spreadsheetKey,aToken)
import java.io.*;
import java.net.*;
import java.lang.*;
com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings;

MAXITER=10;
success=false;

getURLStringList=['https://docs.google.com/feeds/default/private/full/' spreadsheetKey '?delete=true'];
safeguard=0;
while (~success && safeguard<MAXITER)        
    safeguard=safeguard+1;
    con = urlreadwrite(mfilename,getURLStringList);
    con.setRequestMethod( 'DELETE' );
    con.setRequestProperty('GData-Version','3.0');
    con.setRequestProperty('If-Match','*');
    con.setRequestProperty('Authorization',String('GoogleLogin ').concat(aToken));        
    if (con.getResponseCode()~=200)    
        con.disconnect();
        continue;
    end
    success=true;
end
if success
    con.disconnect(); clear con;
else
    display(['Last response was: ' num2str(con.getResponseCode) '/' con.getResponseMessage().toCharArray()']);
    clear con;
    return;
end
    