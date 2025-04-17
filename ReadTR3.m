function out=ReadTR3(FileNameIn,TrajectoriesToShow)
if exist('TrajectoriesToShow','var')~=1, TrajectoriesToShow=[]; end
%analysis of training and test trials
%compute proportion of real path length to optimal one
%categorize tasks according to the demands/difficulty level

% to do: angles, summary data

SearchAnimal=0; % added March 6 2024
PlotsInFigure=15;
NumTr(3,3)=zeros;NumTrB(3,3)=zeros; NumTrE(3,3)=zeros;
NumAimFound(3,3)=zeros; NumAimFoundB(3,3)=zeros; NumAimFoundE(3,3)=zeros;
TotNumErr(3,3)=zeros; TotNumErrB(3,3)=zeros; TotNumErrE(3,3)=zeros;
SumPathDev(3,3)=zeros; SumPathDevB(3,3)=zeros; SumPathDevE(3,3)=zeros; % 'path deviation';
SumAbsAngErr(3,3)=zeros; SumAbsAngErrB(3,3)=zeros; SumAbsAngErrE(3,3)=zeros;
SumOptToRealPath(3,3)=zeros; SumOptToRealPathB(3,3)=zeros; SumOptToRealPathE(3,3)=zeros; % 'path efficiency';
stav=0; %1-ukazovani, 2-hledani Added March 11, 2024

