function out=DistAng2Pos(dist,ang)  %ang in rad

if ang<0
    ang=ang+(2*pi);
end
if ang==0
    x=dist; y=0;
end
if ang>0 && ang<pi/2
    x=sqrt(dist*dist/(1+tan(ang)*tan(ang)));
    y=tan(ang)*x;
end
if ang==pi/2
    x=0;y=dist;
end
if ang>pi/2 && ang<pi
    x=0-sqrt(dist*dist/(1+tan(ang)*tan(ang)));
    y=tan(ang)*x;
end
if ang==pi
    x=0-dist;y=0;
end
if ang>pi && ang<pi/2*3
    x=0-sqrt(dist*dist/(1+tan(ang)*tan(ang)));
    y=tan(ang)*x;
end
if ang==pi/2*3
    x=0;y=0-dist;
end
if ang>pi/2*3 && ang<pi*2
    x=sqrt(dist*dist/(1+tan(ang)*tan(ang)));
    y=tan(ang)*x;
end
out=[x,y];
