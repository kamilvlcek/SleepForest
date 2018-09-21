function out=ReadTR2(FileName)

%compute proportion of real path length to optimal one
%categorize tasks according to the demands/difficulty level

out{1,1}=FileName;
out{2,1}='num';
out{2,2}='aim';
out{2,3}='animal';
out{2,4}='duration';
out{2,5}='length';
out{2,6}='errors';
out{2,7}='StartField';
out{2,8}='GoalField';
out{2,9}='N of trained pairs in sequence';
out{2,10}='N of turns in sequence';
out{2,11}='TrialType';

FileName=['C:\Unreal Anthology\SpaNav\sleepforest\SpaNav1.48 SleepForest aktuální\' FileName '.tr'];

FileID=fopen(FileName);

SearchNum=0;
NL=0;line=[];
%while strcmp(line(1:6),' 0.000')==0
while isempty(strfind(line, 'Ukaz na'));
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

X(1)=mean(AimX(1,:));Y(1)=mean(AimY(1,:));
X(2)=mean(AimX(2,:));Y(2)=mean(AimY(2,:));
X(3)=mean(AimX(3,:));Y(3)=mean(AimY(3,:));
X(4)=mean(AimX(4,:));Y(4)=mean(AimY(4,:));
X(5)=mean(AimX(5,:));Y(5)=mean(AimY(5,:));
X(6)=mean(AimX(6,:));Y(6)=mean(AimY(6,:));        
X(7)=mean(AimX(7,:));Y(7)=mean(AimY(7,:));
X(8)=mean(AimX(8,:));Y(8)=mean(AimY(8,:));
X(9)=mean(AimX(9,:));Y(9)=mean(AimY(9,:));

while feof(FileID)==0


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
%     if strfind(line,'space')
%         line
%     end
    %if strfind(line, 'Aim search')
    %end
    if strfind(line, 'text:Najdi')
        time=[];
        ArenaLocX=[];
        ArenaLocY=[];
        DLN=0;
        NumErr=0;
        ErrBox=[];
        ErrGoal=[];
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

        plot([X(1)+500 X(2)-500],[0-Y(1) 0-Y(2)],'k')
        hold on
        plot([X(2)+500 X(3)-500],[0-Y(2) 0-Y(3)],'k')
        hold on
        plot([X(3) X(6)],[0-Y(3)-500 0-Y(6)+500],'k')
        hold on
        plot([X(6)-500 X(5)+500],[0-Y(6) 0-Y(5)],'k')
        hold on
        plot([X(5)-500 X(4)+500],[0-Y(5) 0-Y(4)],'k')
        hold on
        plot([X(4) X(7)],[0-Y(4)-500 0-Y(7)+500],'k')
        hold on
        plot([X(7)+500 X(8)-500],[0-Y(7) 0-Y(8)],'k')
        hold on
        plot([X(8)+500 X(9)-500],[0-Y(8) 0-Y(9)],'k')
        hold on
        plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'b')
        StartEndField=DetStartEndField(ArenaLocX(2:end),ArenaLocY(2:end),X,Y); %find start and end field
        TrialType=DetTrialType(StartEndField);  %determine the type of test trial 
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
        out{2+SearchNum,7}=StartEndField(1);
        out{2+SearchNum,8}=StartEndField(2);
        out{2+SearchNum,9}=TrialType(2);
        out{2+SearchNum,10}=TrialType(3);
        out{2+SearchNum,11}=TrialType(1);
    end
end