%8.4.2024 chci aby vstupni parametr FileName obsahoval kompletni cestu, prehozeno pred out= 8.4.2024
FileName = FileNameIn; % complete trajectory
FileNameIn = basename(FileName); % only filename
%FileName=['d:\prace\mff\data\aappSeg\NUDZ\results\spanav\' FileNameIn '.tr'];
%FileName=['D:\Users\kelemen\Data\VRKamil\' FileNameIn '.tr'];

out{1,1}=FileNameIn;
out{2,1}='trial';
out{2,2}='aim';
out{2,3}='animal';
out{2,4}='North marked';
out{2,5}='Statues present';
out{2,6}='aim found';
out{2,7}='duration';
out{2,8}='length';
out{2,9}='path deviaton from optimal';
out{2,10}='errors';
out{2,11}='StartField';
out{2,12}='GoalField';
out{2,13}='N of trained pairs in sequence';
out{2,14}='N of turns in sequence';
out{2,15}='trial type';
out{2,16}='angle indicated';
out{2,17}='angle real';
out{2,18}='angle error';
out{2,19}='path efficiency';

FileID=fopen(FileName);

SearchNum=0;
NL=0;line=[];

while isempty(strfind(line, 'KOLO')) 
    line=fgetl(FileID);  %%%
    NL=NL+1;
    if strfind(line, 'Aim position')
        Aim=GetAimPositionsb(line); 
        AimX=Aim{1}; 
        AimY=Aim{2}; 
    end
end

DLN=0;
firstdataline=0;
NumErr=0;
LastMeasuresForAim = zeros(9,3); %columns: 'duration', 'path efficiency' 'angle error', rows: CurBox 1-9 (tj aims), kamil 7.6.2024

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
    if strfind(line,'Avatar location changed:')     %%%
        ba=strfind(line, '[');
        bb=strfind(line, ',');
        bc=strfind(line, ']');
        StartLocX=str2num(line(ba+1:bb-1));
        StartLocY=str2num(line(bb+2:bc-1));
    end    
    if strfind(line, 'Orientation Marks Shown') %%%
        PosNA=strfind(line, 'North Compas');
        NorthArrow=str2num(line(PosNA+13));
        PosSt=strfind(line, 'Statues');
        Statues=str2num(line(PosSt+10));
        if NorthArrow==1 && Statues==0
            Cues=1;
        end
        if NorthArrow==0 && Statues==1
            Cues=2;
        end
        if NorthArrow==1 && Statues==1  %% 27 Dec 2024
            Cues=3;                     %% 27 Dec 2024
        end                             %% 27 Dec 2024
    end
    if strfind(line, 'Aim search:')
        n=strfind(line, 'Aim search:');
        CurrentAim=line(n+11:n+14); %%%
    end
    if strfind(line,'Ukazte na')
        stav=1; %1-ukazovani, 2-hledani
    end 
    if contains(line,'space') && stav==1
        Angle=str2num(line(k(7)+1:k(8)-1));
        Angle=rem(Angle,360);
        if Angle<0
            Angle=Angle+360;
        end
    end 
                                        %%%
    if strfind(line, 'text:Najdete')
        stav=2;
        time=[];
        ArenaLocX=[];
        ArenaLocY=[];
        DLN=0;
        NumErr=0;
        ErrLocX=[];
        ErrLocY=[];
        n=strfind(line, 'text:Najdete');
        Cil=line(n+13:end-2);
        SearchAnimal=1; % added March 6 2024
    end 


    if strfind(line, 'CHYBA !')
      NumErr=NumErr+1;
      ErrLocX(NumErr)=ArenaLocX(DLN);
      ErrLocY(NumErr)=ArenaLocY(DLN);
    end
        
    if (length(strfind(line, 'VYBORNE !'))>0 || length(strfind(line, 'NEPOVEDLO SE VAM NAJIT CIL'))>0) && SearchAnimal==1 % modified March 6 2024
        SearchAnimal=0; % added March 6 2024
        SearchNum=SearchNum+1;
        if strfind(line, 'VYBORNE !') 
            AimFound=1; 
        end
        if strfind(line, 'NEPOVEDLO SE VAM NAJIT CIL') 
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

        %figure 
        if rem(SearchNum,PlotsInFigure)==1
            figure('Name','All trials','position', [50, 50, 900, 700])
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
        Trajectories{SearchNum}=[ArenaLocX;ArenaLocY];

        StartEndField=DetStartEndField(ArenaLocX(2:end),ArenaLocY(2:end),AimX,AimY); %find start and end field

        TrialType=DetTrialType([StartEndField(1) CurBox]);  %determine the type of test trial 
        TrialTypeKE=DetTrialTypeKamilEliska([StartEndField(1) CurBox]);  %determine the type of test trial 
        for box=1:9
             plot(AimX(box),0-AimY(box), '.k')
        end

        hold on
        plot(AimX(CurBox),0-AimY(CurBox), '.g') %%%
        EndBoxes{SearchNum}=[AimX(CurBox),AimY(CurBox)];
        for i=1:NumErr
             hold on
             plot(ErrLocX(i), 0-ErrLocY(i),'.r')
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
        IndicatedAngles{SearchNum}=IndicatedAng;
        axis equal
        axis ij
        set ( gca, 'xdir', 'reverse' )
        axis off
        Duration=time(end)-time(2);
        Length=LengthofTrack(ArenaLocX(2:end),ArenaLocY(2:end));

        ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),ArenaLocX(DLN),ArenaLocY(DLN));
        RealAngle=XY2ang(ArenaLocX(DLN)-ArenaLocX(2),ArenaLocY(DLN)-ArenaLocY(2))/(2*3.141592653)*360;
        AngleError=Angle-RealAngle;
        if AngleError>180
            AngleError=AngleError-360;
        end
        if AngleError<-180
            AngleError=AngleError+360;
        end
        %title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
        if SearchNum==1
            title([FileNameIn ' ' num2str(SearchNum)],'Interpreter', 'none')
        else
            title([num2str(SearchNum)])
        end
        out{2+SearchNum,1}=SearchNum;
        out{2+SearchNum,2}=CurrentAim;
        out{2+SearchNum,3}=Cil;
        out{2+SearchNum,4}=NorthArrow;
        out{2+SearchNum,5}=Statues;
        out{2+SearchNum,6}=AimFound;
        out{2+SearchNum,7}=Duration;
        out{2+SearchNum,8}=Length;
        out{2+SearchNum,9}=ToOptimalLength; %'path deviaton from optimal';
        out{2+SearchNum,10}=NumErr;
        out{2+SearchNum,11}=StartEndField(1);
        out{2+SearchNum,12}=CurBox; %'GoalField'
        out{2+SearchNum,13}=TrialType(2);
        out{2+SearchNum,14}=TrialType(3);
        out{2+SearchNum,15}=TrialTypeKE;
        out{2+SearchNum,16}=Angle;
        out{2+SearchNum,17}=RealAngle;
        out{2+SearchNum,18}=AngleError;
        out{2+SearchNum,19}=1/ToOptimalLength; %kamil 8.4.2024 'path efficiency';
        
        NumTr(TrialTypeKE,Cues)=NumTr(TrialTypeKE,Cues)+1;
        NumAimFound(TrialTypeKE,Cues)=NumAimFound(TrialTypeKE,Cues)+AimFound;
        TotNumErr(TrialTypeKE,Cues)=TotNumErr(TrialTypeKE,Cues)+NumErr;
        SumPathDev(TrialTypeKE,Cues)=SumPathDev(TrialTypeKE,Cues)+ToOptimalLength;  
        SumAbsAngErr(TrialTypeKE,Cues)=SumAbsAngErr(TrialTypeKE,Cues)+abs(AngleError);
        SumOptToRealPath(TrialTypeKE,Cues)=SumOptToRealPath(TrialTypeKE,Cues)+(1/ToOptimalLength); % 'path efficiency';
        
        LastMeasuresForAim(CurBox,:) = [Duration, 1/ToOptimalLength,abs(AngleError )]; %columns: 'duration', 'path efficiency' 'angle error',
        if SearchNum<13
            NumTrB(TrialTypeKE,Cues)=NumTrB(TrialTypeKE,Cues)+1;
            NumAimFoundB(TrialTypeKE,Cues)=NumAimFoundB(TrialTypeKE,Cues)+AimFound;
            TotNumErrB(TrialTypeKE,Cues)=TotNumErrB(TrialTypeKE,Cues)+NumErr;
            SumPathDevB(TrialTypeKE,Cues)=SumPathDevB(TrialTypeKE,Cues)+ToOptimalLength;
            SumAbsAngErrB(TrialTypeKE,Cues)=SumAbsAngErrB(TrialTypeKE,Cues)+abs(AngleError);
            SumOptToRealPathB(TrialTypeKE,Cues)=SumOptToRealPathB(TrialTypeKE,Cues)+(1/ToOptimalLength);
        end

        if SearchNum>18 && SearchNum<31
            NumTrE(TrialTypeKE,Cues)=NumTrE(TrialTypeKE,Cues)+1;
            NumAimFoundE(TrialTypeKE,Cues)=NumAimFoundE(TrialTypeKE,Cues)+AimFound;
            TotNumErrE(TrialTypeKE,Cues)=TotNumErrE(TrialTypeKE,Cues)+NumErr;
            SumPathDevE(TrialTypeKE,Cues)=SumPathDevE(TrialTypeKE,Cues)+ToOptimalLength;
            SumAbsAngErrE(TrialTypeKE,Cues)=SumAbsAngErrE(TrialTypeKE,Cues)+abs(AngleError);
            SumOptToRealPathE(TrialTypeKE,Cues)=SumOptToRealPathE(TrialTypeKE,Cues)+(1/ToOptimalLength);
        end
    end  
