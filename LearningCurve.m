function [  ] = LearningCurve( DATA )
%LEARNINGCURVE evaluate and plot the learning curve from the table provided using ReadTR
% Kamil Vlcek (c) 4/2017 

figurestarted = false;
xaxisploted = false;
subjects = cell(numel(DATA),1);
trialsmax = 0;
for s = 1:numel(DATA) %subjecs in cells of DATA   
    outdata = DATA{s}; %data from one subject
    subjects{s} = strrep(outdata{1,1}, '_','\_');
    SPs = cell( outdata{end,8},1); %list of pairs of squares as they appear in sequence
    SPpocty = zeros(outdata{end,8},1);  %Which repetition of this pair of squares is this?
    Err  = zeros(outdata{end,8},1); %number of errors
    PathDev = zeros(outdata{end,8},1); %path deviation
    PocetSP = zeros(outdata{end,8},1); %repetions of this pair of squares
    Aims = cell(outdata{end,8},1); %aim - A, B, C etc
    
    for j = 1:size(outdata,1)
        if (j>=3)
            SquarePaire = outdata{j,7};        
            if j < size(outdata,1)
                SquarePaireNext = outdata{j+1,7};
            else
                SquarePaireNext = '';
            end
            SquarePaireNo = outdata{j,8};
            ErrorsTR = outdata{j,6};
            Aim = outdata{j,2};
            %if strcmp(SquarePaire,SquarePaireNext)== 0 %pokud jsou ruzne
                SquarePairePocet = numel(find(strcmp(SPs, SquarePaire))); %how many time this square pair was already
                SPs{SquarePaireNo} = SquarePaire; %series of squarepairs
                SPpocty(SquarePaireNo) = SquarePairePocet + 1; %Which repetition of this pair of squares is this?
                Err(SquarePaireNo) = Err(SquarePaireNo) + ErrorsTR;
                PathDev(SquarePaireNo) =  PathDev(SquarePaireNo) + outdata{j,5};
                PocetSP(SquarePaireNo) = PocetSP(SquarePaireNo) + 1;
                Aims(SquarePaireNo) = {Aim(4)}; %only the letter of the aim square
            %end
        end
    end
    
    PathDev = PathDev ./ PocetSP;
    trialsmax = max(trialsmax,numel(Err));
    if ~figurestarted
        fhe = figure('Name','Learning Curve Errors', 'Position',[100, 100, 900, 400]);        
        fhd = figure('Name','Learning Curve PathDev', 'Position',[100, 100, 900, 400]);    
        figurestarted = true;
    else
        
    end
    figure(fhe); %activate figure
        plot(Err,'o-');
        hold all; %different colors
    figure(fhd); %activate figure
        plot(PathDev,'o-');    
        hold all; %different colors
    
    if trialsmax == numel(Err) && ~xaxisploted %if there is maximum number of trials for this subjects
        figure(fhe); set(gca,'XTick',1:numel(Err));
        figure(fhd); set(gca,'XTick',1:numel(Err));
        for j = 1:numel(SPs)
            SPs{j} = [SPs{j} num2str(SPpocty(j))];
        end
        figure(fhe); set(gca,'XTickLabel',SPs); xtickangle(90); %popisky osy x
        figure(fhd); set(gca,'XTickLabel',SPs); xtickangle(90); %popisky osy x
        if numel(DATA) == 1
            figure(fhe); title(strrep(outdata{1,1}, '_','\_')); ylabel('Learning Curve Errors');
            figure(fhd); title(strrep(outdata{1,1}, '_','\_')); ylabel('Learning Curve PathDev');
        else
            figure(fhe); title('Errors'); 
            figure(fhd); title('PathDev'); 
        end
        xaxisploted = true;
    end
    
end
%figure(fhe); ylim([0 8]);
%figure(fhd); ylim([0 20]);
if numel(DATA) > 1 
     figure(fhe); legend(subjects);
     figure(fhd); legend(subjects);
end

