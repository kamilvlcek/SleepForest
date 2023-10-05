function out=ReadTR3d(FileNameIn)

%compute proportion of real path length to optimal one
%categorize tasks according to the demands/difficulty level

% to do: angles, summary data

PlotsInFigure=15;

out{1,1}=FileNameIn;
out{2,1}='trial';
out{2,2}='aim';
out{2,3}='animal';
out{2,4}='aim found';
out{2,5}='duration';
out{2,6}='length';
out{2,7}='path deviaton from optimal';
out{2,8}='errors';
out{2,9}='StartField';
out{2,10}='GoalField';
out{2,11}='N of trained pairs in sequence';
out{2,12}='N of turns in sequence';
out{2,13}='trial category Alena';
out{2,14}='angle indicated';
out{2,15}='angle real';
out{2,16}='angle error';
out{2,17}='trial category';


FileName=['d:\prace\mff\data\aappSeg\NUDZ\results\spanav\' FileNameIn '.tr'];


FileID=fopen(FileName);

SearchNum=0;
NL=0;line=[];
%while strcmp(line(1:6),' 0.000')==0
while isempty(strfind(line, 'Ukaz na'));
    line=fgetl(FileID);  %%%
    NL=NL+1;
    if strfind(line, 'Aim position')
        Aim=GetAimPositionsb(line); 
        AimX=Aim{1}; 
        AimY=Aim{2}; 
    end
    if strfind(line,'Avatar location changed:')     %%%
        ba=strfind(line, '[');
        bb=strfind(line, ',');
        bc=strfind(line, ']');
        StartLocX=str2num(line(ba+1:bb-1));
        StartLocY=str2num(line(bb+2:bc-1));
    end                                             %%%
end
n=strfind(line, 'text:Najdi');
Cil=line(n+11:end-2);
DLN=0;
firstdataline=0;
NumErr=0;

%figure

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
    if strfind(line,'space')
        Angle=str2num(line(k(7)+1:k(8)-1));
        Angle=rem(Angle,360);
        if Angle<0
            Angle=Angle+360;
        end
    end 
    if strfind(line,'Avatar location changed:')     %%%
        ba=strfind(line, '[');
        bb=strfind(line, ',');
        bc=strfind(line, ']');
        StartLocX=str2num(line(ba+1:bb-1));
        StartLocY=str2num(line(bb+2:bc-1));
    end                                             %%%
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
%     if strfind(line, 'Avoid entrance:') %%%
%         NumErr=NumErr+1;
%         n=strfind(line, 'Avoid entrance:');
%         ErrAim=line(n+15:n+19);
%         if strcmp(ErrAim(4),'A')
%             ErrBox(NumErr)=1;
%         end
%         if strcmp(ErrAim(4),'B')
%             ErrBox(NumErr)=2;
%         end
%         if strcmp(ErrAim(4),'C')
%             ErrBox(NumErr)=3;
%         end
%         if strcmp(ErrAim(4),'D')
%             ErrBox(NumErr)=4;
%         end
%         if strcmp(ErrAim(4),'E')
%             ErrBox(NumErr)=5;
%         end
%         if strcmp(ErrAim(4),'F')
%             ErrBox(NumErr)=6;
%         end        
%         if strcmp(ErrAim(4),'G')
%             ErrBox(NumErr)=7;
%         end
%         if strcmp(ErrAim(4),'H')
%             ErrBox(NumErr)=8;
%         end
%         if strcmp(ErrAim(4),'I')
%             ErrBox(NumErr)=9;
%         end        
%         ErrGoal(NumErr)=str2num(ErrAim(5));
%     end

    
    
    if length(strfind(line, 'Aim entrance:'))>0 || length(strfind(line, 'Aim not found:'))>0

        SearchNum=SearchNum+1;
        
        if strfind(line, 'Aim entrance:')
            n=strfind(line, 'Aim entrance:');
            CurrentAim=line(n+13:n+17); %%%
            AimFound=1;
        end
        if strfind(line, 'Aim not found:')
            n=strfind(line, 'Aim not found:');
            CurrentAim=line(n+14:n+18); %%%
            AimFound=0;
        end
        if strcmp(CurrentAim(4),'A')
            CurBox=1; %%%
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
%         CurrentAim %%%
%         CurrentAim(4) %%%
%         CurrentAim(5) %%%
        CurGoal=str2num(CurrentAim(5));
%         CurGoal %%%
        %figure 
        if rem(SearchNum,PlotsInFigure)==1
            figure('position', [50, 50, 900, 700])
        end
        PlotPosition=SearchNum;
        while PlotPosition>PlotsInFigure 
            PlotPosition=PlotPosition-PlotsInFigure;
        end
        subplot(3,5,PlotPosition)
        plot([AimX(1)+500 AimX(2)-500],[0-AimY(1) 0-AimY(2)],'k') %%%
        hold on
        plot([AimX(2)+500 AimX(3)-500],[0-AimY(2) 0-AimY(3)],'k')
        hold on
        plot([AimX(3) AimX(6)],[0-AimY(3)-500 0-AimY(6)+500],'k')
        hold on
        plot([AimX(6)-500 AimX(5)+500],[0-AimY(6) 0-AimY(5)],'k')
        hold on
        plot([AimX(5)-500 AimX(4)+500],[0-AimY(5) 0-AimY(4)],'k')
        hold on
        plot([AimX(4) AimX(7)],[0-AimY(4)-500 0-AimY(7)+500],'k')
        hold on
        plot([AimX(7)+500 AimX(8)-500],[0-AimY(7) 0-AimY(8)],'k')
        hold on
        plot([AimX(8)+500 AimX(9)-500],[0-AimY(8) 0-AimY(9)],'k')
        hold on
        plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'b')%%