end

%summary analysis

%analysis of all trials
out{2+SearchNum+3,1}='Analysis of all trials';
out{2+SearchNum+3,2}='landmarks';
out{2+SearchNum+3,3}='trial type';
out{2+SearchNum+3,4}='N of trained pairs in sequence'; 
out{2+SearchNum+3,5}='N of turns in sequence';
out{2+SearchNum+3,6}='N'; %
out{2+SearchNum+3,7}='prop. aim found';%
out{2+SearchNum+3,8}='mean N errors';% 'Angle Error';
out{2+SearchNum+3,9}='mean path deviation';
out{2+SearchNum+3,10}='mean Absolute angle error';
out{2+SearchNum+3,11}='mean optimal to real path';

out{2+SearchNum+4,2}='north only';
out{2+SearchNum+4,3}='1';
out{2+SearchNum+4,4}='1'; 
out{2+SearchNum+4,5}='0';
out{2+SearchNum+4,6}=NumTr(1,1);
out{2+SearchNum+4,7}=NumAimFound(1,1)/NumTr(1,1);
out{2+SearchNum+4,8}=TotNumErr(1,1)/NumTr(1,1);
out{2+SearchNum+4,9}=SumPathDev(1,1)/NumTr(1,1);
out{2+SearchNum+4,10}=SumAbsAngErr(1,1)/NumTr(1,1);
out{2+SearchNum+4,11}=SumOptToRealPath(1,1)/NumTr(1,1);

out{2+SearchNum+5,2}='north only';
out{2+SearchNum+5,3}='2';
out{2+SearchNum+5,4}='2'; 
out{2+SearchNum+5,5}='0';
out{2+SearchNum+5,6}=NumTr(2,1);
out{2+SearchNum+5,7}=NumAimFound(2,1)/NumTr(2,1);
out{2+SearchNum+5,8}=TotNumErr(2,1)/NumTr(2,1);
out{2+SearchNum+5,9}=SumPathDev(2,1)/NumTr(2,1);
out{2+SearchNum+5,10}=SumAbsAngErr(2,1)/NumTr(2,1);
out{2+SearchNum+5,11}=SumOptToRealPath(2,1)/NumTr(2,1);

