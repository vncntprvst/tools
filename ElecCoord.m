%% Output electrode coordinates files from procdata file

%% define path
if strcmp(getenv('username'),'SommerVD')
    directory = 'C:\Data\Recordings\';
elseif  strcmp(getenv('username'),'DangerZone')
    directory = 'E:\Data\Recordings\';
else
    directory = 'B:\data\Recordings\';
end
slash = '\';

%% get info from xls file
monknum=1;

exl = actxserver('excel.application');
    exlWkbk = exl.Workbooks;
    exlFile = exlWkbk.Open([directory 'procdata.xlsx']);
    exlSheet = exlFile.Sheets.Item(monknum);% e.g.: 2 = Sixx
    robj = exlSheet.Columns.End(4);
    numrows = robj.row;
    % if numrows==1048576 %empty document
    %     numrows=1;
    % end
    Quit(exl);
    
    [~,allocs] = xlsread([directory 'procdata.xlsx'],monknum,['C2:C' num2str(numrows)]);
    [~,allrot] = xlsread([directory 'procdata.xlsx'],monknum,['D2:D' num2str(numrows)]);
    [~,alltasks] = xlsread([directory 'procdata.xlsx'],monknum,['G2:G' num2str(numrows)]);
    [alldepth] = xlsread([directory 'procdata.xlsx'],monknum,['E2:E' num2str(numrows)]);
    [allactive] = xlsread([directory 'procdata.xlsx'],monknum,['K2:K' num2str(numrows)]);
    
    allocs=allocs(allactive>0.5);
    allrot=allrot(allactive>0.5);
    alltasks=alltasks(allactive>0.5);
    alldepth=alldepth(allactive>0.5);
    
    %convert location to ML/AP coordinates
    allocs=cellfun(@(x) regexprep(x, 'A', '+'), allocs,'UniformOutput',false);
    allocs=cellfun(@(x) regexprep(x, 'P', '-'), allocs,'UniformOutput',false);
    allocs=cellfun(@(x) regexprep(x, 'L', '+'), allocs,'UniformOutput',false);
    allocs=cellfun(@(x) regexprep(x, 'M', '-'), allocs,'UniformOutput',false);
    
    coords=cellfun(@(x) [str2num([x(1),'1'])*str2num(x(2)) str2num([x(3),'1'])*str2num(x(4))] , allocs ,'UniformOutput',false); % regexpi(allocs,'\w', 'match')

    % for rotations, calculate new position
    %9 cw is our "0" for the MRI, so 54cw is actually a 45deg rotation
    hypoth54=cellfun(@(x) {x(1)/(cos(atan(x(2)/x(1))))},coords(strcmp(allrot,'54cw')));
    coords(strcmp(allrot,'54cw'))=cellfun(@(x,y) [round(cos(acos(y(1)/x)-pi/4)*x) -round(sin(acos(y(1)/x)-pi/4)*x)],...
        hypoth54,coords(strcmp(allrot,'54cw')),'UniformOutput',false);
    % same for 0cw
    hypoth0=cellfun(@(x) {x(1)/(cos(atan(x(2)/x(1))))},coords(strcmp(allrot,'0cw')));
    coords(strcmp(allrot,'0cw'))=cellfun(@(x,y) [round(cos(acos(y(1)/x)-pi/4)*x) round(sin(acos(y(1)/x)-pi/4)*x)],...
        hypoth54,coords(strcmp(allrot,'0cw')),'UniformOutput',false);
    
    %task index
    taskidx=zeros(length(alltasks),1);
    taskidx(strcmp(alltasks,'vg_saccades'))=0;
    taskidx(strcmp(alltasks,'optiloc'))=1;
    taskidx(strcmp(alltasks,'st_saccades'))=2;
    taskidx(strcmp(alltasks,'gapstop'))=3;
    taskidx(strcmp(alltasks,'tokens'))=4;
    
    %depth index
    depthidx=zeros(length(alldepth),1);
    if monknum==1
        cdn_depth=19000;
        bcx_depth=22000;
    elseif monknum==2
        cdn_depth=11000;
        bcx_depth=17000;
    end
    depthidx(alldepth<cdn_depth | alldepth>bcx_depth)=1;
    
    if monknum==1
        filename='Rigel_ElCoord';
    elseif monknum==1
        filename='Sixx_ElCoord';
    end
    
    
    fileID = fopen([filename,'.txt'],'w');
    fprintf(fileID,'%6.0f %6.0f %6.0f %6.0f %6.0f\r\n',([depthidx taskidx cell2mat(coords) alldepth])');
    fclose(fileID);
    
    %save([filename,'.txt'], 'pyElectrode_formated', '-ascii', '-double', '-tabs')
    
    
    
    
    
    
   
    
    
    
    
    