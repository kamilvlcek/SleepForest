function out=ReadTR3(FileNameIn,SubPlots,OrderTrials, TrajectoriesToShow)
%process the test data, plot the graph and return the result table
%analysis of training and test trials - March 11, 2024
%compute proportion of real path length to optimal one
%categorize tasks according to the demands/difficulty level

% to do: angles, summary data

SearchAnimal=0; % added March 6 2024
PlotsInFigure=12; %how many subplots can be in one figure
if ~exist('SubPlots','var') 
    SubPlots = 1;   %subplots shown by default
end

if ~exist('OrderTrials','var') || isempty(OrderTrials)
    OrderTrials = 0;   %if to order trials from best to worse
end

if ~exist('TrajectoriesToShow','var'), TrajectoriesToShow=[]; end

%values for categoris 3 difficulty levels x 3 (North/Statues/both shown, across all trials) x 3  (all trials, first part , last part)
NumTr(3,3,3)=zeros; %num of trials (TrialTypeKE,Cues) 
NumAimFound(3,3,3)=zeros; %num success
TotNumErr(3,3,3)=zeros; %num errors
SumPathDev(3,3,3)=zeros; % path dev 
SumAbsAngErr(3,3,3)=zeros;
SumOptToRealPath(3,3,3)=zeros;  % 'path efficiency';
stav=0; %%state - 1-pointing , 2- navigation