out{2+SearchNum+6,2}='north only';
out{2+SearchNum+6,3}='3';
out{2+SearchNum+6,4}='>1'; 
out{2+SearchNum+6,5}='>0';
out{2+SearchNum+6,6}=NumTr(3,1);
out{2+SearchNum+6,7}=NumAimFound(3,1)/NumTr(3,1);
out{2+SearchNum+6,8}=TotNumErr(3,1)/NumTr(3,1);
out{2+SearchNum+6,9}=SumPathDev(3,1)/NumTr(3,1);
out{2+SearchNum+6,10}=SumAbsAngErr(3,1)/NumTr(3,1);
out{2+SearchNum+6,11}=SumOptToRealPath(3,1)/NumTr(3,1);

out{2+SearchNum+7,2}='statues only';
out{2+SearchNum+7,3}='1';
out{2+SearchNum+7,4}='1'; 
out{2+SearchNum+7,5}='0';
out{2+SearchNum+7,6}=NumTr(1,2);
out{2+SearchNum+7,7}=NumAimFound(1,2)/NumTr(1,2);
out{2+SearchNum+7,8}=TotNumErr(1,2)/NumTr(1,2);
out{2+SearchNum+7,9}=SumPathDev(1,2)/NumTr(1,2);
out{2+SearchNum+7,10}=SumAbsAngErr(1,2)/NumTr(1,2);
out{2+SearchNum+7,11}=SumOptToRealPath(1,2)/NumTr(1,2);

out{2+SearchNum+8,2}='statues only';
out{2+SearchNum+8,3}='2';
out{2+SearchNum+8,4}='2'; 
out{2+SearchNum+8,5}='0';
out{2+SearchNum+8,6}=NumTr(2,2);
out{2+SearchNum+8,7}=NumAimFound(2,2)/NumTr(2,2);
out{2+SearchNum+8,8}=TotNumErr(2,2)/NumTr(2,2);
out{2+SearchNum+8,9}=SumPathDev(2,2)/NumTr(2,2);
out{2+SearchNum+8,10}=SumAbsAngErr(2,2)/NumTr(2,2);
out{2+SearchNum+8,11}=SumOptToRealPath(2,2)/NumTr(2,2);

out{2+SearchNum+9,2}='statues only';
out{2+SearchNum+9,3}='3';
out{2+SearchNum+9,4}='>1'; 
out{2+SearchNum+9,5}='>0';
out{2+SearchNum+9,6}=NumTr(3,2);
out{2+SearchNum+9,7}=NumAimFound(3,2)/NumTr(3,2);
out{2+SearchNum+9,8}=TotNumErr(3,2)/NumTr(3,2);
out{2+SearchNum+9,9}=SumPathDev(3,2)/NumTr(3,2);
out{2+SearchNum+9,10}=SumAbsAngErr(3,2)/NumTr(3,2);
out{2+SearchNum+9,11}=SumOptToRealPath(3,2)/NumTr(3,2);

%***beg %% 27 Dec 2024
out{2+SearchNum+10,2}='north and statues';
out{2+SearchNum+10,3}='1';
out{2+SearchNum+10,4}='1'; 
out{2+SearchNum+10,5}='0';
out{2+SearchNum+10,6}=NumTr(1,3);
out{2+SearchNum+10,7}=NumAimFound(1,3)/NumTr(1,3);
out{2+SearchNum+10,8}=TotNumErr(1,3)/NumTr(1,3);
out{2+SearchNum+10,9}=SumPathDev(1,3)/NumTr(1,3);
out{2+SearchNum+10,10}=SumAbsAngErr(1,3)/NumTr(1,3);
out{2+SearchNum+10,11}=SumOptToRealPath(1,3)/NumTr(1,3);

out{2+SearchNum+11,2}='north and statues';
out{2+SearchNum+11,3}='2';
out{2+SearchNum+11,4}='2'; 
out{2+SearchNum+11,5}='0';
out{2+SearchNum+11,6}=NumTr(2,3);
out{2+SearchNum+11,7}=NumAimFound(2,3)/NumTr(2,3);
out{2+SearchNum+11,8}=TotNumErr(2,3)/NumTr(2,3);
out{2+SearchNum+11,9}=SumPathDev(2,3)/NumTr(2,3);
out{2+SearchNum+11,10}=SumAbsAngErr(2,3)/NumTr(2,3);
out{2+SearchNum+11,11}=SumOptToRealPath(2,3)/NumTr(2,3);

