function out=DetStartEndField(Xpos,Ypos,X,Y) 
%determines start and end field of a trial, inputs are X,Y positions on the
%track during the trial, and X,Y coordinates of the centers of the 9 fields
% the function is called by function ReadTR

FieldRadius=500;

for i=1:9
    if dist(Xpos(1),Ypos(1),X(i),Y(i))< FieldRadius
        StartField=i;
    end 
    if dist(Xpos(end),Ypos(end),X(i),Y(i))< FieldRadius
        EndField=i;
    end 
end

out=[StartField];%, EndField];