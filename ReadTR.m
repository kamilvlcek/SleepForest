function out=ReadTR(FileName)
%ReadTR compute proportion of real path length to optimal one
% categorize tasks according to the demands/difficulty level
% Eduard Kelemen (c) 3/2017

out{1,1}=FileName;
out{2,1}='num';
out{2,2}='aim';
out{2,3}='animal';
out{2,4}='duration';
out{2,5}='length';
out{2,6}='errors';
out{2,7}='squairepair'; %jmeno aktualni dvojice ctvercu
out{2,8}='squairepairno'; %cislo dvojice ctvercu v poradi
out{2,9}='errorsTR'; %pocet chyb podle TR souboru

FileNameShort = FileName; %uschovam na pozdeji
FileName=['d:\prace\mff\data\aappSeg\skriptyForest\output\' FileName '.tr'];


FileID=fopen(FileName);

SearchNum=0;
NL=0;line=[]; %line number
%while strcmp(line(1:6),' 0.000')==0
while isempty(strfind(line, 'JavaTime')); %musi tam byt neco pred zacatkem prvnich dat
    line=fgetl(FileID);
    NL=NL+1;
    if strfind(line, 'Aim position')
        Aim=GetAimPositions(line);
        AimX=Aim{1}; %double 9x6 + ctverce x stany
        AimY=Aim{2};
    end
end
n=strfind(line, 'text:Najdi');
Cil=line(n+11:end-2);
DLN=0; %data line number - one trial only
firstdataline=0;
NumErr=0;
FigureStarted = false; %jestli uz bylo nakreslene zakladni schema obrazku
fprintf('SquarePairs: ');
SquarePaireNo = 0;
ErrorsTR = 0;
while feof(FileID)==0
%while isempty(strfind(line, 'text:VYBORNE !'));

    line=fgetl(FileID);
    NL=NL+1;
    if strcmp(line(1),' ') %radky s ciselnymi daty - zacinaji mezerou
        DLN=DLN+1; %radky data pro tento trial
        if firstdataline==0
            divider=line(7);
            firstdataline=1;
        end
        k=strfind(line, divider); %hranice sloupcu
        time(DLN)=str2num(line(2:k(1)-1)); %#ok<*ST2NM>
        ArenaLocX(DLN)=str2num(line(k(2)+1:k(3)-1)); %pozice hrace na arene v tomto casovem okamziku
        ArenaLocY(DLN)=str2num(line(k(3)+1:k(4)-1));
    end   
    if strfind(line, 'Aim search') %trial start
        time=[];
        ArenaLocX=[];
        ArenaLocY=[];
        DLN=0; 
        NumErr=0; %pocet chyb v trialu
        ErrBox=[];
        ErrGoal=[];
    end
    if strfind(line, 'text:Najdi')
        n=strfind(line, 'text:Najdi');
        Cil=line(n+11:end-2); %jmeno zvirete, napriklad KOCKU
    end 
    if strfind(line,'Square Pair')
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
        ErrGoal(NumErr)=str2num(ErrAim(5)); %cislo stanu ve ctverci
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
        CurGoal=str2num(CurrentAim(5));
        % ---------- ZACINAM KRESLIT OBRAZEK ---------------     
        if ~FigureStarted
            figure('Name','Sumarni obrazek'); %jeden obrazek pro cely tr soubor?
            
            % pozice ctvercu
            X1=mean(AimX(1,:));Y1=mean(AimY(1,:));
            X2=mean(AimX(2,:));Y2=mean(AimY(2,:));
            X3=mean(AimX(3,:));Y3=mean(AimY(3,:));
            X4=mean(AimX(4,:));Y4=mean(AimY(4,:));
            X5=mean(AimX(5,:));Y5=mean(AimY(5,:));
            X6=mean(AimX(6,:));Y6=mean(AimY(6,:));        
            X7=mean(AimX(7,:));Y7=mean(AimY(7,:));
            X8=mean(AimX(8,:));Y8=mean(AimY(8,:));
            X9=mean(AimX(9,:));Y9=mean(AimY(9,:));        
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
              for i=1:6
                 
                 plot(AimX(box,i),0-AimY(box,i), 'ok')
              end
            end
            plot([-1700 3700 3700 -1700 -1700],0-[-1700 -1700 3700 3700 -1700], 'k') %nejake ohraniceni
            axis equal
            axis off
            title(strrep(FileNameShort, '_','\_')); 
            FigureStarted = true;
        end        
        
        for i=1:NumErr            
             plot(AimX(ErrBox(i),ErrGoal(i)),0-AimY(ErrBox(i),ErrGoal(i)), 'or') %cervenou barvou chybne nalezene cile
        end        
        plot(ArenaLocX(2:end),0-ArenaLocY(2:end),'b') %tohle je jedna trasa v trialu
        plot(AimX(CurBox,CurGoal),0-AimY(CurBox,CurGoal), 'og', 'MarkerSize',10) %zelenou barvou aktualni cil - nakonec, aby byl zeleny cil na povrchu
        
        Duration=time(end)-time(2); %cas  nalezeni cile
        Length=LengthofTrack(ArenaLocX(2:end),ArenaLocY(2:end)); %delka cesty do cile
        % titulek obrazku nepotrebuju, kdyz kreslim sumarni
        % title(['Search# ' num2str(SearchNum) '   ' CurrentAim '-' Cil '   duration: ' num2str(Duration) '   length: ' num2str(Length) '   Errors: ' num2str(NumErr)])
        
        % ----  vystupni tabulka  ---------------
        out{2+SearchNum,1}=SearchNum;
        out{2+SearchNum,2}=CurrentAim; %jmeno nelezeneho cile, napriklad AimE4
        out{2+SearchNum,3}=Cil;        %jmeno zvirete, napriklad KOCKU
        out{2+SearchNum,4}=Duration;   %cas  nalezeni cile
        out{2+SearchNum,5}=Length;     %celka cesty do cile
        out{2+SearchNum,6}=NumErr;     %pocet chyb v trialu
        out{2+SearchNum,7}=SquarePaire;     %jmeno dvojice ctvercu
        out{2+SearchNum,8}=SquarePaireNo;   %cislo dvojice ctvercu 1-N
        out{2+SearchNum,9}=ErrorsTR - ErrorsTRLast;   %pocet chyb podle TR souboru
    end
end
fprintf(' ...  finished\n');




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