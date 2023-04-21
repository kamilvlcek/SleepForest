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
    PathDev = zeros(outdata{end,8},1); %cas nalezeni cile
    PocetSP = zeros(outdata{end,8},1); %pocet tohoto paru ctvercu
    
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
            if strcmp(SquarePaire,SquarePaireNext)== 0 %pokud jsou ruzne
                SquarePairePocet = numel(find(strcmp(SPs, SquarePaire)));
                SPs{SquarePaireNo} = SquarePaire;
                SPpocty(SquarePaireNo) = SquarePairePocet + 1; %kolikate to je opakovani tehle dvojice ctvercu
                Err(SquarePaireNo) = Err(SquarePaireNo) + ErrorsTR;
                PathDev(SquarePaireNo) =  PathDev(SquarePaireNo) + outdata{j,5};
                PocetSP(SquarePaireNo) = PocetSP(SquarePaireNo) + 1;
            end
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
    figure(fhe); %aktivuju figure 
        plot(Err,'o-');
        hold all; %ruzne barvy
    figure(fhd); %aktivuju figure 
        plot(PathDev,'o-');    
        hold all; %ruzne barvy
    
    if trialsmax == numel(Err) %pokud je zde maximalni pocet trialu
        figure(fhe); set(gca,'XTick',1:numel(Err));
        figure(fhd); set(gca,'XTick',1:numel(Err));
        for j = 1:numel(SPs)
            SPs{j} = [SPs{j} num2str(SPpocty(j))];
        end
        figure(fhe); set(gca,'XTickLabel',SPs); xtickangle(90); %popisky osy x
        figure(fhd); set(gca,'XTickLabel',SPs); xtickangle(90); %popisky osy x
    end
    if numel(DATA) == 1
        figure(fhe); title(strrep(outdata{1,1}, '_','\_')); ylabel('Learning Curve Errors');
        figure(fhd); title(strrep(outdata{1,1}, '_','\_')); ylabel('Learning Curve PathDev');
    else
        figure(fhe); title('Errors'); 
        figure(fhd); title('PathDev'); 
    end
    
    
    
end
%figure(fhe); ylim([0 8]);
%figure(fhd); ylim([0 20]);
if numel(DATA) > 1 
     figure(fhe); legend(subjects);
     figure(fhd); legend(subjects);
end

