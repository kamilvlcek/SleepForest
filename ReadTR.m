function out=ReadTR(FileNameIn, PlotSingleTrials,Colors)
%vytvori data pro Learning Curve
%ReadTR compute proportion of real path length to optimal one
% categorize tasks according to the demands/difficulty level
% Eduard Kelemen (c) 3/2017

if ~exist('PlotSingleTrials','var')
    PlotSingleTrials = 0; %By default, I want to print all three trials at once.
end %1 znamena subplot, 2 znamena opravdu sinle trials
if ~exist('Colors','var') %number of trials, i.e. number of different colors
    Colors = 50; %Certain, but too high a value for the number of trials 
end
ColorSet = distinguishable_colors(Colors); %ruzne barvy do grafu

if contains(FileNameIn,'\')
    FullFileName = FileNameIn;  % complete trajectory with parh
else
    FullFileName=['d:\prace\mff\data\aappSeg\NUDZ\results\spanav\' FileNameIn ];
end
%FileName=['D:\Users\kelemen\Data\VRKamil\' FileNameIn '.tr'];
FileNameShort = basename(FullFileName); %without path, only filename

out{1,1}=FileNameShort;
out{2,1}='num';
out{2,2}='aim';
out{2,3}='animal';
out{2,4}='duration';
out{2,5}='path deviation'; %length / optimal length
out{2,6}='errors';
out{2,7}='squairepair'; %name of the current pair of squares
out{2,8}='squairepairno'; %number of pairs of squares in sequence
out{2,9}='errorsTR'; %number of errors according to TR file


FileID=fopen(FullFileName);

SearchNum=0;
NL=0;line=[]; %line number
%while strcmp(line(1:6),' 0.000')==0
while isempty(strfind(line, 'JavaTime')); %musi tam byt neco pred zacatkem prvnich dat
    line=fgetl(FileID);
    NL=NL+1;
    if strfind(line, 'Aim position')
        Aim=GetAimPositionsb(line);
        AimX=Aim{1}; %double 9x6 + ctverce x stany
        AimY=Aim{2};
    end
end
n=strfind(line, 'ext:Najdete');
Cil=line(n+11:end-2);
DLN=0; %data line number - one trial only
firstdataline=0;
NumErr=0;
FigureStarted = false; %if the basic outline of the image has already been drawn
fprintf('SquarePairs: ');
SquarePaire = ''; %defaultni hodnota
SquarePaireNo = 0;
ErrorsTR = 0;
ErrorsTRLast = 0; %defaultni hodnota
stav=0; %state - 0=exploration, 1-pointing , 2- navigation
while feof(FileID)==0
%while isempty(strfind(line, 'text:VYBORNE !'));

    line=fgetl(FileID);
    NL=NL+1;
    if strcmp(line(1),' ') %Lines with numerical data begin with a space.
        DLN=DLN+1; %radky data pro tento trial
        if firstdataline==0
            divider=line(7);
            firstdataline=1;
        end
        k=strfind(line, divider); %column borders
        time(DLN)=str2num(line(2:k(1)-1)); %#ok<*ST2NM>
        ArenaLocX(DLN)=str2num(line(k(2)+1:k(3)-1)); %player position at this moment in time
        ArenaLocY(DLN)=str2num(line(k(3)+1:k(4)-1));
    end   
    if strfind(line, 'Aim search') %trial start
        time=[];
        ArenaLocX=[];
        ArenaLocY=[];
        DLN=0; 
        NumErr=0; %pocet chyb v trialu
        ErrBox=[];
    end
    if strfind(line,'Ukazte na')  
        stav=1; %state - 1-pointing , 2- navigation
    end       
    if strfind(line, 'text:Najdete')
        stav=2;
        n=strfind(line, 'text:Najdi');
        Cil=line(n+11:end-2); %animal name, e.g. KOCKU
    end 
    if strfind(line, 'text:Prozkoumej')
        stav=0;
    end    
    if contains(line,'Square Pair') && stav ==1
        n=strfind(line, 'Square Pair:');
        SquarePaire = line(n+13 : n+14);
        fprintf('%s ',SquarePaire);
        SquarePaireNo = SquarePaireNo +1;
        ErrorsTRLast = ErrorsTR; %uchovam posledni cislo, abych mohl pocet chyb pocitat zvlast v kazde dvojici ctvercu
    end
    if strfind(line,'Errors:')
        n = strfind(line,'Errors:');
        ErrorsTR = str2num(line(n+7 : end));  %pocet chyb podle TR souboru
    end
    if strfind(line, 'Avoid entrance:') %vstup do spatneho stanu
        NumErr=NumErr+1; %pocet chyb v trialu
        n=strfind(line, 'Avoid entrance:');
        ErrAim=line(n+15:n+19); %nazev cile, kam vstoupil
        if strcmp(ErrAim(4),'A')
            ErrBox(NumErr)=1; %#ok<*AGROW> 
        end
        if strcmp(ErrAim(4),'B')
            ErrBox(NumErr)=2;  %cislo ctverce 
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
        %ErrGoal(NumErr)=str2num(ErrAim(5)); %cislo stanu ve ctverci
    end
    if strfind(line, 'Aim entrance:') %vstup do spravneho stanu = konec jednoho trialu
        SearchNum=SearchNum+1; %cislo cile
        n=strfind(line, 'Aim entrance:');
        CurrentAim=line(n+13:n+17); %jmeno nelezeneho cile, napriklad AimE4
        if strcmp(CurrentAim(4),'A')
            CurBox=1;                  %cislo ctverce 
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
        %CurGoal=str2num(CurrentAim(5));
        % ---------- ZACINAM KRESLIT OBRAZEK ---------------     
        if ~FigureStarted || PlotSingleTrials > 0
            if PlotSingleTrials == 2
               figure('Name',[FileNameShort ' Trial' num2str(SearchNum) ' E' num2str(NumErr)]); %jeden obrazek pro kazdy trial
               FigureStarted = true;
               c = [0 0 1]; %blues
            elseif PlotSingleTrials == 1 %jeden obrazek se subploty pro kazdy trial
                PlotsInFigure = 16;  
                PlotNo = ceil(SearchNum/PlotsInFigure);
                if ~FigureStarted
                    figure('Name',['Sumarni obrazek ' FileNameShort ' #' num2str(PlotNo) ]);
                    FigureStarted = true;
                end
                subplot(4,4,SearchNum-(PlotNo-1)*PlotsInFigure);
                if rem(SearchNum,PlotsInFigure) == 0 %pokud uz posledni obrazek v plotu
                    FigureStarted = false;
                end
                c = [0 0 1]; %blues
            else        
               figure('Name',['Sumarni obrazek ' FileNameShort]); %jeden obrazek pro cely tr soubor?
               FigureStarted = true;              
            end
            % pozice ctvercu
            X1=mean(AimX(1));Y1=mean(AimY(1));
            X2=mean(AimX(2));Y2=mean(AimY(2));
            X3=mean(AimX(3));Y3=mean(AimY(3));
            X4=mean(AimX(4));Y4=mean(AimY(4));
            X5=mean(AimX(5));Y5=mean(AimY(5));
            X6=mean(AimX(6));Y6=mean(AimY(6));        
            X7=mean(AimX(7));Y7=mean(AimY(7));
            X8=mean(AimX(8));Y8=mean(AimY(8));
            X9=mean(AimX(9));Y9=mean(AimY(9));        
            %tady se kresli sekvence uceni - asi fixni pevne dana
            plot([X1+500 X2-500],[0-Y1 0-Y2],'k')
            hold on
            plot([X2+500 X3-500],[0-Y2 0-Y3],'k')        
            plot([X3 X6],[0-Y3-500 0-Y6+500],'k')        
            plot([X6-500 X5+500],[0-Y6 0-Y5],'k')        
            plot([X5-500 X4+500],[0-Y5 0-Y4],'k')        
            plot([X4 X7],[0-Y4-500 0-Y7+500],'k')        
            plot([X7+500 X8-500],[0-Y7 0-Y8],'k')        
            plot([X8+500 X9-500],[0-Y8 0-Y9],'k')

            %tohle jsou pozice vsech stanu
            for box=1:9
                 plot(AimX(box),0-AimY(box), 'ok')
            end
            plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k') %nejake ohraniceni
            axis equal
            axis off
            title(strrep(FileNameShort, '_','\_')); 
            
        end        
        
        for i=1:NumErr            
             plot(AimX(ErrBox(i)),0-AimY(ErrBox(i)), 'or') %cervenou barvou chybne nalezene cile
        end    
        if PlotSingleTrials == 0
             c = ColorSet(SearchNum,:);
        end
        plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'Color',c) %tohle je jedna trasa v trialu
        plot(ArenaLocX(1),0-ArenaLocY(1),'*','Color',c) %startovni misto
        plot(AimX(CurBox),0-AimY(CurBox), 'og', 'MarkerSize',10) %zelenou barvou aktualni cil - nakonec, aby byl zeleny cil na povrchu
        
        Duration=time(end)-time(2); %cas  nalezeni cile
        Length=LengthofTrack(ArenaLocX(2:end),ArenaLocY(2:end)); %delka cesty do cile
        OptimalLenght =dist(ArenaLocX(2),ArenaLocY(2),AimX(CurBox),AimY(CurBox)); %nejkratsi cesta do cile
        if PlotSingleTrials == 2
            title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
        elseif PlotSingleTrials == 1
            title(['# ' num2str(SearchNum) ' E' num2str(NumErr)] );
        end
        
        % ----  vystupni tabulka  ---------------
        out{2+SearchNum,1}=SearchNum;
        out{2+SearchNum,2}=CurrentAim; %jmeno nelezeneho cile, napriklad AimE4
        out{2+SearchNum,3}=Cil;        %jmeno zvirete, napriklad KOCKU
        out{2+SearchNum,4}=Duration;   %cas  nalezeni cile
        out{2+SearchNum,5}=Length/OptimalLenght;     % odchylka od nejkratsi cesty do cile
        out{2+SearchNum,6}=NumErr;     %pocet chyb v trialu
        out{2+SearchNum,7}=SquarePaire;     %jmeno dvojice ctvercu
        out{2+SearchNum,8}=SquarePaireNo;   %cislo dvojice ctvercu 1-N
        out{2+SearchNum,9}=ErrorsTR - ErrorsTRLast;   %pocet chyb podle TR souboru
    end
end
fprintf(' ...  finished with %i trials\n',SearchNum);


