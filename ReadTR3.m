function out=ReadTR3(FileNameIn)
%process the test data, plot the graph and return the result table
%compute proportion of real path length to optimal one
%categorize tasks according to the demands/difficulty level

% to do: angles, summary data

PlotsInFigure=15; %how many subplots can be in one image
if ~exist('SubPlots','var') 
    SubPlots = 1;   %subplots shown by default
end
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
out{2,18}='trial type Kamil';

FullFileName=['d:\prace\mff\data\aappSeg\skriptyForest\output\' FileNameIn ];
%FileName=['D:\Users\kelemen\Data\VRKamil\' FileNameIn '.tr'];


FileID=fopen(FullFileName);

SearchNum=0; %trial number
NL=0;line=[]; %line number
%while strcmp(line(1:6),' 0.000')==0
fprintf('        ');
%READing THE POSITIONs OF THE TENTs
while ~contains(line, 'Ukazte na')  %that concludes the search for a tent
    line=fgetl(FileID);
	fprintf('\b\b\b\b\b\b%5i', NL);
    NL=NL+1;
    if contains(line, 'Aim position') 
        Aim=GetAimPositions(line); 
        AimX=Aim{1}; %9x6 double - squaers and tents inside 
        AimY=Aim{2}; 
    end
%     if contains(line,'Avatar location changed:')  %not used
%         ba=strfind(line, '[');
%         bb=strfind(line, ',');
%         bc=strfind(line, ']');
%         StartLocX=str2double(line(ba+1:bb-1)); 
%         StartLocY=str2double(line(bb+2:bc-1));
%     end                                             %%%
end
n=strfind(line, 'text:Najdete');
Cil=line(n+11:end-2);
DLN=0;
firstdataline=0;
NumErr=0;

X(1)=mean(AimX(1,:));Y(1)=mean(AimY(1,:)); % centers of individual squares, X a Y, jako mean pozice stanu
X(2)=mean(AimX(2,:));Y(2)=mean(AimY(2,:));
X(3)=mean(AimX(3,:));Y(3)=mean(AimY(3,:));
X(4)=mean(AimX(4,:));Y(4)=mean(AimY(4,:));
X(5)=mean(AimX(5,:));Y(5)=mean(AimY(5,:));
X(6)=mean(AimX(6,:));Y(6)=mean(AimY(6,:));        
X(7)=mean(AimX(7,:));Y(7)=mean(AimY(7,:));
X(8)=mean(AimX(8,:));Y(8)=mean(AimY(8,:));
X(9)=mean(AimX(9,:));Y(9)=mean(AimY(9,:));

%figure
FIGUREDATA = {}; %there I will collect data for the images, so I can then draw them in manual order

while feof(FileID)==0
    line=fgetl(FileID);
    NL=NL+1;
    if strcmp(line(1),' ') %Dataline
        DLN=DLN+1;
        if firstdataline==0 %first row with column description
            divider=line(7); 
            firstdataline=1;
        end
        k=strfind(line, divider);
        %three data from the track - data about the position of the subject
        time(DLN)=str2double(line(2:k(1)-1));
        ArenaLocX(DLN)=str2double(line(k(2)+1:k(3)-1)); %pozice subjektu = track v jednom trialu
        ArenaLocY(DLN)=str2double(line(k(3)+1:k(4)-1));
    end   
    if contains(line,'space') %pointing to the target
        Angle=str2double(line(k(7)+1:k(8)-1));
        Angle=rem(Angle,360);
        if Angle<0
            Angle=Angle+360;
        end
    end 
%     if contains(line,'Avatar location changed:')     %not used
%         ba=strfind(line, '[');
%         bb=strfind(line, ',');
%         bc=strfind(line, ']');
%         StartLocX=str2double(line(ba+1:bb-1)); %not used
%         StartLocY=str2double(line(bb+2:bc-1)); %not used
%     end                                             %%%
    if contains(line, 'text:Najdete')
        time=[];
        ArenaLocX=[];
        ArenaLocY=[];
        DLN=0;
        NumErr=0;
        ErrBox=[];
        ErrGoal=[];
        n=strfind(line, 'text:Najdete');
        Cil=line(n+11:end-2); %goal name, e.g. KOLIBRIKA
    end 
    if contains(line, 'Avoid entrance:') %entering the wrong tent
%         NumErr=NumErr+1;
%         n=strfind(line, 'Avoid entrance:');
        ErrAim=line(n+15:n+19); %napr AimA2 
        if strcmp(ErrAim(4),'A') %square number
            ErrBox(NumErr)=1; %#ok<*AGROW>
        elseif strcmp(ErrAim(4),'B')
%             ErrBox(NumErr)=2;
        elseif strcmp(ErrAim(4),'C')
%             ErrBox(NumErr)=3;
        elseif strcmp(ErrAim(4),'D')
%             ErrBox(NumErr)=4;
        elseif strcmp(ErrAim(4),'E')
%             ErrBox(NumErr)=5;
        elseif strcmp(ErrAim(4),'F')
%             ErrBox(NumErr)=6;
        elseif strcmp(ErrAim(4),'G')
%             ErrBox(NumErr)=7;
        elseif strcmp(ErrAim(4),'H')
%             ErrBox(NumErr)=8;
        elseif strcmp(ErrAim(4),'I')
%             ErrBox(NumErr)=9;
        end        
%         ErrGoal(NumErr)=str2num(ErrAim(5));
     end
    
    
    %ukonceni hledani cile 
    if contains(line, 'Aim entrance:') || contains(line, 'Aim not found:')

        SearchNum=SearchNum+1; %trial number
        
        if contains(line, 'Aim entrance:')
            n=strfind(line, 'Aim entrance:');
            CurrentAim=line(n+13:n+17); %%%
            AimFound=1;
        end
        if contains(line, 'Aim not found:')
            n=strfind(line, 'Aim not found:');
            CurrentAim=line(n+14:n+18); %%%
            AimFound=0;
        end
        if strcmp(CurrentAim(4),'A')
            CurBox=1; %cislo ctverce s cilem
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
        CurGoal=str2double(CurrentAim(5)); %cislo stanu ve ctverci s cilem
        
        StartEndField=DetStartEndField(ArenaLocX(2:end),ArenaLocY(2:end),X,Y) %; %find start and end field - uz jenom start field
		CurBox
        TrialType=DetTrialType([StartEndField(1) CurBox]) %;  %determine the type of test trial 
        
        if exist('Angle','var')   %  Kamil 6.11.2018 -  Adam24_8_18_3_0.tr vubec neukazal                 
            IndicatedAng=DistAng2Pos(400,Angle/360*2*3.141592653);           
        else
            IndicatedAng = [0 0 ];
            Angle = NaN;
        end        
                        
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
        RealAngle=XY2ang(AimX(CurBox,CurGoal)-ArenaLocX(2),AimY(CurBox,CurGoal)-ArenaLocY(2))/(2*3.141592653)*360;
        %RealAngle=XY2ang(ArenaLocX(end)-ArenaLocX(2),ArenaLocY(end)-ArenaLocY(2))/(2*3.141592653)*360;
        AngleError=Angle-RealAngle;
        if AngleError>180
            AngleError=AngleError-360;
        end
        if AngleError<-180
            AngleError=AngleError+360;
        end
               
        %fill in the figure data that we can draw later
        FIGUREDATA(SearchNum).X = X;
        FIGUREDATA(SearchNum).Y = Y;
        FIGUREDATA(SearchNum).ArenaLocX = ArenaLocX;
        FIGUREDATA(SearchNum).ArenaLocY = ArenaLocY;
        FIGUREDATA(SearchNum).AimX = AimX;
        FIGUREDATA(SearchNum).AimY = AimY;
        FIGUREDATA(SearchNum).CurBox = CurBox;
        FIGUREDATA(SearchNum).CurGoal = CurGoal;
        FIGUREDATA(SearchNum).ErrBox = ErrBox;
        FIGUREDATA(SearchNum).ErrGoal = ErrGoal;
        FIGUREDATA(SearchNum).NumErr = NumErr;
        FIGUREDATA(SearchNum).IndicatedAng = IndicatedAng;
        FIGUREDATA(SearchNum).TrialType = TrialType(1);
        FIGUREDATA(SearchNum).AimFound = AimFound;
        FIGUREDATA(SearchNum).Cil = Cil;
        FIGUREDATA(SearchNum).ToOptimalLength = ToOptimalLength; 
        
        out{2+SearchNum,1}=SearchNum;
        out{2+SearchNum,2}=CurrentAim;
        out{2+SearchNum,3}=Cil;
        out{2+SearchNum,4}=AimFound;
        out{2+SearchNum,5}=Duration;
        out{2+SearchNum,6}=Length;
        out{2+SearchNum,7}=ToOptimalLength;
        out{2+SearchNum,8}=NumErr; %'errors'
        out{2+SearchNum,9}=StartEndField(1); %'StartField'
        out{2+SearchNum,10}=CurBox;  %'GoalField'
        out{2+SearchNum,11}=TrialType(2); %'N of trained pairs in sequence'
        out{2+SearchNum,12}=TrialType(3); %'N of turns in sequence'
        out{2+SearchNum,13}=TrialType(4); %'trial category Alena'
        out{2+SearchNum,14}=Angle;
        out{2+SearchNum,15}=RealAngle;
        out{2+SearchNum,16}=AngleError;
        out{2+SearchNum,17}=TrialType(1); %'trial category'        
        Kategorie = [1 2 3 3 4 4 4 5 5 5 5 5 ];%trenovane dvojice, prima trasa, 1 roh, 2 rohy, 3 a 4 rohy
        out{2+SearchNum,18}=Kategorie(TrialType(1)); %'trial type Kamil'       
        
        clear Angle; %if subject hadn't point to target in the next trial
    end
end

% udelam obrazek dodatecne
Obrazky(FIGUREDATA,PlotsInFigure,FileName,SubPlots);
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
    NumNans = 0;
    for i=1:SearchNum
        if out{2+i,17}==TrialType  
            NumTrainedPairsTests=NumTrainedPairsTests+1;
            NumAimFound=NumAimFound+out{2+i,4};
            ErrTrainedPairsTests=ErrTrainedPairsTests+out{2+i,8};
            PathDevTrainedPairsTests=PathDevTrainedPairsTests+out{2+i,7};
            if isnan(out{2+i,16}) %pokud treba neukazal v nejakem trialu - kamil
               NumNans = NumNans +1; 
            else
               AngleErrTrainedPairsTests=AngleErrTrainedPairsTests+abs(out{2+i,16});
            end
        end
    end

    out{2+SearchNum+3+TrialType,5}=NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,6}=NumAimFound/NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,7}=ErrTrainedPairsTests/NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,8}=PathDevTrainedPairsTests/NumTrainedPairsTests;
    out{2+SearchNum+3+TrialType,9}=AngleErrTrainedPairsTests/(NumTrainedPairsTests-NumNans);
