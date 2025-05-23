function out=DetStartEndField(Xpos,Ypos,AimX,AimY) 
%determines start and end field of a trial, inputs are X,Y positions on the
%track during the trial, and X,Y coordinates of the centers of the 9 fields
% the function is called by function ReadTR

FieldRadius=1000;

for i=1:9
%     i %%%
%     dist(Xpos(1),Ypos(1),X(i),Y(i)) %%%
    if dist(Xpos(1),Ypos(1),AimX(i),AimY(i))< FieldRadius
        StartField=i;
    end 
    if dist(Xpos(end),Ypos(end),AimX(i),AimY(i))< FieldRadius
        EndField=i;
    end 
end

out=[StartField];%, EndField];