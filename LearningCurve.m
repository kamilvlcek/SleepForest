function [  ] = LearningCurve( outdata )
%LEARNINGCURVE vyhodnoti ucici krivku z tabulky poskytnute pomoci ReadTR
% Kamil Vlcek (c) 4/2017 

SPs = cell( outdata{end,8},1); %seznam paru ctvercu jak sly za sebou
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
            SPs{SquarePaireNo} = SquarePaire;
            Err(SquarePaireNo) = ErrorsTR;
        end
    end
end
figure('Name','Learning Curve');
plot(Err,'o-');
set(gca,'XTick',1:numel(Err));
set(gca,'XTickLabel',SPs);
title(strrep(outdata{1,1}, '_','\_')); 
ylim([0 8]);
end