out{2+SearchNum+12,2}='north and statues';
out{2+SearchNum+12,3}='3';
out{2+SearchNum+12,4}='>1'; 
out{2+SearchNum+12,5}='>0';
out{2+SearchNum+12,6}=NumTr(3,3);
out{2+SearchNum+12,7}=NumAimFound(3,3)/NumTr(3,3);
out{2+SearchNum+12,8}=TotNumErr(3,3)/NumTr(3,3);
out{2+SearchNum+12,9}=SumPathDev(3,3)/NumTr(3,3);
out{2+SearchNum+12,10}=SumAbsAngErr(3,3)/NumTr(3,3);
out{2+SearchNum+12,11}=SumOptToRealPath(3,3)/NumTr(3,3);
%***end %% 27 Dec 2024

%analysis of the first 12 trials
out{2+SearchNum+14,1}='Analysis of trials 1-12';
out{2+SearchNum+14,2}='landmarks';
out{2+SearchNum+14,3}='trial type';
out{2+SearchNum+14,4}='N of trained pairs in sequence'; 
out{2+SearchNum+14,5}='N of turns in sequence';
out{2+SearchNum+14,6}='N'; %
out{2+SearchNum+14,7}='prop. aim found';%
out{2+SearchNum+14,8}='mean N errors';%
out{2+SearchNum+14,9}='mean path deviation';
out{2+SearchNum+14,10}='mean Absolute angle error';
out{2+SearchNum+14,11}='mean optimal to real path';

out{2+SearchNum+15,2}='north only';
out{2+SearchNum+15,3}='1';
out{2+SearchNum+15,4}='1'; 
out{2+SearchNum+15,5}='0';
out{2+SearchNum+15,6}=NumTrB(1,1);
out{2+SearchNum+15,7}=NumAimFoundB(1,1)/NumTrB(1,1);
out{2+SearchNum+15,8}=TotNumErrB(1,1)/NumTrB(1,1);
out{2+SearchNum+15,9}=SumPathDevB(1,1)/NumTrB(1,1);
out{2+SearchNum+15,10}=SumAbsAngErrB(1,1)/NumTrB(1,1);
out{2+SearchNum+15,11}=SumOptToRealPathB(1,1)/NumTrB(1,1);

out{2+SearchNum+16,2}='north only';
out{2+SearchNum+16,3}='2';
out{2+SearchNum+16,4}='2'; 
out{2+SearchNum+16,5}='0';
out{2+SearchNum+16,6}=NumTrB(2,1);
out{2+SearchNum+16,7}=NumAimFoundB(2,1)/NumTrB(2,1);
out{2+SearchNum+16,8}=TotNumErrB(2,1)/NumTrB(2,1);
out{2+SearchNum+16,9}=SumPathDevB(2,1)/NumTrB(2,1);
out{2+SearchNum+16,10}=SumAbsAngErrB(2,1)/NumTrB(2,1);
out{2+SearchNum+16,11}=SumOptToRealPathB(2,1)/NumTrB(2,1);

out{2+SearchNum+17,2}='north only';
out{2+SearchNum+17,3}='3';
out{2+SearchNum+17,4}='>1'; 
out{2+SearchNum+17,5}='>0';
out{2+SearchNum+17,6}=NumTrB(3,1);
out{2+SearchNum+17,7}=NumAimFoundB(3,1)/NumTrB(3,1);
out{2+SearchNum+17,8}=TotNumErrB(3,1)/NumTrB(3,1);
out{2+SearchNum+17,9}=SumPathDevB(3,1)/NumTrB(3,1);
out{2+SearchNum+17,10}=SumAbsAngErrB(3,1)/NumTrB(3,1);
out{2+SearchNum+17,11}=SumOptToRealPathB(3,1)/NumTrB(3,1);

out{2+SearchNum+18,2}='statues only';
out{2+SearchNum+18,3}='1';
out{2+SearchNum+18,4}='1'; 
out{2+SearchNum+18,5}='0';
out{2+SearchNum+18,6}=NumTrB(1,2);
out{2+SearchNum+18,7}=NumAimFoundB(1,2)/NumTrB(1,2);
out{2+SearchNum+18,8}=TotNumErrB(1,2)/NumTrB(1,2);
out{2+SearchNum+18,9}=SumPathDevB(1,2)/NumTrB(1,2);
out{2+SearchNum+18,10}=SumAbsAngErrB(1,2)/NumTrB(1,2);
out{2+SearchNum+18,11}=SumOptToRealPathB(1,2)/NumTrB(1,2);