if contains(FileNameIn,'\')
    FullFileName = FileNameIn;  % complete trajectory with parh
else
    FullFileName=['d:\prace\mff\data\aappSeg\NUDZ\results\spanav\' FileNameIn ];
end
%FileName=['D:\Users\kelemen\Data\VRKamil\' FileNameIn '.tr'];
FileName = basename(FullFileName); %without path, only filename

%output table - first row
out{1,1}=FileName;
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
out{2,15}='Level=trial type'; %category Alena 
out{2,16}='angle indicated';
out{2,17}='angle real';
out{2,18}='angle error';
%out{2,19}='trial category';
out{2,19}='trial type Kamil';
out{2,20}='Cues'; 
out{2,21}='path efficiency';



FileID=fopen(FullFileName);

SearchNum=0; %trial number
NL=0;line=[]; %line number
%while strcmp(line(1:6),' 0.000')==0
%fprintf('\n\n        '); %removed temporarily
%READing THE POSITIONs OF THE TENTs
while isempty(strfind(line, 'KOLO'))   %e.g. JavaTime:16:35:02.303; Text.modify(); handle:5; text:KOLO: 1; 
    line=fgetl(FileID);
	%fprintf('\b\b\b\b\b\b%5i', NL); %removed temporarily
    NL=NL+1;
    if contains(line, 'Aim position') 
        Aim=GetAimPositionsb(line);  %b version of the function
        AimX=Aim{1}; %1x9 double - aim areas for 9 squres
        AimY=Aim{2}; 
        break; %useless to continue, we have the aims positions
    end
end
% n=strfind(line, 'text:Najdete'); % WHy is this here?
% Cil=line(n+11:end-2); % Why is this here?
DLN=0; %index of data line , reset for each new goal
firstdataline=0;
NumErr=0;
Cues = 0; % Cues: 1 = North shown, 2 = Statues shown
LastMeasuresForAim = zeros(9,3); %columns: 'duration', 'path efficiency' 'angle error', rows: CurBox 1-9 (tj aims), kamil 7.6.2024

%figure
FIGUREDATA = {}; %there I will collect data for the images, so I can then draw them in manual order

while feof(FileID)==0
    line=fgetl(FileID);
    NL=NL+1;
    if strcmp(line(1),' ') %Dataline - first character is space
        DLN=DLN+1;
        if firstdataline==0 %first row with column description
            divider=line(6); %column divider - tab
            firstdataline=1; % Time	Frame	ArenaLoc.X	ArenaLoc.Y ... 
        end
        k=strfind(line, divider); %1x85 double - indexes of column divider
        %three data from the track - data about the position of the subject
        timesec(DLN)=str2double(line(2:k(1)-1)); %time of current dataline in seconds
        ArenaLocX(DLN)=str2double(line(k(2)+1:k(3)-1)); %pozice subjektu = track v jednom trialu
        ArenaLocY(DLN)=str2double(line(k(3)+1:k(4)-1));
    end   
%     if contains(line,'space') %pointing to the target
%         Angle=str2double(line(k(7)+1:k(8)-1));
%         Angle=rem(Angle,360);
%         if Angle<0
%             Angle=Angle+360;
%         end
%     end 
    if contains(line,'Avatar location changed:')   
        ba=strfind(line, '[');
        bb=strfind(line, ',');
        bc=strfind(line, ']');
        StartLocX=str2double(line(ba+1:bb-1)); 
        StartLocY=str2double(line(bb+2:bc-1)); 
        NorthArrow = 0; %default values for trial. In some old trials, Orientation Marks Shown never happens
        Statues = 0;
        Cues = 0;
    end                                             %%%
    if strfind(line, 'Orientation Marks Shown') %%% e.g. Orientation Marks Shown : North Compas 0, Statues : 1 
        PosNA=strfind(line, 'North Compas');
        NorthArrow=str2num(line(PosNA+13)); %0/1 - if  North Compas is shown
        PosSt=strfind(line, 'Statues');
        Statues=str2num(line(PosSt+10)); %0/1 - if Statues are shown
        if NorthArrow==1 && Statues==0
            Cues=1;  % 1 = North shown
        elseif NorthArrow==0 && Statues==1
            Cues=2;  % 2 = Statues shown
        elseif NorthArrow==1 && Statues==1  %% 27 Dec 2024 - training - both types of cues are shown
            Cues=3;  %% 27 Dec 2024
        else
            Cues=0;  %not defined             
        end
    end
    if strfind(line, 'Aim search:') % e.g. Aim search:AimA
        n=strfind(line, 'Aim search:');
        CurrentAim=line(n+11:n+14); %%% e.g. AimA
    end
    if contains(line,'Ukazte na') ||  contains(line,'Ukaz na')
        stav=1; %state - 1-pointing , 2- navigation
    end 
    if contains(line,'space') && stav==1 %pointing - data line with space key pressed
        Angle=str2num(line(k(7)+1:k(8)-1)); %View.X when pointing
        Angle=rem(Angle,360);
        if Angle<0
            Angle=Angle+360;
        end
    end 
    if contains(line, 'text:Najdete') || contains(line, 'text:Najdi') %e.g. text:Najdete JELENA;
        stav=2;
        timesec=[];
        ArenaLocX=[]; 
        ArenaLocY=[];
        DLN=0; %index of data line
        NumErr=0; %number of errors
        ErrLocX=[]; %position where error occured
        ErrLocY=[];
        n=strfind(line, 'text:Najdete');
        if isempty(n)
            n=strfind(line, 'text:Najdi'); 
            Cil=line(n+11:end-2); %goal name, e.g. KOLIBRIKA
        else
            Cil=line(n+13:end-2); %goal name, e.g. KOLIBRIKA
        end
        
        SearchAnimal=1; % added March 6 2024
    end 
    
    
    %ukonceni hledani cile 
    if strfind(line, 'CHYBA !')
      NumErr=NumErr+1;
      ErrLocX(NumErr)=ArenaLocX(DLN); %subject position at error
      ErrLocY(NumErr)=ArenaLocY(DLN);
    end
    if length(strfind(line, 'VYBORNE !'))>0 || length(strfind(line, 'NEPOVEDLO SE VAM NAJIT CIL'))>0 && SearchAnimal==1 % modified March 6 2024
        SearchAnimal=0; % added March 6 2024
        SearchNum=SearchNum+1; %trial number
        
        if strfind(line, 'VYBORNE !')
            AimFound=1;
        end
        if strfind(line, 'NEPOVEDLO SE VAM NAJIT CIL')
            AimFound=0;
        end
        if strcmp(CurrentAim(4),'A')
            CurBox=1; %number of square A-I is 1-9
        elseif strcmp(CurrentAim(4),'B')
            CurBox=2;
        elseif strcmp(CurrentAim(4),'C')
            CurBox=3;
        elseif strcmp(CurrentAim(4),'D')
            CurBox=4;
        elseif strcmp(CurrentAim(4),'E')
            CurBox=5;
        elseif strcmp(CurrentAim(4),'F')
            CurBox=6;
        elseif strcmp(CurrentAim(4),'G')
            CurBox=7;
        elseif strcmp(CurrentAim(4),'H')
            CurBox=8;
        elseif strcmp(CurrentAim(4),'I')
            CurBox=9;
        end      
%         CurGoal=str2double(CurrentAim(5)); %cislo stanu ve ctverci s cilem
        
        StartEndField=DetStartEndField(ArenaLocX(2:end),ArenaLocY(2:end),AimX,AimY); %find start field - int 1-9
% 		CurBox
        TrialType=DetTrialType([StartEndField(1) CurBox]);  %determine the type of test trial , [1,1,0,1] to [12,8,4,6] 
        TrialTypeKE=DetTrialTypeKamilEliska([StartEndField(1) CurBox]);  %determine the type of test trial - 1 to 3
        
        if exist('Angle','var')   %  Kamil 6.11.2018 -  Adam24_8_18_3_0.tr vubec neukazal                 
            IndicatedAng=DistAng2Pos(400,Angle/360*2*3.141592653);   %pointing angle in [x,y] coordinates, distant 400 from [0,0]
        else
            IndicatedAng = [0 0 ];
            Angle = NaN;
        end        
                        
        Duration=timesec(end)-timesec(2);
        Length=LengthofTrack(ArenaLocX(2:end),ArenaLocY(2:end));
%         ArenaLocX(2) %%%
%         ArenaLocY(2) %%%
%         CurBox %%%
%         CurGoal %%%
%         AimX(CurBox,CurGoal) %%%
%         AimY(CurBox,CurGoal) %%%
        ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),ArenaLocX(DLN),ArenaLocY(DLN));  %%% number 1 - inf, to longer the worse
%       ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),AimX(CurBox,CurGoal),AimY(CurBox,CurGoal));  %%%
        %ToOptimalLength=Length/dist(ArenaLocX(2),ArenaLocY(2),ArenaLocX(end),ArenaLocY(end));
        RealAngle=XY2ang(ArenaLocX(DLN)-ArenaLocX(2),ArenaLocY(DLN)-ArenaLocY(2))/(2*3.141592653)*360; %angle from start to end, in deg
        %RealAngle=XY2ang(ArenaLocX(end)-ArenaLocX(2),ArenaLocY(end)-ArenaLocY(2))/(2*3.141592653)*360;
        AngleError=Angle-RealAngle; %difference between indicated angle from start to goal, and real angle
        if AngleError>180
            AngleError=AngleError-360;
        end
        if AngleError<-180
            AngleError=AngleError+360;
        end
               
        %fill in the figure data that we can draw later
        %FIGUREDATA(SearchNum).X = X;
        %FIGUREDATA(SearchNum).Y = Y;
        
        %SearchNum is trial number
        FIGUREDATA(SearchNum).Trial = SearchNum; %subject trajectory
        FIGUREDATA(SearchNum).ArenaLocX = ArenaLocX; %subject trajectory
        FIGUREDATA(SearchNum).ArenaLocY = ArenaLocY;
        FIGUREDATA(SearchNum).AimX = AimX; %1x9 double - aim areas for 9 squres
        FIGUREDATA(SearchNum).AimY = AimY;
        FIGUREDATA(SearchNum).CurBox = CurBox; %number of square A-I is 1-9
        %FIGUREDATA(SearchNum).CurGoal = CurGoal;
        FIGUREDATA(SearchNum).ErrLocX = ErrLocX; %subject position at error
        FIGUREDATA(SearchNum).ErrLocY = ErrLocY;
        FIGUREDATA(SearchNum).NumErr = NumErr; %number of errors
        FIGUREDATA(SearchNum).IndicatedAng = IndicatedAng; %pointing angle in [x,y] coordinates, distant 400 from [0,0]
        FIGUREDATA(SearchNum).TrialType = TrialType; %[1,1,0,1] to [12,8,4,6]
        FIGUREDATA(SearchNum).TrialTypeKE = TrialTypeKE; %type of test trial - 1 to 3
        FIGUREDATA(SearchNum).AimFound = AimFound; %1/0
        FIGUREDATA(SearchNum).Cil = Cil; %goal name, e.g. KOLIBRIKA
        FIGUREDATA(SearchNum).ToOptimalLength = ToOptimalLength;  % number 1 - inf, to longer the worse
        FIGUREDATA(SearchNum).Cues = Cues;  % Cues: 1 = North shown, 2 = Statues shown
        
        %one trial in output table
        out{2+SearchNum,1}=SearchNum; %SearchNum is trial number
        out{2+SearchNum,2}=CurrentAim; %e.g. AimA
        out{2+SearchNum,3}=Cil;
        out{2+SearchNum,4}=NorthArrow; %0/1 - if  North Compas is shown
        out{2+SearchNum,5}=Statues; %0/1 - if Statues are shown
        out{2+SearchNum,6}=AimFound;
        out{2+SearchNum,7}=Duration; %in sec
        out{2+SearchNum,8}=Length; %LengthofTrack
        out{2+SearchNum,9}=ToOptimalLength; %'path deviaton from optimal';
        out{2+SearchNum,10}=NumErr; %'errors'
        out{2+SearchNum,11}=StartEndField(1); %'StartField' % start field - int 1-9
        out{2+SearchNum,12}=CurBox;  %'GoalField' %number of square A-I is 1-9
        out{2+SearchNum,13}=TrialType(2); %'N of trained pairs in sequence', 1 to 8
        out{2+SearchNum,14}=TrialType(3); %'N of turns in sequence', 0 to 4
        out{2+SearchNum,15}=TrialTypeKE; %'trial category Kamil Eliska', type of test trial - 1 to 3
        out{2+SearchNum,16}=Angle;
        out{2+SearchNum,17}=RealAngle; %angle from start to end, in deg
        out{2+SearchNum,18}=AngleError; %-180 - +180
