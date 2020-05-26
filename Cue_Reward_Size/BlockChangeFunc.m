function NextBlock = BlockChangeFunc(TrialRecord)
	totalCorrect = sum(TrialRecord.TrialErrors==0);
	if totalCorrect>0 && TrialRecord.TrialErrors(end)==0 && mod(totalCorrect, 20)==0 
		NextBlock = 1;
	else
		NextBlock = 0;
	end
end