out{2+SearchNum+19,2}='statues only';
out{2+SearchNum+19,3}='2';
out{2+SearchNum+19,4}='2'; 
out{2+SearchNum+19,5}='0';
out{2+SearchNum+19,6}=NumTrB(2,2);
out{2+SearchNum+19,7}=NumAimFoundB(2,2)/NumTrB(2,2);
out{2+SearchNum+19,8}=TotNumErrB(2,2)/NumTrB(2,2);
out{2+SearchNum+19,9}=SumPathDevB(2,2)/NumTrB(2,2);
out{2+SearchNum+19,10}=SumAbsAngErrB(2,2)/NumTrB(2,2);
out{2+SearchNum+19,11}=SumOptToRealPathB(2,2)/NumTrB(2,2);

out{2+SearchNum+20,2}='statues only';
out{2+SearchNum+20,3}='3';
out{2+SearchNum+20,4}='>1'; 
out{2+SearchNum+20,5}='>0';
out{2+SearchNum+20,6}=NumTrB(3,2);
out{2+SearchNum+20,7}=NumAimFoundB(3,2)/NumTrB(3,2);
out{2+SearchNum+20,8}=TotNumErrB(3,2)/NumTrB(3,2);
out{2+SearchNum+20,9}=SumPathDevB(3,2)/NumTrB(3,2);
out{2+SearchNum+20,10}=SumAbsAngErrB(3,2)/NumTrB(3,2);
out{2+SearchNum+20,11}=SumOptToRealPathB(3,2)/NumTrB(3,2);

%*** beg 27 Dec 2024
out{2+SearchNum+21,2}='north and statues';
out{2+SearchNum+21,3}='1';
out{2+SearchNum+21,4}='1'; 
out{2+SearchNum+21,5}='0';
out{2+SearchNum+21,6}=NumTrB(1,3);
out{2+SearchNum+21,7}=NumAimFoundB(1,3)/NumTrB(1,3);
out{2+SearchNum+21,8}=TotNumErrB(1,3)/NumTrB(1,3);
out{2+SearchNum+21,9}=SumPathDevB(1,3)/NumTrB(1,3);
out{2+SearchNum+21,10}=SumAbsAngErrB(1,3)/NumTrB(1,3);
out{2+SearchNum+21,11}=SumOptToRealPathB(1,3)/NumTrB(1,3);

out{2+SearchNum+22,2}='north and statues';
out{2+SearchNum+22,3}='2';
out{2+SearchNum+22,4}='2'; 
out{2+SearchNum+22,5}='0';
out{2+SearchNum+22,6}=NumTrB(2,3);
out{2+SearchNum+22,7}=NumAimFoundB(2,3)/NumTrB(2,3);
out{2+SearchNum+22,8}=TotNumErrB(2,3)/NumTrB(2,3);
out{2+SearchNum+22,9}=SumPathDevB(2,3)/NumTrB(2,3);
out{2+SearchNum+22,10}=SumAbsAngErrB(2,3)/NumTrB(2,3);
out{2+SearchNum+22,11}=SumOptToRealPathB(2,3)/NumTrB(2,3);

out{2+SearchNum+23,2}='north and statues';
out{2+SearchNum+23,3}='3';
out{2+SearchNum+23,4}='>1'; 
out{2+SearchNum+23,5}='>0';
out{2+SearchNum+23,6}=NumTrB(3,3);
out{2+SearchNum+23,7}=NumAimFoundB(3,3)/NumTrB(3,3);
out{2+SearchNum+23,8}=TotNumErrB(3,3)/NumTrB(3,3);
out{2+SearchNum+23,9}=SumPathDevB(3,3)/NumTrB(3,3);
out{2+SearchNum+23,10}=SumAbsAngErrB(3,3)/NumTrB(3,3);
out{2+SearchNum+23,11}=SumOptToRealPathB(3,3)/NumTrB(3,3);
%*** end 27 Dec 2024

