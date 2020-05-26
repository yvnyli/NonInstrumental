function NextBlock = NonInstrumentalBlockChangeFunc(TrialRecord)
% this block change function causes a block change every x number of
% correct trials
% Yvonne Li 3/20/2020
  numCorrectPerBlock = 50;
  
	totalCorrect = sum(TrialRecord.TrialErrors==0);
	if totalCorrect>0 ... % work around edge case for mod
      && TrialRecord.TrialErrors(end)==0 ... % work around edge case of getting the first trial wrong
      && mod(totalCorrect, numCorrectPerBlock)==0 % because totalCorrect is within session
		NextBlock = 1;
	else
		NextBlock = 0;
	end
end
