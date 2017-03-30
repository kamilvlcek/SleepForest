function out=LengthofTrack(ArenaLocX,ArenaLocY)

L=0;
for i=2:length(ArenaLocX)
    L=L+sqrt((ArenaLocX(i)-ArenaLocX(i-1))^2+(ArenaLocY(i)-ArenaLocY(i-1))^2);
end

out=L;