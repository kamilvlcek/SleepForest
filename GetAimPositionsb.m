function out=GetAimPositionsb(line)
%prepared in March 2023
%returns {AimX(1,9),AimY(1,9)}, with ordered positions of AimA,AimB ... AimI
AimX = zeros(1,9); % prealocate - Kamil
AimY = zeros(1,9);
        %aimA        
        k=strfind(line,'AimA[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(1)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(1)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));
        
        %aimB
        k=strfind(line,'AimB[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(2)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(2)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));  
        
        %aimC
        k=strfind(line,'AimC[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(3)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(3)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));
        
        %aimD
        k=strfind(line,'AimD[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(4)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(4)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));
        
        %aimE
        k=strfind(line,'AimE[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(5)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(5)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));        
                
        %aimF
        k=strfind(line,'AimF[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(6)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(6)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));        
        
        %aimG
        k=strfind(line,'AimG[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(7)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(7)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));

        %aimH
        k=strfind(line,'AimH[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(8)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(8)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));

        %aimI
        k=strfind(line,'AimI[');
        l=strfind(line(k(1):k(1)+20),',');
        AimX(9)=str2num(line(k(1)+5:k(1)+l(1)-2));
        AimY(9)=str2num(line(k(1)+l(1)+1:k(1)+l(2)-2));     
        
        out{1}=AimX;
        out{2}=AimY;