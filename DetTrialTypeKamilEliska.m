function TrialType=DetTrialTypeKamilEliska(StEnd)

TrialType=3; % sequence with turns

if (any(1==StEnd)&&any(2==StEnd))||(any(2==StEnd)&&any(3==StEnd))||(any(3==StEnd)&&any(6==StEnd))||(any(5==StEnd)&&any(6==StEnd))||(any(5==StEnd)&&any(4==StEnd))||(any(4==StEnd)&&any(7==StEnd))||(any(7==StEnd)&&any(8==StEnd))||(any(8==StEnd)&&any(9==StEnd))
   TrialType=1; %trained pair 
end

if (any(1==StEnd)&&any(3==StEnd))||(any(4==StEnd)&&any(6==StEnd))||(any(7==StEnd)&&any(9==StEnd))
   TrialType=2; %sequence of two trained pairs, no turns
end