%         ArenaLocX %%%
%         X %%%
        StartEndField=DetStartEndField(ArenaLocX(2:end),ArenaLocY(2:end),AimX,AimY); %find start and end field
        TrialType=DetTrialType([StartEndField(1) CurBox]);  %determine the type of test trial 
        for box=1:9
%           for i=1:6
%              hold on
             plot(AimX(box),0-AimY(box), '.k')
%           end
        end

        hold on
        plot(AimX(CurBox),0-AimY(CurBox), '.g') %%%
        for i=1:NumErr
             hold on
             plot(AimX(ErrBox(i),ErrGoal(i)),0-AimY(ErrBox(i),ErrGoal(i)), '.r') 
        end
        hold on
        plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k')
        hold on
        IndicatedAng=DistAng2Pos(400,Angle/360*2*3.141592653);
        plot([ArenaLocX(2) ArenaLocX(2)+IndicatedAng(1)],[0-ArenaLocY(2) 0-(ArenaLocY(2)+IndicatedAng(2))],'r', 'LineWidth',2)
        hold on
        plot(ArenaLocX(2),0-ArenaLocY(2), '.b')
        hold on
        plot(ArenaLocX(2)+IndicatedAng(1),0-(ArenaLocY(2)+IndicatedAng(2)), '.r');
        axis equal
        axis ij
        set ( gca, 'xdir', 'reverse' )
        axis off
        Duration=time(end)-time(2);
        Length=LengthofTrack(ArenaLocX(2:end),ArenaLocY(2:end));
%         ArenaLocX(2) %%%
%         ArenaLocY(2) %%%
%         CurBox %%%
%         CurGoal %%%
%         AimX(CurBox,CurGoal) %%%
%         AimY(CurBox,CurGoal) %%%
        ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),ArenaLocX(DLN),ArenaLocY(DLN));  %%%
%       ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),AimX(CurBox,CurGoal),AimY(CurBox,CurGoal));  %%%
        %ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),ArenaLocX(end),ArenaLocY(end));
        RealAngle=XY2ang(ArenaLocX(DLN)-ArenaLocX(2),ArenaLocY(DLN)-ArenaLocY(2))/(2*3.141592653)*360;
        %RealAngle=XY2ang(ArenaLocX(end)-ArenaLocX(2),ArenaLocY(end)-ArenaLocY(2))/(2*3.141592653)*360;
        AngleError=Angle-RealAngle;
        if AngleError>180
            AngleError=AngleError-360;
        end
        if AngleError<-180
            AngleError=AngleError+360;
        end
        %title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
        if SearchNum==1
            title([FileNameIn ' ' num2str(SearchNum)])
        else
            title([num2str(SearchNum)])
        end
        out{2+SearchNum,1}=SearchNum;
        out{2+SearchNum,2}=CurrentAim;
        out{2+SearchNum,3}=Cil;
        out{2+SearchNum,4}=AimFound;
        out{2+SearchNum,5}=Duration;
        out{2+SearchNum,6}=Length;
        out{2+SearchNum,7}=ToOptimalLength;
        out{2+SearchNum,8}=NumErr;
        out{2+SearchNum,9}=StartEndField(1);
        out{2+SearchNum,10}=CurBox;%StartEndField(2);
        out{2+SearchNum,11}=TrialType(2);
        out{2+SearchNum,12}=TrialType(3);
        out{2+SearchNum,13}=TrialType(4);
        out{2+SearchNum,14}=Angle;
        out{2+SearchNum,15}=RealAngle;
        out{2+SearchNum,16}=AngleError;
        out{2+SearchNum,17}=TrialType(1);
    end
end

%summary analysis

out{2+SearchNum+3,1}='trial category'; 
out{2+SearchNum+3,2}='description'; 
out{2+SearchNum+3,3}='N of trained pairs in sequence'; 
out{2+SearchNum+3,4}='N of turns in sequence';
out{2+SearchNum+3,5}='N'; %
out{2+SearchNum+3,6}='% aim found';%
out{2+SearchNum+3,7}='mean N errors';% 'Angle Error';
out{2+SearchNum+3,8}='mean path deviation';
out{2+SearchNum+3,9}='mean ABS angle error';