%         out{2+SearchNum,17}=TrialType(1); %'trial category'        
        Kategorie = [1 2 3 3 4 4 4 5 5 5 5 5 ]; %trenovane dvojice, prima trasa, 1 roh, 2 rohy, 3 a 4 rohy
        out{2+SearchNum,19}=Kategorie(TrialType(1)); %'trial type Kamil'       
        out{2+SearchNum,20}=Cues; %Cues: 1 = North shown, 2 = Statues shown  
        out{2+SearchNum,21}=1/ToOptimalLength; %kamil 8.4.2024 'path efficiency';
        
        %edo 6.12.2023 %values for categoris 3 difficulty levels x 2 North/Statues shown, across all trials
        if Cues>0 
            NumTr(TrialTypeKE,Cues)=NumTr(TrialTypeKE,Cues)+1; % Cues: 1 = North shown, 2 = Statues shown
            NumAimFound(TrialTypeKE,Cues)=NumAimFound(TrialTypeKE,Cues)+AimFound;   %num success
            TotNumErr(TrialTypeKE,Cues)=TotNumErr(TrialTypeKE,Cues)+NumErr; %num errors
            SumPathDev(TrialTypeKE,Cues)=SumPathDev(TrialTypeKE,Cues)+ToOptimalLength; %path deviation
            SumAbsAngErr(TrialTypeKE,Cues)=SumAbsAngErr(TrialTypeKE,Cues)+abs(AngleError);
            SumOptToRealPath(TrialTypeKE,Cues)=SumOptToRealPath(TrialTypeKE,Cues)+(1/ToOptimalLength); % 'path efficiency';
            LastMeasuresForAim(CurBox,:) = [Duration, 1/ToOptimalLength,abs(AngleError )]; %columns: 'duration', 'path efficiency' 'angle error',

            if SearchNum<13 % first 12 trials
                NumTr(TrialTypeKE,Cues,2)=NumTr(TrialTypeKE,Cues,2)+1;
                NumAimFound(TrialTypeKE,Cues,2)=NumAimFound(TrialTypeKE,Cues,2)+AimFound;
                TotNumErr(TrialTypeKE,Cues,2)=TotNumErr(TrialTypeKE,Cues,2)+NumErr;
                SumPathDev(TrialTypeKE,Cues,2)=SumPathDev(TrialTypeKE,Cues,2)+ToOptimalLength;
                SumAbsAngErr(TrialTypeKE,Cues,2)=SumAbsAngErr(TrialTypeKE,Cues,2)+abs(AngleError);
                SumOptToRealPath(TrialTypeKE,Cues,2)=SumOptToRealPath(TrialTypeKE,Cues,2)+(1/ToOptimalLength);        
            elseif SearchNum>18 && SearchNum<31 %last 12 trials
                NumTr(TrialTypeKE,Cues,3)=NumTr(TrialTypeKE,Cues,3)+1;
                NumAimFound(TrialTypeKE,Cues,3)=NumAimFound(TrialTypeKE,Cues,3)+AimFound;
                TotNumErr(TrialTypeKE,Cues,3)=TotNumErr(TrialTypeKE,Cues,3)+NumErr;
                SumPathDev(TrialTypeKE,Cues,3)=SumPathDev(TrialTypeKE,Cues,3)+ToOptimalLength;
                SumAbsAngErr(TrialTypeKE,Cues,3)=SumAbsAngErr(TrialTypeKE,Cues,3)+abs(AngleError);
                SumOptToRealPath(TrialTypeKE,Cues,3)=SumOptToRealPath(TrialTypeKE,Cues,3)+(1/ToOptimalLength);  
            end
        end
        
        clear Angle; %if subject hadn't point to target in the next trial
    end
