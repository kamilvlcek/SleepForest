function [  ] = LearningCurve( DATA )
%LEARNINGCURVE vyhodnoti ucici krivku z tabulky poskytnute pomoci ReadTR
% Kamil Vlcek (c) 4/2017 

figurestarted = false;
subjects = cell(numel(DATA),1);
trialsmax = 0;
for s = 1:numel(DATA) %subjekty v cells    
    outdata = DATA{s}; %data z jednoho subjektu
    subjects{s} = strrep(outdata{1,1}, '_','\_');
    SPs = cell( outdata{end,8},1); %seznam paru ctvercu jak sly za sebou
    SPpocty = zeros(outdata{end,8},1);
    Err  = zeros(outdata{end,8},1); %pocet chyb

    for j = 1:size(outdata,1)
        if (j>=3)
            SquarePaire = outdata{j,7};        
            if j < size(outdata,1)
                SquarePaireNext = outdata{j+1,7};
            else
                SquarePaireNext = '';
            end
            SquarePaireNo = outdata{j,8};
            ErrorsTR = outdata{j,9};
            if strcmp(SquarePaire,SquarePaireNext)== 0 %pokud jsou ruzne
                SquarePairePocet = numel(find(strcmp(SPs, SquarePaire)));
                SPs{SquarePaireNo} = SquarePaire;
                SPpocty(SquarePaireNo) = SquarePairePocet + 1; %kolikate to je opakovani tehle dvojice ctvercu
                Err(SquarePaireNo) = ErrorsTR;
            end
        end
    end
    
    trialsmax = max(trialsmax,numel(Err));
    if ~figurestarted
        figure('Name','Learning Curve', 'Position',[100, 100, 900, 400]);        
        figurestarted = true;
    end
    plot(Err,'o-');
    hold all; %ruzne barvy
    if trialsmax == numel(Err) %pokud je zde maximalni pocet trialu
        set(gca,'XTick',1:numel(Err));
        for j = 1:numel(SPs)
            SPs{j} = [SPs{j} num2str(SPpocty(j))];
        end
        set(gca,'XTickLabel',SPs); %popisky osy x
    end
    if numel(DATA) == 1
        title(strrep(outdata{1,1}, '_','\_')); 
    end
    
end
ylim([0 8]);
if numel(DATA) > 1 
    legend(subjects);
end

