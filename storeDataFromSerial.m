function storeDataFromSerial(obj,event,handles)
global Ardu_serial_input
try
    while (get(Ardu_serial_input, 'BytesAvailable')~=0) % && tenzo == true
        % read until terminator
        sentence = fscanf( Ardu_serial_input, '%s')
        %decodes "sentence" seperated (delimted) by commas
%         decode(sentence);
        [Dnew, Dcount, Dmsg]=fread(obj)
        
        if Ardu_serial_input.UserData.isNew==0
    % indicate that we have new data
    Ardu_serial_input.UserData.isNew=1; 
    Ardu_serial_input.UserData.newData=Dnew;
    else
    % If the main loop has not had a chance to process the previous batch
    % of data, then append this new data to the previous "new" data
    Ardu_serial_input.UserData.newData=[Ardu_serial_input.UserData.newData Dnew];
    end
    end
catch
end
end

