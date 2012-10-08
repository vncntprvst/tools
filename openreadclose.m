function filecontent=openreadclose(filename,dir)
    fileID=fopen([dir filename{:}]);
    filecontent=textscan(fileID,'%s');
    fclose(fileID);
end