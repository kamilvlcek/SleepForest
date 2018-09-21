function TrialType=DetTrialType(StEnd)

% output - TrialType(Type, Sequence length - num pairs, Sequence Turns, Alenas category) 

TrialType=0;
if (any(1==StEnd)&any(2==StEnd))||(any(2==StEnd)&any(3==StEnd))||(any(3==StEnd)&any(6==StEnd))||(any(5==StEnd)&any(6==StEnd))||(any(5==StEnd)&any(4==StEnd))||(any(4==StEnd)&any(7==StEnd))||(any(7==StEnd)&any(8==StEnd))||(any(8==StEnd)&any(9==StEnd))
   TrialType=[1,1,0,1]; %trained pair 
end
if (any(1==StEnd)&any(3==StEnd))||(any(4==StEnd)&any(6==StEnd))||(any(7==StEnd)&any(9==StEnd))
   TrialType=[2,2,0,2]; %sequence of two trained pairs, straight 
end
if (any(2==StEnd)&any(6==StEnd))||(any(3==StEnd)&any(5==StEnd))||(any(5==StEnd)&any(7==StEnd))||(any(4==StEnd)&any(8==StEnd))
   TrialType=[3,2,1,3]; %sequence of two trained pairs, with a turn 
end
if (any(1==StEnd)&any(6==StEnd))||(any(3==StEnd)&any(4==StEnd))||(any(6==StEnd)&any(7==StEnd))||(any(4==StEnd)&any(9==StEnd))
   TrialType=[4,3,1,3]; %sequence of three trained pairs, with one turn 
end
if (any(2==StEnd)&any(5==StEnd))||(any(5==StEnd)&any(8==StEnd))
   TrialType=[5,3,2,4]; %sequence of three trained pairs, with two turns 
end
if (any(1==StEnd)&any(5==StEnd))||(any(2==StEnd)&any(4==StEnd))||(any(3==StEnd)&any(7==StEnd))||(any(6==StEnd)&any(8==StEnd))||(any(5==StEnd)&any(9==StEnd))
   TrialType=[6,4,2,4]; %sequence of four trained pairs, (always with two turns)
end
if (any(1==StEnd)&any(4==StEnd))||(any(6==StEnd)&any(9==StEnd))
   TrialType=[7,5,2,4]; %sequence of five trained pairs, with two turns
end
if (any(2==StEnd)&any(7==StEnd))||(any(3==StEnd)&any(8==StEnd))
   TrialType=[8,5,3,5]; %sequence of five trained pairs, with three turns
end
if (any(1==StEnd)&any(7==StEnd))||(any(3==StEnd)&any(9==StEnd))
   TrialType=[9,6,3,5]; %sequence of six trained pairs, with three turns
end
if (any(2==StEnd)&any(8==StEnd))
   TrialType=[10,6,4,6]; %sequence of six trained pairs, with four turns
end
if (any(1==StEnd)&any(8==StEnd))||(any(2==StEnd)&any(9==StEnd))
   TrialType=[11,7,4,6]; %sequence of seven trained pairs, (always with four turns)
end
if (any(1==StEnd)&any(9==StEnd))
   TrialType=[12,8,4,6]; %sequence of eight trained pairs, (only one with four turns)
end

