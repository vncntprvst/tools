function [aTokenDocs,aTokenSpreadsheet]=connectNAuthorize(userName)

if (nargin==1) && ischar(userName)
    S.GUSER = userName;
    clear userName;
else
    S.GUSER = [];
end
S.GPASS = [];
screenSize=get(0,'ScreenSize');
screenSize=screenSize(3:4);
S.fh = figure('units','pixels',...
    'position',[round(screenSize(1)/2)-150 round(screenSize(2)/2)-40 300 80],...
    'menubar','none',...
    'resize','off',...
    'numbertitle','off',...
    'name','Enter your Google credentials');
S.utx = uicontrol('style','text',...
    'units','pix',...
    'position',[5 45 80 20],...
    'string','User name:',...
    'fontweight','bold',...
    'horizontalalign','left',...
    'fontsize',11);
S.ptx = uicontrol('style','text',...
    'units','pix',...
    'position',[5 20 80 20],...
    'string','Password:',...
    'fontweight','bold',...
    'horizontalalign','left',...
    'fontsize',11);
S.ued = uicontrol('style','edit',...
    'units','pix',...
    'position',[90 45 200 20],...
    'backgroundcolor','w',...
    'tooltipstring',' Enter your user name here.',...
    'HorizontalAlign','left',...
    'String',S.GUSER,...
    'KeyPressFcn',{@ued_kpfcn,S});
S.ped = uicontrol('style','edit',...
    'units','pix',...
    'position',[90 20 200 20],...
    'backgroundcolor','w',...
    'tooltipstring',' Enter your password here.',...
    'HorizontalAlign','left',...
    'KeyPressFcn',{@ped_kpfcn,S});
set(S.ued,'KeyPressFcn',{@ued_kpfcn,S});
set(S.ped,'KeyPressFcn',{@ped_kpfcn,S});

if isempty(S.GUSER)
    uicontrol(S.ued);
else
    uicontrol(S.ped);
end
uiwait(S.fh);
S=rmfield(S,{'fh','utx','ptx','ued','ped'});

[aTokenDocs,authorized]=urlread('https://www.google.com/accounts/ClientLogin','POST',...
    {'Email',S.GUSER,'Passwd',S.GPASS,'source','CAG-Matlab-1','service','writely'});
if authorized==1
    aTokenDocs=['auth' aTokenDocs(strfind(aTokenDocs,'Auth')+4:end-1)];
    clear authorized;
else
    aTokenDocs='';
end
[aTokenSpreadsheet,authorized]=urlread('https://www.google.com/accounts/ClientLogin','POST',...
    {'Email',S.GUSER,'Passwd',S.GPASS,'source','CAG-Matlab-1','service','wise'});
if authorized==1
    aTokenSpreadsheet=['auth' aTokenSpreadsheet(strfind(aTokenSpreadsheet,'Auth')+4:end-1)];
    clear authorized;
else
    aTokenSpreadsheet='';
end

    function [] = ped_call(varargin)
        close(S.fh)
    end

    function [] = ued_kpfcn(varargin)
        [h,S] = varargin{[1,3]};
        CC = get(S.fh,'currentcharacter');
        num = int8(CC);
        
        if num == 13  % This is a carriage return.
            uicontrol(S.ped);
            return
        end
        
        E = get(h,'string');  % the string of the edit box.
        % Any key handling other than the return key should be handled
        % in the following if else block.
        if num == 8  % Backspace pressed, update password and screen.
            set(h,'string',E(1:end-1));
            S.GUSER = S.GUSER(1:end-1);
        elseif num == 127  % The Delete Key: do nothing.
            % On some systems this will delete the symbols.  How would you
            % prevent this?
        elseif ~isempty(num)
            S.GUSER = [S.GUSER CC];
        end
        % Update the structure.
        set(S.ued,'KeyPressFcn',{@ued_kpfcn,S});
        set(S.ped,'KeyPressFcn',{@ped_kpfcn,S});
    end

    function [] = ped_kpfcn(varargin)
        [h,S] = varargin{[1,3]};  % Get calling handle and structure.
        % Deals with user input.
        CC = get(S.fh,'currentcharacter');  % The character user entered.
        num = int8(CC);
        
        if num == 13  % This is a carriage return.
            set(S.ped,'callback',{@ped_call,S});
            return
        end
        
        E = get(h,'string');  % the string of the edit box.
        % Any key handling other than the return key should be handled
        % in the following if else block.
        if num == 8  % Backspace pressed, update password and screen.
            set(h,'string',E(1:end-1));
            S.GPASS = S.GPASS(1:end-1);
        elseif num == 127  % The Delete Key: do nothing.
            % On some systems this will delete the symbols.  How would you
            % prevent this?
        elseif ~isempty(num)
            set(h,'string',[E,'*'])  ;  % Print out an asterisk in gui.
            S.GPASS = [S.GPASS CC];
        end
        % Update the structure.
        set(S.ued,'KeyPressFcn',{@ued_kpfcn,S});
        set(h,'KeyPressFcn',{@ped_kpfcn,S});
    end
end