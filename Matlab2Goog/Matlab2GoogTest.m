clear variables; clc;

userName=''; %your '...@gmail.com' email address; if empty you can enter one in the dialog box. 

[aTokenDocs,aTokenSpreadsheet]=connectNAuthorize(userName);
pause(0.5);

if isempty(aTokenDocs) || isempty(aTokenSpreadsheet)
    warndlg('Could not obtain authorization tokens from Google.','');
    return;
end

spreadSheetNew=createSpreadsheet('testMatlabNew',aTokenDocs);

%deleteSpreadsheet(spreadSheetNew.spreadsheetKey,aTokenDocs);

rowCount=10;
colCount=7;
worksheetTitleNew='Sheet';
worksheetNew=createWorksheet(spreadSheetNew.spreadsheetKey,rowCount,colCount,worksheetTitleNew,aTokenSpreadsheet);

spreadsheetWorksheets=getWorksheetList(spreadSheetNew.spreadsheetKey,aTokenSpreadsheet);

selectWorksheet='Sheet 1';
selectWorksheetIndex=strmatch(selectWorksheet,{spreadsheetWorksheets.worksheetTitle},'exact');
if ~isempty(selectWorksheetIndex)
    rowCountNew=1;
    colCountNew=1;
    worksheetTitleNew='SheetDefault';
    changeWorksheetNameAndSize(spreadSheetNew.spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,rowCountNew,colCountNew,worksheetTitleNew,aTokenSpreadsheet);    
%     deleteWorksheet(spreadSheetNew.spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,aTokenSpreadsheet);
end

userSpreadsheets=getSpreadsheetList(aTokenSpreadsheet);
%userSpreadsheets=getSpreadsheetListGDocs(aTokenDocs);

selectSpreadsheet='testMatlabNew';
selectSpreadsheetIndex=strmatch(selectSpreadsheet,{userSpreadsheets.spreadsheetTitle},'exact');
if ~isempty(selectSpreadsheetIndex)
    spreadsheetWorksheets=getWorksheetList(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,aTokenSpreadsheet);
    
    
    selectWorksheet='Sheet';
    selectWorksheetIndex=strmatch(selectWorksheet,{spreadsheetWorksheets.worksheetTitle},'exact');
    if ~isempty(selectWorksheetIndex)
        rowCountNew=3;
        colCountNew=5;
        worksheetTitleNew='Sheet1';
        changeWorksheetNameAndSize(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,rowCountNew,colCountNew,worksheetTitleNew,aTokenSpreadsheet);
    end
    spreadsheetWorksheets=getWorksheetList(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,aTokenSpreadsheet);
    
    
    rowCount=3;
    colCount=4;
    worksheetTitleNew='Sheet';
    spreadsheetWorksheets(length(spreadsheetWorksheets)+1)=createWorksheet(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,rowCount,colCount,worksheetTitleNew,aTokenSpreadsheet);
    spreadsheetWorksheets=getWorksheetList(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,aTokenSpreadsheet);
    
    
    selectWorksheet='Sheet';
    selectWorksheetIndex=strmatch(selectWorksheet,{spreadsheetWorksheets.worksheetTitle},'exact');
    if ~isempty(selectWorksheetIndex)
        for rowIndex=1:rowCount
            for colIndex=1:colCount
                if colIndex<colCount || colCount==1
                    editWorksheetCell(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,rowIndex,colIndex,num2str(rand),aTokenSpreadsheet);
                else
                    % square the value in the previous column by entering
                    % formula.
                    editWorksheetCell(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,rowIndex,colIndex,'=R[0]C[-1]*R[0]C[-1]',aTokenSpreadsheet);
                end
            end
        end
    end
    
    for rowIndex=1:rowCount
        for colIndex=1:colCount
            [tempVar1,tempVar2]=getWorksheetCell(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,rowIndex,colIndex,aTokenSpreadsheet);
            worksheetValues(rowIndex,colIndex)={tempVar1};
            worksheetFormulas(rowIndex,colIndex)={tempVar2};
            clear tempVar1 tempVar2;
        end
    end
    spreadsheetWorksheets=getWorksheetList(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,aTokenSpreadsheet);
    
    
    selectWorksheet='Sheet1';
    selectWorksheetIndex=strmatch(selectWorksheet,{spreadsheetWorksheets.worksheetTitle});
    if ~isempty(selectWorksheetIndex)
%         deleteWorksheet(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,spreadsheetWorksheets(selectWorksheetIndex).worksheetKey,aTokenSpreadsheet);
    end
    spreadsheetWorksheets=getWorksheetList(userSpreadsheets(selectSpreadsheetIndex).spreadsheetKey,aTokenSpreadsheet);
end