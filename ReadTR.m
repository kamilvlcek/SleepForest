function out=ReadTR(FileName)

%compute proportion of real path length to optimal one
%categorize tasks according to the demands/difficulty level

out{1,1}=FileName;
out{2,1}='num';
out{2,2}='aim';
out{2,3}='animal';
out{2,4}='duration';
out{2,5}='length';
out{2,6}='errors';


FileName=['C:\Users\kelemen\DATA\VR\' FileName '.tr'];

FileID=fopen(FileName);

SearchNum=0;
NL=0;line=[];
%while strcmp(line(1:6),' 0.000')==0
while isempty(strfind(line, 'text:Najdi'));
    line=fgetl(FileID);
    NL=NL+1;
    if strfind(line, 'Aim position')
        Aim=GetAimPositions(line);
        AimX=Aim{1};
        AimY=Aim{2};
    end
end
n=strfind(line, 'text:Najdi');
Cil=line(n+11:end-2);
DLN=0;
firstdataline=0;
NumErr=0;
while feof(FileID)==0
%while isempty(strfind(line, 'text:VYBORNE !'));

    line=fgetl(FileID);
    NL=NL+1;
    if strcmp(line(1),' ')
        DLN=DLN+1;
        if firstdataline==0
            divider=line(7);
            firstdataline=1;
        end
        k=strfind(line, divider);
        time(DLN)=str2num(line(2:k(1)-1));
        ArenaLocX(DLN)=str2num(line(k(2)+1:k(3)-1));
        ArenaLocY(DLN)=str2num(line(k(3)+1:k(4)-1));
    end   
    if strfind(line, 'Aim search')
        time=[];
        ArenaLocX=[];
        ArenaLocY=[];
        DLN=0;
        NumErr=0;
        ErrBox=[];
        ErrGoal=[];
    end
    if strfind(line, 'text:Najdi')
        n=strfind(line, 'text:Najdi');
        Cil=line(n+11:end-2);
    end 
    if strfind(line, 'Avoid entrance:')
        NumErr=NumErr+1;
        n=strfind(line, 'Avoid entrance:');
        ErrAim=line(n+15:n+19);
        if strcmp(ErrAim(4),'A')
            ErrBox(NumErr)=1;
        end
        if strcmp(ErrAim(4),'B')
            ErrBox(NumErr)=2;
        end
        if strcmp(ErrAim(4),'C')
            ErrBox(NumErr)=3;
        end
        if strcmp(ErrAim(4),'D')
            ErrBox(NumErr)=4;
        end
        if strcmp(ErrAim(4),'E')
            ErrBox(NumErr)=5;
        end
        if strcmp(ErrAim(4),'F')
            ErrBox(NumErr)=6;
        end        
        if strcmp(ErrAim(4),'G')
            ErrBox(NumErr)=7;
        end
        if strcmp(ErrAim(4),'H')
            ErrBox(NumErr)=8;
        end
        if strcmp(ErrAim(4),'I')
            ErrBox(NumErr)=9;
        end        
        ErrGoal(NumErr)=str2num(ErrAim(5));
    end
    if strfind(line, 'Aim entrance:')
        SearchNum=SearchNum+1;
        n=strfind(line, 'Aim entrance:');
        CurrentAim=line(n+13:n+17);
        if strcmp(CurrentAim(4),'A')
            CurBox=1;
        end
        if strcmp(CurrentAim(4),'B')
            CurBox=2;
        end
        if strcmp(CurrentAim(4),'C')
            CurBox=3;
        end
        if strcmp(CurrentAim(4),'D')
            CurBox=4;
        end
        if strcmp(CurrentAim(4),'E')
            CurBox=5;
        end
        if strcmp(CurrentAim(4),'F')
            CurBox=6;
        end        
        if strcmp(CurrentAim(4),'G')
            CurBox=7;
        end
        if strcmp(CurrentAim(4),'H')
            CurBox=8;
        end
        if strcmp(CurrentAim(4),'I')
            CurBox=9;
        end        
        CurGoal=str2num(CurrentAim(5));
        figure        
        X1=mean(AimX(1,:));Y1=mean(AimY(1,:));
        X2=mean(AimX(2,:));Y2=mean(AimY(2,:));
        X3=mean(AimX(3,:));Y3=mean(AimY(3,:));
        X4=mean(AimX(4,:));Y4=mean(AimY(4,:));
        X5=mean(AimX(5,:));Y5=mean(AimY(5,:));
        X6=mean(AimX(6,:));Y6=mean(AimY(6,:));        
        X7=mean(AimX(7,:));Y7=mean(AimY(7,:));
        X8=mean(AimX(8,:));Y8=mean(AimY(8,:));
        X9=mean(AimX(9,:));Y9=mean(AimY(9,:));
        plot([X1+500 X2-500],[0-Y1 0-Y2],'k')
        hold on
        plot([X2+500 X3-500],[0-Y2 0-Y3],'k')
        hold on
        plot([X3 X6],[0-Y3-500 0-Y6+500],'k')
        hold on
        plot([X6-500 X5+500],[0-Y6 0-Y5],'k')
        hold on
        plot([X5-500 X4+500],[0-Y5 0-Y4],'k')
        hold on
        plot([X4 X7],[0-Y4-500 0-Y7+500],'k')
        hold on
        plot([X7+500 X8-500],[0-Y7 0-Y8],'k')
        hold on
        plot([X8+500 X9-500],[0-Y8 0-Y9],'k')
        hold on
        plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'b')
        for box=1:9
          for i=1:6
             hold on
             plot(AimX(box,i),0-AimY(box,i), 'ok')
          end
        end

        
        hold on
        plot(AimX(CurBox,CurGoal),0-AimY(CurBox,CurGoal), 'og')
        for i=1:NumErr
             hold on
             plot(AimX(ErrBox(i),ErrGoal(i)),0-AimY(ErrBox(i),ErrGoal(i)), 'or') 
        end
        hold on
        plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k')
        axis equal
        axis off
        Duration=time(end)-time(2);
        Length=LengthofTrack(ArenaLocX(2:end),ArenaLocY(2:end));
        title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
        out{2+SearchNum,1}=SearchNum;
        out{2+SearchNum,2}=CurrentAim;
        out{2+SearchNum,3}=Cil;
        out{2+SearchNum,4}=Duration;
        out{2+SearchNum,5}=Length;
        out{2+SearchNum,6}=NumErr;
    end
end





%RatFile = ['C:\Users\kelemen\DATA\robotavoidance\' RatFileName '.dat'];
% RatFileID=fopen(RatFile);
% 
% %%%
% line=[];NHL=0;
% while strcmp(line,'%%END_HEADER')==0
%     NHL=NHL+1;
%     line=fgetl(RatFileID);
%     k=strfind(line, ' %RobotZone');
%     if ~isempty(k)
%         ShSecPos=ShockSecPos(line(k+12:end));
%     end
% end
% if ShSecPos(4)==0
%     ShockZoneLoc='F';
% end
% if ShSecPos(4)==90
%     ShockZoneLoc='R';
% end
% if ShSecPos(4)==180
%     ShockZoneLoc='B';
% end
% if ShSecPos(4)==270
%     ShockZoneLoc='L';
% end
% %%%
% 
% 
% RatData = textscan(RatFileID, '%d %d %f %f %f %d %d %d');
% 
% 
% timeMs=RatData{2};
% RatX=RatData{3};
% RatY=RatData{4};
% RatA=RatData{6};