end

%kamil - tabulka prumeru podle TrialType Kamil
D = cell2mat(out(3:2+SearchNum,4:18)); %data trialu do matrix
outY = 2+SearchNum+3+TrialType+2; %od ktereho radku zacim psat dal svoje data
out{outY,1} = 'TrialType Kamil';
for TrialTypeK = 1:5
    out{outY + TrialTypeK,1} = TrialTypeK;
    iD = D(:,15)==TrialTypeK; %index v D s trialtypeK
    out{outY + TrialTypeK,5} = sum(iD); %pocet trialu
    out{outY + TrialTypeK,6} = mean(D(iD,1)); % %nalezeni cile
    out{outY + TrialTypeK,7} = mean(D(iD,5)); % prumerny pocet chyb
    out{outY + TrialTypeK,8} = mean(D(iD,4)); % mean path deviation
    out{outY + TrialTypeK,9} = nanmean(abs(D(iD,13))); % mean ABS angle error
end

end

function Obrazky(FD,PlotsInFigure,FileName,SubPlots)
    % parametry:
    % SearchNum - cislo trialu
    % PlotsInFigure - kolik obrazku v obrazku
    % X,Y - stredy jednotlivych ctvercu, X a Y, jako mean pozice stanu
    % ArenaLocX,ArenaLocY - pozice subjektu = track v jednom trialu
    % AimX,AimY - pozice stanu 9x6 double
    % CurBox - cislo ctverce s cilem
    % CurGoal - cislo stanu ve ctverci s cilem
    % ErrBox,ErrGoal - cisla ctvercu a stanu ve ctverci s chybama - array
    % IndicatedAng[ x y ] - smer ukazani, prevedeny na relativni souradnice 
    % TrialType - typ testoveho trialu podle obtiznosti
    % AimFound - jesti byl cil nalezen
    % Cil - pojmenovani cile, napriklad KOCKU
    Kategorie = { 1 , 2, [3 4], [5 6 7], [8 9 10 11 12]}; %trenovane dvojice, prima trasa, 1 roh, 2 rohy, 3 a 4 rohy
    for kat = 1:numel(Kategorie)
        tt = find(ismember([FD.TrialType] ,Kategorie{kat}) ); %indexy v FD, kde jsou prislusne TrialType
        ToOptimalLength = [FD(tt).ToOptimalLength];
        [~,it] = sort(ToOptimalLength); %ziskam indexy pro trideni trialu
        tt = tt(it); %seradim trialy podle relativni delky trasy
        ColorSet = distinguishable_colors(numel(tt)); %ruzne barvy do grafu
        for n = 1:numel(tt)
            if SubPlots
                c = ColorSet(1,:);
            else
                c = ColorSet(n,:);
            end
            m = tt(n); %skutecny index v poli DF
            SearchNum = tt(n);
            X = FD(m).X;
            Y = FD(m).Y;
            ArenaLocX = FD(m).ArenaLocX;
            ArenaLocY = FD(m).ArenaLocY;
            AimX = FD(m).AimX;
            AimY = FD(m).AimY;
            CurBox = FD(m).CurBox;
            CurGoal = FD(m).CurGoal;
            ErrBox = FD(m).ErrBox;
            ErrGoal = FD(m).ErrGoal;
            NumErr = FD(m).NumErr;
            IndicatedAng = FD(m).IndicatedAng;
            TrialType = FD(m).TrialType;
            AimFound = FD(m).AimFound;
            Cil = FD(m).Cil;
            
            StartPlot = false; %jestli se maji kresli spolecne veci - vse krome tracku
            if SubPlots == 1 && rem(n,PlotsInFigure)==1
				figurename = [ FileName ' - TT ' num2str(Kategorie{kat}) ' - Plot ' num2str(ceil(n/PlotsInFigure))];
            elseif SubPlots == 0 && n==1 %jestli se nekresli subploty a je to prvni track
                figurename = [ FileName ' - TT ' num2str(Kategorie{kat}) ]; %nastartuju obrazek
                StartPlot = true; %a budu ho chcit inicializovat
            end
			figure('Name',figurename,'position', [50, 50, 900, 700]);
            if SubPlots == 1 %mam obrazky rozdelit do ruznych subplotu
                PlotPosition=n;
                while PlotPosition>PlotsInFigure 
                    PlotPosition=PlotPosition-PlotsInFigure;
                end
                subplot(3,5,PlotPosition)
                StartPlot = true; %kdyz zacinam subplot chci vzdy inicializovat obrazek
            end
            if StartPlot %veci spolecne pro vsechny subploty
                plot([X(1)+500 X(2)-500],[0-Y(1) 0-Y(2)],'k')  %kreslim trasu pres ctverce      
                hold on
                plot([X(2)+500 X(3)-500],[0-Y(2) 0-Y(3)],'k')
                plot([X(3) X(6)],[0-Y(3)-500 0-Y(6)+500],'k')
                plot([X(6)-500 X(5)+500],[0-Y(6) 0-Y(5)],'k')
                plot([X(5)-500 X(4)+500],[0-Y(5) 0-Y(4)],'k')        
                plot([X(4) X(7)],[0-Y(4)-500 0-Y(7)+500],'k')
                plot([X(7)+500 X(8)-500],[0-Y(7) 0-Y(8)],'k')
                plot([X(8)+500 X(9)-500],[0-Y(8) 0-Y(9)],'k')
                
                %nakreslim vsechny stany 
                for box=1:9 %pro vsechny ctverce - louky
                  for j=1:6 %pro vsechny stany na louce             
                     plot(AimX(box,j),0-AimY(box,j), '.k')
                  end
                end
                
                plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k') %ctverec kolem 9 luk
                
                %title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
                if SubPlots 
                    title({[ '#' num2str(SearchNum) ' T' num2str(TrialType(1)) ' f' num2str(AimFound) ' e' num2str(NumErr)], Cil})
                else
                    title([  'Type ' num2str(kat) ' f' num2str(sum([FD(tt).AimFound])) '/' num2str(numel(tt)) ] ) %  kat found/celkem
                end
            end

            plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'Color',c) %% nakreslim posledni track, od startu k cili                       
            plot(ArenaLocX(2),0-ArenaLocY(2), '*','Color',c,'MarkerSize',15, 'MarkerFaceColor',c) %pocatecni bod trasy            
            plot(AimX(CurBox,CurGoal),0-AimY(CurBox,CurGoal), 'o','Color',c,'MarkerSize',10, 'MarkerFaceColor',c ) %nakreslim zelene pozici ciloveho zvirete
            
            if SubPlots == 0 %pokud vsechny tracky do jednoho, potrebuju cisla tracku na jejich rozliseni
                textoffset = 150;
                OF = [1 1; -1 -1; 1 -1; -1 1; 0 1; 1 0; 0 -1; -1 0]; %potrebuju cislicka rozhazet podle trialu - co radek to trial, sloupce jsou x a y
                text(ArenaLocX(2)+textoffset*OF(n,1),0-ArenaLocY(2)+textoffset*OF(n,2),num2str(n),'Color',c, 'FontSize',14); %u startu
                text(AimX(CurBox,CurGoal)+textoffset*OF(n,1),0-AimY(CurBox,CurGoal)+textoffset*OF(n,2),num2str(n),'Color',c,'FontSize',14); %u cile                
            end
            
            for i=1:NumErr    %pro vsechny chyby         
                 plot(AimX(ErrBox(i),ErrGoal(i)),0-AimY(ErrBox(i),ErrGoal(i)), '.r') 
                 plot(AimX(ErrBox(i),ErrGoal(i)),0-AimY(ErrBox(i),ErrGoal(i)), 'or') %nakreslim chybove pokusy
            end

            %smeru ukazani 
            plot([ArenaLocX(2) ArenaLocX(2)+IndicatedAng(1)],[0-ArenaLocY(2) 0-(ArenaLocY(2)+IndicatedAng(2))],'r', 'LineWidth',2)          
            plot(ArenaLocX(2)+IndicatedAng(1),0-(ArenaLocY(2)+IndicatedAng(2)),'.r' ); 
            
            axis equal
			axis ij
			set ( gca, 'xdir', 'reverse' )
            axis off %vymazu osy grafu, zustane je cerny ctverec
        end
    end
end