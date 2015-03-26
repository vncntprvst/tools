%For GUI, see http://stackoverflow.com/questions/8751590/matlab-gui-using-guide-want-to-dynamically-update-graphs?rq=1
global Ardu_serial_input
Ardu_serial_input = serial('COM4');%,'baudrate',9600,'terminator','CR');%'tag','Quad'

% You will have to set the serial port settings 
Ardu_serial_input.BaudRate=9600;
% Termination character for data sequences
Ardu_serial_input.Terminator='CR';
% The byte order is important for interpreting binary data
Ardu_serial_input.ByteOrder='bigEndian';


%% Prepare for the data stream
Ardu_serial_input.InputBufferSize=512; % in bytes
% The "BytesAvailableFcn" function will be called whenever
%  BytesAvailableFcnCount number of bytes have been received from the USB
%  device.
Ardu_serial_input.BytesAvailableFcnMode='byte';
Ardu_serial_input.BytesAvailableFcnCount=1; % 1 kB of data

% The name of the BytesAvailableFcn function in this example is
%  "getNewData", and it has one additional input argument ("arg1").
% Ardu_serial_input.BytesAvailableFcn = {@storeDataFromSerial,arg1};

%% 3. Setup your device
% The serial port object must be opened for communication
if strcmp(Ardu_serial_input.Status,'closed'), fopen(Ardu_serial_input); end

% Send a command. The terminator character set above will be appended.
% fprintf(Ardu_serial_input,'WAKEUP');
% 
% Read the response
response = fscanf(Ardu_serial_input);
response

fclose(Ardu_serial_input)

% % When the connect to serial button is pressed
timer_ardu = timer('ExecutionMode','FixedRate','Period',0.1,'TimerFcn',{@storeDataFromSerial}); %'TasksToExecute', 10, ... % Number of times to run the timer object                                                                                          %'timerOn=false; disp(''Updating GUI!'')', 'TimerFcn', {@GUIUpdate,handles}); 
start(timer_ardu);
% Polling
% fprintf(Ardu_serial_input,'M') ; 
disp ('Connection established.');

stop(timer_ardu);
delete(timer_ardu);

% delete(instrfindall);



% Use the serial port object to pass data between your main function
%  and the serial port function ("getNewData").
% You could include things like total number of data points read,
%  timestamps, etc, here as well.
Ardu_serial_input.UserData.newData=[];
Ardu_serial_input.UserData.isNew=0;

%% 5. Process the incoming data
% In this example, we use a loop to plot the data stream that is sent by
% the USB device.

% A global variable is used to exit the loop
global PLOTLOOP; PLOTLOOP=1;
% Initialize data for plotting. "plotWindow" will be the length of the
%  x-axis in the data plot.
plotData=zeros(plotWindow);
newData=[];
% Create figure for plotting
pfig = figure;
% This allows us to stop the test by pressing a key
set(pfig,'KeyPressFcn', @stopStream); 

% Send commands to the device to start the data stream.
fprintf(Ardu_serial_input,'START');

while PLOTLOOP

      % wait until we have new data
      if Ardu_serial_input.UserData.isNew==1

          % get the data from serial port object (data will be row-oriented)    
          newData=mr.UserData.newData';

          % indicate that data has been read
          mr.UserData.isNew=0;

          % concatenate new data for plotting
          plotData=[plotData(size(newData,1)+1:end,:); newData];

          % plot the data
          plot(pfig,plotData);

          drawnow;
      end

      % The loop will exit when the user presses return, using the
      %  KeyPressFcn of the plot window

end

%% 6. Finish & Cleanup
% Add whatever commands are required for closing your device.

% Send commands to the device stop the data transmission
fprintf(Ardu_serial_input,'STOP');

% flush the input buffer
ba=get(Ardu_serial_input,'BytesAvailable');
if ba > 0, fread(mr,ba); end

% Close the serial port
fclose(Ardu_serial_input);
delete(Ardu_serial_input);

return