%analysis of the last 12 trials
out{2+SearchNum+25,1}='Analysis of trials 19-30';
out{2+SearchNum+25,2}='landmarks';
out{2+SearchNum+25,3}='trial type';
out{2+SearchNum+25,4}='N of trained pairs in sequence'; 
out{2+SearchNum+25,5}='N of turns in sequence';
out{2+SearchNum+25,6}='N'; %
out{2+SearchNum+25,7}='prop. aim found';%
out{2+SearchNum+25,8}='mean N errors';%
out{2+SearchNum+25,9}='mean path deviation';
out{2+SearchNum+25,10}='mean Absolute angle error';
out{2+SearchNum+25,11}='mean optimal to real path';

out{2+SearchNum+26,2}='north only';
out{2+SearchNum+26,3}='1';
out{2+SearchNum+26,4}='1'; 
out{2+SearchNum+26,5}='0';
out{2+SearchNum+26,6}=NumTrE(1,1);
out{2+SearchNum+26,7}=NumAimFoundE(1,1)/NumTrE(1,1);
out{2+SearchNum+26,8}=TotNumErrE(1,1)/NumTrE(1,1);
out{2+SearchNum+26,9}=SumPathDevE(1,1)/NumTrE(1,1);
out{2+SearchNum+26,10}=SumAbsAngErrE(1,1)/NumTrE(1,1);
out{2+SearchNum+26,11}=SumOptToRealPathE(1,1)/NumTrE(1,1);

out{2+SearchNum+27,2}='north only';
out{2+SearchNum+27,3}='2';
out{2+SearchNum+27,4}='2'; 
out{2+SearchNum+27,5}='0';
out{2+SearchNum+27,6}=NumTrE(2,1);
out{2+SearchNum+27,7}=NumAimFoundE(2,1)/NumTrE(2,1);
out{2+SearchNum+27,8}=TotNumErrE(2,1)/NumTrE(2,1);
out{2+SearchNum+27,9}=SumPathDevE(2,1)/NumTrE(2,1);
out{2+SearchNum+27,10}=SumAbsAngErrE(2,1)/NumTrE(2,1);
out{2+SearchNum+27,11}=SumOptToRealPathE(2,1)/NumTrE(2,1);

out{2+SearchNum+28,2}='north only';
out{2+SearchNum+28,3}='3';
out{2+SearchNum+28,4}='>1'; 
out{2+SearchNum+28,5}='>0';
out{2+SearchNum+28,6}=NumTrE(3,1);
out{2+SearchNum+28,7}=NumAimFoundE(3,1)/NumTrE(3,1);
out{2+SearchNum+28,8}=TotNumErrE(3,1)/NumTrE(3,1);
out{2+SearchNum+28,9}=SumPathDevE(3,1)/NumTrE(3,1);
out{2+SearchNum+28,10}=SumAbsAngErrE(3,1)/NumTrE(3,1);
out{2+SearchNum+28,11}=SumOptToRealPathE(3,1)/NumTrE(3,1);

out{2+SearchNum+29,2}='statues only';
out{2+SearchNum+29,3}='1';
out{2+SearchNum+29,4}='1'; 
out{2+SearchNum+29,5}='0';
out{2+SearchNum+29,6}=NumTrE(1,2);
out{2+SearchNum+29,7}=NumAimFoundE(1,2)/NumTrE(1,2);
out{2+SearchNum+29,8}=TotNumErrE(1,2)/NumTrE(1,2);
out{2+SearchNum+29,9}=SumPathDevE(1,2)/NumTrE(1,2);
out{2+SearchNum+29,10}=SumAbsAngErrE(1,2)/NumTrE(1,2);
out{2+SearchNum+29,11}=SumOptToRealPathE(1,2)/NumTrE(1,2);

out{2+SearchNum+30,2}='statues only';
out{2+SearchNum+30,3}='2';
out{2+SearchNum+30,4}='2'; 
out{2+SearchNum+30,5}='0';
out{2+SearchNum+30,6}=NumTrE(2,2);
out{2+SearchNum+30,7}=NumAimFoundE(2,2)/NumTrE(2,2);
out{2+SearchNum+30,8}=TotNumErrE(2,2)/NumTrE(2,2);
out{2+SearchNum+30,9}=SumPathDevE(2,2)/NumTrE(2,2);
out{2+SearchNum+30,10}=SumAbsAngErrE(2,2)/NumTrE(2,2);
out{2+SearchNum+30,11}=SumOptToRealPathE(2,2)/NumTrE(2,2);