end

% udelam obrazek dodatecne
Obrazky(FIGUREDATA,PlotsInFigure,FileName,SubPlots,OrderTrials,TrajectoriesToShow);

%KAMIL 22.5.2025 - tady jsou asi chyby

%summary analysis in output table
%SearchNum is now total number of trials
for z = 1:3 %third dimension -  all trials, first trials, last trials  
    if z==1 
        r = 3; %output table row
        out{2+SearchNum+r,1}='Analysis of all trials';
    elseif z==2
        r = r+2;
        out{2+SearchNum+r,1}='Analysis of trials 1-12';        
    else
        r = r+2;
        out{2+SearchNum+r,1}='Analysis of trials 19-30';
    end
    out{2+SearchNum+r,2}='landmarks';
    out{2+SearchNum+r,3}='difficulty level';  %trialtype 1-3
    % out{2+SearchNum+3,2}='description'; 
    out{2+SearchNum+r,4}='N of trained pairs in sequence'; 
    out{2+SearchNum+r,5}='N of turns in sequence';
    out{2+SearchNum+r,6}='N'; %
    out{2+SearchNum+r,7}='prop. aim found';%
    out{2+SearchNum+r,8}='mean N errors';% 'Angle Error';
    out{2+SearchNum+r,9}='mean path deviation';
    out{2+SearchNum+r,10}='mean ABS angle error';
    out{2+SearchNum+r,11}='mean path efficiency'; %kamil 19.4.2024
    r = r + 1; %4,15,26
    out{2+SearchNum+r,2}='north only'; %'landmarks'
    out{2+SearchNum+r,3}='1'; %'difficulty level' %trialtype 1-3
    out{2+SearchNum+r,4}='1';  %'N of trained pairs in sequence'; 
    out{2+SearchNum+r,5}='0'; %'N of turns in sequence';
    out{2+SearchNum+r,6}=NumTr(1,1,z); %'N' (TrialTypeKE,Cues)
    out{2+SearchNum+r,7}=NumAimFound(1,1,z)/NumTr(1,1,z); %'prop. aim found'
    out{2+SearchNum+r,8}=TotNumErr(1,1,z)/NumTr(1,1,z); %'mean N errors'
    out{2+SearchNum+r,9}=SumPathDev(1,1,z)/NumTr(1,1,z);  %'mean path deviation';
    out{2+SearchNum+r,10}=SumAbsAngErr(1,1,z)/NumTr(1,1,z); %'mean ABS angle error'
    out{2+SearchNum+r,11}=SumOptToRealPath(1,1,z)/NumTr(1,1,z);  %'mean path efficiency'; %kamil 19.4.2024
    r = r + 1;
    out{2+SearchNum+r,2}='north only';
    out{2+SearchNum+r,3}='2';
    out{2+SearchNum+r,4}='2'; 
    out{2+SearchNum+r,5}='0';
    out{2+SearchNum+r,6}=NumTr(2,1,z);
    out{2+SearchNum+r,7}=NumAimFound(2,1,z)/NumTr(2,1,z);
    out{2+SearchNum+r,8}=TotNumErr(2,1,z)/NumTr(2,1,z);
    out{2+SearchNum+r,9}=SumPathDev(2,1,z)/NumTr(2,1,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(2,1,z)/NumTr(2,1,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(2,1,z)/NumTr(2,1,z);
    r = r + 1;    
    out{2+SearchNum+r,2}='north only';
    out{2+SearchNum+r,3}='3';
    out{2+SearchNum+r,4}='>2'; 
    out{2+SearchNum+r,5}='>0';
    out{2+SearchNum+r,6}=NumTr(3,1,z);
    out{2+SearchNum+r,7}=NumAimFound(3,1,z)/NumTr(3,1,z);
    out{2+SearchNum+r,8}=TotNumErr(3,1,z)/NumTr(3,1,z);
    out{2+SearchNum+r,9}=SumPathDev(3,1,z)/NumTr(3,1,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(3,1,z)/NumTr(3,1,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(3,1,z)/NumTr(3,1,z);
    r = r + 1;
    out{2+SearchNum+r,2}='statues only';
    out{2+SearchNum+r,3}='1';
    out{2+SearchNum+r,4}='1'; 
    out{2+SearchNum+r,5}='0';
    out{2+SearchNum+r,6}=NumTr(1,2,z);
    out{2+SearchNum+r,7}=NumAimFound(1,2,z)/NumTr(1,2,z);
    out{2+SearchNum+r,8}=TotNumErr(1,2,z)/NumTr(1,2,z);
    out{2+SearchNum+r,9}=SumPathDev(1,2,z)/NumTr(1,2,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(1,2,z)/NumTr(1,2,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(1,2,z)/NumTr(1,2,z);
    r = r + 1;
    out{2+SearchNum+r,2}='statues only';
    out{2+SearchNum+r,3}='2';
    out{2+SearchNum+r,4}='2'; 
    out{2+SearchNum+r,5}='0';
    out{2+SearchNum+r,6}=NumTr(2,2,z);
    out{2+SearchNum+r,7}=NumAimFound(2,2,z)/NumTr(2,2,z);
    out{2+SearchNum+r,8}=TotNumErr(2,2,z)/NumTr(2,2,z);
    out{2+SearchNum+r,9}=SumPathDev(2,2,z)/NumTr(2,2,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(2,2,z)/NumTr(2,2,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(2,2,z)/NumTr(2,2,z);
    r = r + 1;
    out{2+SearchNum+r,2}='statues only';
    out{2+SearchNum+r,3}='3';
    out{2+SearchNum+r,4}='>2'; 
    out{2+SearchNum+r,5}='>0';
    out{2+SearchNum+r,6}=NumTr(3,2,z);
    out{2+SearchNum+r,7}=NumAimFound(3,2,z)/NumTr(3,2,z);
    out{2+SearchNum+r,8}=TotNumErr(3,2,z)/NumTr(3,2,z);
    out{2+SearchNum+r,9}=SumPathDev(3,2,z)/NumTr(3,2,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(3,2,z)/NumTr(3,2,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(3,2,z)/NumTr(3,2,z);
    r = r + 1; %10,21,32
    %***beg %% 27 Dec 2024
    out{2+SearchNum+r,2}='north and statues';
    out{2+SearchNum+r,3}='1';
    out{2+SearchNum+r,4}='1'; 
    out{2+SearchNum+r,5}='0';
    out{2+SearchNum+r,6}=NumTr(1,3,z);
    out{2+SearchNum+r,7}=NumAimFound(1,3,z)/NumTr(1,3,z);
    out{2+SearchNum+r,8}=TotNumErr(1,3,z)/NumTr(1,3,z);
    out{2+SearchNum+r,9}=SumPathDev(1,3,z)/NumTr(1,3,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(1,3,z)/NumTr(1,3,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(1,3,z)/NumTr(1,3,z);
    r = r + 1;
    out{2+SearchNum+r,2}='north and statues';
    out{2+SearchNum+r,3}='2';
    out{2+SearchNum+r,4}='2'; 
    out{2+SearchNum+r,5}='0';
    out{2+SearchNum+r,6}=NumTr(2,3,z);
    out{2+SearchNum+r,7}=NumAimFound(2,3,z)/NumTr(2,3,z);
    out{2+SearchNum+r,8}=TotNumErr(2,3,z)/NumTr(2,3,z);
    out{2+SearchNum+r,9}=SumPathDev(2,3,z)/NumTr(2,3,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(2,3,z)/NumTr(2,3,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(2,3,z)/NumTr(2,3,z);
    r = r + 1; %12,23,34
    out{2+SearchNum+r,2}='north and statues';
    out{2+SearchNum+r,3}='3';
    out{2+SearchNum+r,4}='>2'; 
    out{2+SearchNum+r,5}='>0';
    out{2+SearchNum+r,6}=NumTr(3,3,z);
    out{2+SearchNum+r,7}=NumAimFound(3,3,z)/NumTr(3,3,z);
    out{2+SearchNum+r,8}=TotNumErr(3,3,z)/NumTr(3,3,z);
    out{2+SearchNum+r,9}=SumPathDev(3,3,z)/NumTr(3,3,z);
    out{2+SearchNum+r,10}=SumAbsAngErr(3,3,z)/NumTr(3,3,z);
    out{2+SearchNum+r,11}=SumOptToRealPath(3,3,z)/NumTr(3,3,z);
    %***end %% 27 Dec 2024

end

r = r + 2;
%LastMeasuresForAim kamil 7.6.2024 - hodnoty z posledniho hledani cile 1-9
row = 2+SearchNum+r; %should start at row 44
out{row,1} = 'LastMeasuresForAim';
[out{row+1, 1:5}] = deal('Last goal search for each field','GoalField', 'duration', 'path efficiency', 'angle error');
for j=1:9
	[out{row+j+1,2:5}]=deal(j,LastMeasuresForAim(j,1), LastMeasuresForAim(j,2), LastMeasuresForAim(j,3));
end

xlswrite([FullFileName '.xls'], out); %write output table to xls file in the same folder as source data

end

%plot function 
function Obrazky(FD,PlotsInFigure,FileName,SubPlots,OrderTrials,TrajectoriesToShow)
    % arguments:
    % FD - all plot values
    % FileName
    % SubPlots - if to plot tracks in individual subplots
    % PlotsInFigure - how many subplots can be in one figure
    % OrderTrials - if to order trials from best to worse
    
    % ArenaLocX,ArenaLocY - subject position = track of one trial
    % AimX,AimY - %1x9 double - aim positions for 9 squres
    % CurBox - square number of aim, 1-9    
    % ErrLocX,ErrLocY - %position of the error
    % NumErr; %number of errors
    % IndicatedAng[ x y ] - pointing directios
    % TrialType - %different trial categorization [1,1,0,1] to [12,8,4,6
    % TrialTypeKE; %type of test trial - 1 to 3 (difficulty level)
    % AimFound - if the aim was found in tre trial
    % Cil - goal name, e.g. KOLIBRIKA
    % ToOptimalLength - number 1 - inf, to longer the worse
    if ~isempty(TrajectoriesToShow)
        FD = FD(TrajectoriesToShow);
    end
    Kategorie = unique([FD.TrialTypeKE]);  % trials categories 1-3
    for kat = 1:numel(Kategorie)
        tt = find(ismember([FD.TrialTypeKE] ,Kategorie(kat)) ); %indexes of this category in  FD
        ToOptimalLength = [FD(tt).ToOptimalLength];        
        if OrderTrials
            [~,it] = sort(ToOptimalLength); %indexes for sorting the trials
            tt = tt(it); %sort trials by ToOptimalLength - best to worse
        end
        ColorSet = distinguishable_colors(numel(tt)); %color to the chart
        for n = 1:numel(tt) %loop over tracks in this cateogory (i.e. difficulty level)
            if SubPlots %if to plot tracks in individual subplots
                c = ColorSet(1,:);
            else
                c = ColorSet(n,:);
            end
            m = tt(n); %absolute index in FD
            SearchNum = tt(n);
            %AimX = FD(m).X;
            %AimY = FD(m).Y;
            ArenaLocX = FD(m).ArenaLocX;
            ArenaLocY = FD(m).ArenaLocY;
            AimX = FD(m).AimX;
            AimY = FD(m).AimY;
            CurBox = FD(m).CurBox;
            %CurGoal = FD(m).CurGoal;
            ErrLocX = FD(m).ErrLocX;
            ErrLocY = FD(m).ErrLocY;
            NumErr = FD(m).NumErr;
            IndicatedAng = FD(m).IndicatedAng;
            TrialType = FD(m).TrialType;
            AimFound = FD(m).AimFound;
            Cil = FD(m).Cil;
            Cues = FD(m).Cues; %Cues: 1 = North shown, 2 = Statues shown
            if Cues == 1, CuesStr = 'North'; elseif Cues == 2, CuesStr = 'Statues'; elseif Cues == 3, CuesStr = 'N+S'; else CuesStr=''; end
            
            if SubPlots == 1 && rem(n,PlotsInFigure)==1 %if we plot subplots for individual tracks and this is the first track/subplots in this figure
				figurename = [ FileName ' - Level ' num2str(Kategorie(kat)) ' - Plot ' num2str(ceil(n/PlotsInFigure))];
                figure('Name',figurename,'position', [50, 50, 900, 700]);
            elseif SubPlots == 0 && n==1 %if we do not plot subplots and this is the first track
                figurename = [ FileName ' - Level ' num2str(Kategorie(kat)) ]; %nastartuju obrazek                
                figure('Name',figurename,'position', [50, 50, 900, 700]);
            end
			
            StartPlot = false; %if to plot common parts across subplots - all except track itself
            if SubPlots %whether to plot tracks in individual subplots
                PlotPosition=n;
                while PlotPosition>PlotsInFigure 
                    PlotPosition=PlotPosition-PlotsInFigure; % = rem(n,PlotsInFigure) ????
                end
                subplot(3,4,PlotPosition) 
                StartPlot = true; %kdyz zacinam subplot chci vzdy inicializovat obrazek
            elseif n==1
                StartPlot = true; % 
            end
            if StartPlot %common plotting across trials
                plot([AimX(1)+500 AimX(2)-500],[0-AimY(1) 0-AimY(2)],'k')  %plotting learned S sequence of squares      
                hold on
                plot([AimX(2)+500 AimX(3)-500],[0-AimY(2) 0-AimY(3)],'k')
                plot([AimX(3) AimX(6)],[0-AimY(3)-500 0-AimY(6)+500],'k')
                plot([AimX(6)-500 AimX(5)+500],[0-AimY(6) 0-AimY(5)],'k')
                plot([AimX(5)-500 AimX(4)+500],[0-AimY(5) 0-AimY(4)],'k')        
                plot([AimX(4) AimX(7)],[0-AimY(4)-500 0-AimY(7)+500],'k')
                plot([AimX(7)+500 AimX(8)-500],[0-AimY(7) 0-AimY(8)],'k')
                plot([AimX(8)+500 AimX(9)-500],[0-AimY(8) 0-AimY(9)],'k')
                
                %9 goal positions
                for box=1:9 %pro vsechny ctverce - louky                            
                     plot(AimX(box),0-AimY(box), '.k')                  
                end
                
                plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k') %square around 9 meadows
                
                %title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
                if SubPlots 
                    % trial number , found 1/0, errors ; goal name (e.g. PRASE)
                    title({[ '#' num2str(SearchNum) ' f' num2str(AimFound) ' e' num2str(NumErr) ' l:' CuesStr], Cil}) %  ' T' num2str(TrialType(1))
                else 
                    % cateogory (i.e. difficulty level) , found / trials, errors
                    title([  'Level ' num2str(kat) ' f' num2str(sum([FD(tt).AimFound])) '/' num2str(numel(tt)) ' e' num2str(sum([FD(tt).NumErr])) ] ) %  kat found/celkem
                end
            end

            plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'Color',c) %% plot track, from start to goal
            plot(ArenaLocX(2),0-ArenaLocY(2), '*','Color',c,'MarkerSize',15, 'MarkerFaceColor',c) %star as track start           
            plot(AimX(CurBox),0-AimY(CurBox), 'o','Color',c,'MarkerSize',10, 'MarkerFaceColor',c ) %position of goal animal
            
            if SubPlots == 0 % tracks numbers if plotting all tracks into one plot
                textoffset = 150;
                OF = [1 1; -1 -1; 1 -1; -1 1; 0 1; 1 0; 0 -1; -1 0; .5 .5; -.5 -.5; .5 -.5; -.5 .5]; %distribution of trial number around - each line is [x,y] offset for a trial
                OF = repmat(OF,4,1); %we need enoug rows for all possible training trials
                text(ArenaLocX(2)+textoffset*OF(n,1),0-ArenaLocY(2)+textoffset*OF(n,2),num2str(FD(m).Trial),'Color',c, 'FontSize',14); %number near start
                text(AimX(CurBox)+textoffset*OF(n,1),0-AimY(CurBox)+textoffset*OF(n,2),num2str(FD(m).Trial),'Color',c,'FontSize',14); %number near goal                
            end
            
            for i=1:NumErr    %for all errors                        
                 plot(ErrLocX(i), 0-ErrLocY(i),'or') %plot location of error
            end

            %directin of pointing
            plot([ArenaLocX(2) ArenaLocX(2)+IndicatedAng(1)],[0-ArenaLocY(2) 0-(ArenaLocY(2)+IndicatedAng(2))],'r', 'LineWidth',2)          
            plot(ArenaLocX(2)+IndicatedAng(1),0-(ArenaLocY(2)+IndicatedAng(2)),'.r' ); 
            
            axis equal
			axis ij
			set ( gca, 'xdir', 'reverse' )
            axis off %vymazu osy grafu, zustane je cerny ctverec
        end
    end
end