%memory for trained pairs (trial category 1) beginning
% NumTrainedPairsTests=0; NumAimFound=0; ErrTrainedPairsTests=0; PathDevTrainedPairsTests=0; AngleErrTrainedPairsTests=0;
% 
% for i=1:SearchNum
%    if out{2+i,17}==1;  
%        NumTrainedPairsTests=NumTrainedPairsTests+1;
%        NumAimFound=NumAimFound+out{2+i,4};
%        ErrTrainedPairsTests=ErrTrainedPairsTests+out{2+i,8};
%        PathDevTrainedPairsTests=PathDevTrainedPairsTests+out{2+i,7};
%        AngleErrTrainedPairsTests=AngleErrTrainedPairsTests+abs(out{2+i,16});
%    end
% end
% 
% out{2+SearchNum+4,1}='1';
% out{2+SearchNum+4,2}='memory for trained pairs';
% out{2+SearchNum+4,3}='1';
% out{2+SearchNum+4,4}='0';
% out{2+SearchNum+4,5}=NumTrainedPairsTests;
% out{2+SearchNum+4,6}=NumAimFound/NumTrainedPairsTests;
% out{2+SearchNum+4,7}=ErrTrainedPairsTests/NumTrainedPairsTests;
% out{2+SearchNum+4,8}=PathDevTrainedPairsTests/NumTrainedPairsTests;
% out{2+SearchNum+4,9}=AngleErrTrainedPairsTests/NumTrainedPairsTests;

%memory for trained pairs end

out{2+SearchNum+4,1}=1;
out{2+SearchNum+4,2}='trained pair';
out{2+SearchNum+4,3}=1;
out{2+SearchNum+4,4}=0;

out{2+SearchNum+5,1}=2;
out{2+SearchNum+5,2}='sequence of two trained pairs, straight';
out{2+SearchNum+5,3}=2;
out{2+SearchNum+5,4}=0;

out{2+SearchNum+6,1}=3;
out{2+SearchNum+6,2}='sequence of two trained pairs, with a turn';
out{2+SearchNum+6,3}=2;
out{2+SearchNum+6,4}=1;

out{2+SearchNum+7,1}=4;
out{2+SearchNum+7,2}='sequence of three trained pairs, with one turn';
out{2+SearchNum+7,3}=3;
out{2+SearchNum+7,4}=1;

out{2+SearchNum+8,1}=5;
out{2+SearchNum+8,2}='sequence of three trained pairs, with two turns';
out{2+SearchNum+8,3}=3;
out{2+SearchNum+8,4}=2;

out{2+SearchNum+9,1}=6;
out{2+SearchNum+9,2}='sequence of four trained pairs, (always with two turns)';
out{2+SearchNum+9,3}=4;
out{2+SearchNum+9,4}=2;

out{2+SearchNum+10,1}=7;
out{2+SearchNum+10,2}='sequence of five trained pairs, with two turns';
out{2+SearchNum+10,3}=5;
out{2+SearchNum+10,4}=2;

out{2+SearchNum+11,1}=8;
out{2+SearchNum+11,2}='sequence of five trained pairs, with three turns';
out{2+SearchNum+11,3}=5;
out{2+SearchNum+11,4}=3;

out{2+SearchNum+12,1}=9;
out{2+SearchNum+12,2}='sequence of six trained pairs, with three turns';
out{2+SearchNum+12,3}=6;
out{2+SearchNum+12,4}=3;

out{2+SearchNum+13,1}=10;
out{2+SearchNum+13,2}='sequence of six trained pairs, with four turns';
out{2+SearchNum+13,3}=6;
out{2+SearchNum+13,4}=4;

out{2+SearchNum+14,1}=11;
out{2+SearchNum+14,2}='sequence of seven trained pairs, (always with four turns)';
out{2+SearchNum+14,3}=7;
out{2+SearchNum+14,4}=4;

out{2+SearchNum+15,1}=12;
out{2+SearchNum+15,2}='sequence of eight trained pairs, (always with four turns)';
out{2+SearchNum+15,3}=8;
out{2+SearchNum+15,4}=4;


for TrialType=1:12
    NumTrainedPairsTests=0; NumAimFound=0; ErrTrainedPairsTests=0; PathDevTrainedPairsTests=0; AngleErrTrainedPairsTests=0;

    for i=1:SearchNum
        if out{2+i,17}==TrialType;  
            NumTrainedPairsTests=NumTrainedPairsTests+1;
            NumAimFound=NumAimFound+out{2+i,4};
            ErrTrainedPairsTests=ErrTrainedPairsTests+out{2+i,8};
            PathDevTrainedPairsTests=PathDevTrainedPairsTests+out{2+i,7};
            AngleErrTrainedPairsTests=AngleErrTrainedPairsTests+abs(out{2+i,16});
        end
    end

    out{2+SearchNum+3+TrialType,5}=NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,6}=NumAimFound/NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,7}=ErrTrainedPairsTests/NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,8}=PathDevTrainedPairsTests/NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,9}=AngleErrTrainedPairsTests/NumTrainedPairsTests;
end