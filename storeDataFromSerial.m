function storeDataFromSerial(obj,event,handles)
global Ardu_serial_input session;
% sound def
sounddur=10000;
s=zeros(sounddur,1);
for freqval=1:sounddur
    s(freqval)=sin(-freqval/10);
    % s(a)=tan(a)*sin(-a/10);
end
Freq=20000; %increase value to speed up the sound, decrease to slow it down

try
    while (get(Ardu_serial_input, 'BytesAvailable')~=0) && session.gameon == true
        % read until terminator
        sentence = fscanf( Ardu_serial_input, '%s');
        %decodes "sentence" seperated (delimted) by commas
        %         decode(sentence);
        if strcmp(sentence,'OpenLeftSolenoid')
            session.MouseData.leftcount=session.MouseData.leftcount+1;
            session.MouseData.rew=session.MouseData.rew+1;
            session.MouseData.lefttime=...
                [session.MouseData.lefttime;toc];
        elseif strcmp(sentence,'OpenRightSolenoid')
            session.MouseData.rightcount=session.MouseData.rightcount+1;
            session.MouseData.rew=session.MouseData.rew+1;
            session.MouseData.righttime=...
                [session.MouseData.righttime;toc];
        elseif strcmp(sentence,'Frontpanelexplored') %Front:DoubleReward!
            %play sound
            soundsc(s,Freq)
            session.MouseData.frontcount=session.MouseData.frontcount+1;
%             session.MouseData.rew=session.MouseData.rew+2;
            session.MouseData.fronttime=...
                [session.MouseData.frontime;toc];
        end
        
        if session.MouseData.rew > 400 || toc > 3600
            session.gameon = false;
            disp ('Timeout: Connection ended');
        end
        
    end
catch
end
end
