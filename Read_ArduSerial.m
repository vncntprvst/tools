%For GUI, see http://stackoverflow.com/questions/8751590/matlab-gui-using-guide-want-to-dynamically-update-graphs?rq=1
global Ardu_serial_input session;

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

%% Setup device
% The serial port object must be opened for communication
if strcmp(Ardu_serial_input.Status,'closed'), fopen(Ardu_serial_input); end

% Send a command. The terminator character set above will be appended.
% fprintf(Ardu_serial_input,'WAKEUP');
% 
%% Read the response
session.MouseData.rew=0;
session.MouseData.frontcount=0;
session.MouseData.fronttime=[];
session.MouseData.leftcount=0;
session.MouseData.lefttime=[];
session.MouseData.rightcount=0;
session.MouseData.righttime=[];
session.gameon = true;
tic
session.timestart=toc;

timer_ardu = timer('ExecutionMode','FixedRate','Period',0.1,'TimerFcn',{@storeDataFromSerial}); %'TasksToExecute', 10, ... % Number of times to run the timer object                                                                                          %'timerOn=false; disp(''Updating GUI!'')', 'TimerFcn', {@GUIUpdate,handles}); 
start(timer_ardu);

disp ('Connection established.');

% while session.gameon == true && toc < 10
%     %wait
% end

% while session.gameon == false;
% wait(timer_ardu,'finished');

filename='s6_PrV25_1.mat'; %'session.mat'
save(filename,'session');
% load('session.mat')

stop(timer_ardu);
delete(timer_ardu);

% Close the serial port
fclose(Ardu_serial_input);
delete(Ardu_serial_input);
clear Ardu_serial_input;

disp ('End of session');

% return
% end

% figures
% left port vs right port
figure
plot(session.MouseData.lefttime,1:size(session.MouseData.lefttime,1))
hold on
plot(session.MouseData.righttime,1:size(session.MouseData.righttime,1))
legend('left port','right port')
xlabel('Time (s)')
ylabel('Reward count')

% time from front panel to reward port
% foo=round(session.MouseData.fronttime.*10);
% bla=mat2cell(round(session.MouseData.lefttime.*10),2);
% cellfun(@(x) x-find(foo(foo<x),'last'), )
% 
% for port=1:size(session.MouseData.fronttime,1)
%     fronttoporttime=session.MouseData.lefttime