out{2+SearchNum+31,2}='statues only';
out{2+SearchNum+31,3}='3';
out{2+SearchNum+31,4}='>1'; 
out{2+SearchNum+31,5}='>0';
out{2+SearchNum+31,6}=NumTrE(3,2);
out{2+SearchNum+31,7}=NumAimFoundE(3,2)/NumTrE(3,2);
out{2+SearchNum+31,8}=TotNumErrE(3,2)/NumTrE(3,2);
out{2+SearchNum+31,9}=SumPathDevE(3,2)/NumTrE(3,2);
out{2+SearchNum+31,10}=SumAbsAngErrE(3,2)/NumTrE(3,2);
out{2+SearchNum+31,11}=SumOptToRealPathE(3,2)/NumTrE(3,2);

%*** beg 27 Dec 2024
out{2+SearchNum+32,2}='north and statues';
out{2+SearchNum+32,3}='1';
out{2+SearchNum+32,4}='1'; 
out{2+SearchNum+32,5}='0';
out{2+SearchNum+32,6}=NumTrE(1,3);
out{2+SearchNum+32,7}=NumAimFoundE(1,3)/NumTrE(1,3);
out{2+SearchNum+32,8}=TotNumErrE(1,3)/NumTrE(1,3);
out{2+SearchNum+32,9}=SumPathDevE(1,3)/NumTrE(1,3);
out{2+SearchNum+32,10}=SumAbsAngErrE(1,3)/NumTrE(1,3);
out{2+SearchNum+32,11}=SumOptToRealPathE(1,3)/NumTrE(1,3);

out{2+SearchNum+33,2}='north and statues';
out{2+SearchNum+33,3}='2';
out{2+SearchNum+33,4}='2'; 
out{2+SearchNum+33,5}='0';
out{2+SearchNum+33,6}=NumTrE(2,3);
out{2+SearchNum+33,7}=NumAimFoundE(2,3)/NumTrE(2,3);
out{2+SearchNum+33,8}=TotNumErrE(2,3)/NumTrE(2,3);
out{2+SearchNum+33,9}=SumPathDevE(2,3)/NumTrE(2,3);
out{2+SearchNum+33,10}=SumAbsAngErrE(2,3)/NumTrE(2,3);
out{2+SearchNum+33,11}=SumOptToRealPathE(2,3)/NumTrE(2,3);

out{2+SearchNum+34,2}='north and statues';
out{2+SearchNum+34,3}='3';
out{2+SearchNum+34,4}='>1'; 
out{2+SearchNum+34,5}='>0';
out{2+SearchNum+34,6}=NumTrE(3,3);
out{2+SearchNum+34,7}=NumAimFoundE(3,3)/NumTrE(3,3);
out{2+SearchNum+34,8}=TotNumErrE(3,3)/NumTrE(3,3);
out{2+SearchNum+34,9}=SumPathDevE(3,3)/NumTrE(3,3);
out{2+SearchNum+34,10}=SumAbsAngErrE(3,3)/NumTrE(3,3);
out{2+SearchNum+34,11}=SumOptToRealPathE(3,3)/NumTrE(3,3);
%*** end 27 Dec 2024

%LastMeasuresForAim kamil 7.6.2024 - hodnoty z posledniho hledani cile 1-9
row = 2+SearchNum+36;

[out{row, 1:5}] = deal('Last goal search for each field','GoalField', 'duration', 'path efficiency', 'angle error');
for j=1:9
	[out{row+j,2:5}]=deal(j,LastMeasuresForAim(j,1), LastMeasuresForAim(j,2), LastMeasuresForAim(j,3));
end

xlswrite([FileNameIn '.xls'], out); %#ok<XLSWT>

% TrajectoriesToShow=[1 2 3 6];
if ~isempty(TrajectoriesToShow), figure('Name','TrajectoriesToShow') ; end
for i=1:SearchNum
    TrFound=0;
    for j=1:length(TrajectoriesToShow)
        if i==TrajectoriesToShow(j)
            TrFound=1;
        end
    end    
    if TrFound==1        
        plot(Trajectories{i}(1,2:end),0-Trajectories{i}(2,2:end),'b')
        hold on
        plot(EndBoxes{i}(1),0-EndBoxes{i}(2),'.g')
        hold on
        plot([Trajectories{i}(1,2) Trajectories{i}(1,2)+IndicatedAngles{i}(1)],[0-Trajectories{i}(2,2) 0-(Trajectories{i}(2,2)+IndicatedAngles{i}(2))],'r', 'LineWidth',2)
        hold on
        plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k')
        axis equal
        axis ij
        set ( gca, 'xdir', 'reverse' )
        axis off
    end
end