try
    osInfo=computer('arch');
    if strfind(osInfo,'win')
        cd('D:\') % go to assumed CD drive on PC
    elseif strfind(osInfo,'mac')
        cd('...') % go to assumed CD drive on MAC
    end
        dirlisting=dir(); % list CD directory
catch % if that fails 
    disp('please select DICOM folder'); 
    folder_name = uigetdir('','please select DICOM folder'); %ask user for DICOM directory
end
if sum(~cellfun('isempty',strfind({dirlisting.name},'DICOM')))
    folder_name='D:\DICOM';
else 
    disp('please select DICOM folder');
    folder_name = uigetdir('','please select DICOM folder');
end

%ask user for output directory
output_folder_name = uigetdir('','please select folder to write to'); 

dirlisting=dir(folder_name);

%...

info = dicominfo([dir '\' dirlisting(3).name])

if strfind(info.SeriesDescription,'diff')
elseif ...
    I = dicomread(info);
    dicomwrite(I,[output_folder_name '\' filename],info)
end




