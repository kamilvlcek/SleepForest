function ang=XY2ang(X, Y)  %ang in rad

if X>0 && Y==0
    ang=0;
end
if X>0 && Y>0
    ang=atan(Y/X);
end
if X==0 && Y>0
    ang=pi/2;
end
if X<0 && Y>0
    ang=pi+atan(Y/X);
end
if X<0 && Y==0
    ang=pi;
end
if X<0 && Y<0
    ang=pi+atan(Y/X);
end
if X==0 && Y<0
    ang = pi/2*3;
end
if X>0 && Y<0
    ang=2*pi+atan(Y/X);
end