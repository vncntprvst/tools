function SHdaq2mat()

%SHdaq2mat converts the daq files recorded with SH to .mat format
%SHdaq2mat get the trigger timestamps from the trigger channel (ie,
%channel 1, then delete Ch1 data to reduce file size.

%% select files to convert
clear all;
DirInfo = dir('*.daq');
filedates = datenum(cat(1,DirInfo(:).datenum));
[maxdate, index] = max(filedates);
recentf=DirInfo(index).name;
[daqfilenames, pathname, filterindex] = uigetfile( ...
    {'*.daq'},'File Selector',recentf,...
    'MultiSelect','on');  % add 'defaultpath'

if filterindex==0
    disp('conversion canceled');
    return
end
if length(char(daqfilenames(1)))==1
    numfiles=1;
else
    numfiles = length (daqfilenames);
end
clear filterindex pathname;
rm_ch_save(daqfilenames, numfiles);

end
%% processing and save files 
    function rm_ch_save(filenames,nbfiles)
        
        for f=1:nbfiles
            if nbfiles==1
                daqfilename=char(filenames);
            else
                daqfilename=char(filenames(f));
            end
            daqinfo=daqread(daqfilename,'info');
            nbsamples=daqinfo.ObjInfo.SamplesAcquired;
            samplerate=daqinfo.ObjInfo.SampleRate;
            nbchan=length(daqinfo.ObjInfo.Channel); %checking there are two channels
            infofilename=cat(2,daqfilename(1:find(daqfilename=='.')-1),'_info.txt');
            if exist(infofilename)
                contxtinfo = importdata(infofilename);
            else
                contxtinfo = 'none';
            end
            
            %% if there's a trigger channel
            if nbchan==2
                
                try
                    fulltrigdat=daqread(daqfilename,'Channels',2);
                catch cangetfulltrigdat
                    fulltrigdat=0;
                end
                trigdat=zeros(250,1);
                trigtime=[];
                trignb=1;
                splittrig=0;
                for i=1:samplerate:(floor(nbsamples/samplerate)*samplerate)
                    if fulltrigdat
                        trigdat=fulltrigdat(i:i+samplerate-1);
                    else
                        trigdat=daqread(daqfilename,'Channels',2,'Samples',[i i+samplerate-1]);
                    end
                    trigdat(trigdat>4)=5;
                    trigdat(trigdat<4)=0;
                    trigdat=bwlabeln(trigdat);
                    
                    if max(trigdat)
                        %                  if trignb== 1 || trignb==19 || trignb==21 || trignb==39
                        %                      trignb % used to check a few suspicious trials
                        %                  end
                        for k=1:max(trigdat)
                            if length(trigdat(trigdat==i))==1 %just artifact, not trigger
                                trigdat(trigdat==i)=0;
                            end
                        end
                    end
                    
                    if splittrig
                        splittrig=0;
                        if find(trigdat==1,1)==1 %in case end of last loop was high state already !!!!
                            trigtime(trignb-1,2)=i+find(trigdat==1,1,'last')-1;
                            if find(trigdat==1,1,'last')==samplerate
                                break;
                            end
                            if max(trigdat)>1 % case where there would be other triggers after split one
                                for j=2:max(trigdat)
                                    trigtime(trignb,1)=i+find(trigdat==j,1)-1;
                                    trigtime(trignb,2)=i+find(trigdat==j,1,'last')-1;
                                    trignb=trignb+1;
                                end
                                
                            end
                            splittrig=1;
                        else
                            splittrig=0;
                        end
                    end
                    
                    if max(trigdat) && ~splittrig
                        for j=1:max(trigdat)
                            if ~isempty(find(trigdat==j,1))
                                trigtime(trignb,1)=i+find(trigdat==j,1)-1;
                                trigtime(trignb,2)=i+find(trigdat==j,1,'last')-1;
                                trignb=trignb+1;
                            end
                        end
                        if find(trigdat==j,1,'last')==samplerate
                            splittrig=1;
                        else
                            splittrig=0;
                        end
                    end
                    
                end
                
                %% finish the last bit (if any remains)
                if nbsamples-(i+samplerate)
                    lastchunck=i+samplerate;
                    if fulltrigdat
                        trigdat=fulltrigdat(lastchunck:nbsamples);
                    else
                        trigdat=daqread(daqfilename,'Channels',2,'Samples',[lastchunck nbsamples]);
                    end
                    trigdat(trigdat>4)=5;
                    trigdat(trigdat<4)=0;
                    trigdat=bwlabeln(trigdat);
                    
                    if max(trigdat)
                        for k=1:max(trigdat)
                            if length(trigdat(trigdat==i))==1 %just artifact, not trigger
                                trigdat(trigdat==i)=0;
                            end
                        end
                    end
                    
                    if splittrig
                        splittrig=0;
                        if find(trigdat==1,1)==1 %in case end of last loop was high state already !!!!
                            trigtime(trignb-1,2)=i+find(trigdat==1,1,'last')-1;
                            if find(trigdat==1,1,'last')==samplerate
                                break;
                            end
                            if max(trigdat)>1 %rare case where there would be two successive triggers
                                for j=2:max(trigdat)
                                    trigtime(trignb,1)=i+find(trigdat==j,1)-1;
                                    trigtime(trignb,2)=i+find(trigdat==j,1,'last')-1;
                                    trignb=trignb+1;
                                end
                            end
                            splittrig=1;
                        end
                    end
                    
                    if max(trigdat) && ~splittrig
                        for j=1:max(trigdat)
                            if ~isempty(find(trigdat==j,1))
                                trigtime(trignb,1)=i+find(trigdat==j,1)-1;
                                trigtime(trignb,2)=i+find(trigdat==j,1,'last')-1;
                                trignb=trignb+1;
                            end
                        end
                        if find(trigdat==j,1,'last')==samplerate
                            splittrig=1;
                        else
                            splittrig=0;
                        end
                    end
                end
            end
            
            %% find trial sequence
            
            trialseq=findtrialsseq(trigtime, daqfilename);
            
            %% saving data
            try
                data = daqread(daqfilename,'Channels',1);
                %clear time j trigdat infofilename;
                %varlist=who;
                %varlist=varlist([1 2 4 5 6]);%remove daqfilename and other useless variables from the list of variables to save
                save(cat(2,daqfilename(1:find(daqfilename=='.')-1),'_cv.mat'),'contxtinfo','daqinfo','data','trigtime','trialseq');
                fclose('all');
                clear daqfilename data time abstime events daqinfo infofilename contxtinfo nbchan trigdat trigtime;
            catch
                fprintf('error (or out of memory) while opening file %s\n',daqfilename);
            end
        end
    end
%% additional code to try to find the trials sequence
    function trialseq=findtrialsseq(trigtime, daqfilename)
        trialseq=[];
        trigdur=nan(length(trigtime),1);
        for i=1:length(trigdur)
            trigdur(i)=trigtime(i,2)-trigtime(i,1);
        end
        
        if round(max(trigdur)/1000)==round(min(trigdur)/1000)
            % triggers correctly detected (no trial detected as trigger)
            % should be around 4000, at 40kHz sampling rate
            
            trigspacing=nan(length(trigtime)-1,1);
            for i=1:length(trigspacing)
                trigspacing(i)=trigtime(i+1,1)-trigtime(i,1); %time between onset of 
            end
            %trigspacing=trigspacing(~isnan(trigspacing));
            triallengthratio=median(trigspacing(1:2:length(trigspacing)))/median(trigspacing(2:2:length(trigspacing)));
            if triallengthratio>0
                % odd seq numbers are trials (this is the most likely situation) 
                trialseq=[trigtime(1:2:end,1) trigtime(2:2:end,1)]; 
            elseif triallengthratio<0
                % even seq then
                trialseq=[trigtime(2:2:end,1) trigtime(3:2:end,1)]; 
            else 
                str = sprintf('couldnt detect trial sequence for file %s',daqfilename);
                disp(str);
                return
            end
            
        else
            %maybe started with split trigger
            alttrigdur=nan(length(trigtime),1);
            for i=1:length(alttrigdur)-1
                alttrigdur(i)=trigtime(i+1,1)-trigtime(i,2);
            end
            
            if round(max(alttrigdur)/1000)==round(min(alttrigdur)/1000)
                
                trigspacing=nan(length(trigtime),1);
                for i=1:length(trigspacing)
                    trigspacing(i)=trigtime(i,2)-trigtime(i,1);
                end
            trigspacing=trigspacing(~isnan(trigspacing));
            triallengthratio=median(trigspacing(1:2:length(trigspacing)))/median(trigspacing(2:2:length(trigspacing)));
            if triallengthratio>0
                % odd seq numbers are trials (this is the most likely situation) 
                trialseq=[trigtime(1:2:end,2) trigtime(2:2:end,2)]; 
            elseif triallengthratio<0
                % even seq then
                trialseq=[trigtime(2:2:end,2) trigtime(3:2:end,2)]; 
            else 
                str = sprintf('couldnt detect trial sequence for file %s',daqfilename);
                disp(str);
                return
            end
                
            else
                str = sprintf('couldnt detect trial sequence for file %s',daqfilename);
                disp(str);
                return
            end
        end
        
    end
