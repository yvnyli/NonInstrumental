
% This task requires that either an "eye" input or joystick (attached to the
% eye input channels) is available to perform the necessary responses.
%
% During a real experiment, a task such as this should make use of the
% "eventmarker" command to keep track of key actions and state changes (for
% instance, displaying or extinguishing an object, initiating a movement, etc).

% DEFINE TASKOBJECTS
fixation_point = 1;
trialGate = 2;
highDcue = 3;
highDmaskArray = [4,9,10];
BlockChangeFlash = 5;
lowdcue1 = 6;
lowdcue2 = 7;
lowdmaskArray = [8,11,12];

% DEFINE EDITABLE VARIABLES
editable('wait_for_fix');
editable('initial_fix');
editable('reveal_fix');
editable('interaction_time');
editable('half_iti');
editable('FP_fix_radius');
editable('target_fix_radius');
editable('reward_small');
editable('reward_large');
editable('reward_average');

% define time intervals (in ms):
wait_for_fix = 1000;
initial_fix = 1000; 
reveal_fix = 400;
interaction_time = 2000;
half_iti = 500;

% fixation window (in degrees):
FP_fix_radius = 2.5; 
target_fix_radius = 2.8;

% reward
reward_small = 20;
reward_large = 200;
reward_average = 110;

% eccentricity of mask/cue
eccentricity = 8;

% 6 positions starting from top going clockwise
positions = [0,1; sqrt(3)/2,1/2; sqrt(3)/2,-1/2;...
  0,-1; -sqrt(3)/2,-1/2; -sqrt(3)/2,1/2] * eccentricity;

% decide which low d cue to use in this trial
if rand>0.5
  lowdcue = lowdcue1;
else
  lowdcue = lowdcue2;
end


% TASK:


% if this is the first trial of a block, flash the screen to indicate block
% change
if TrialRecord.CurrentTrialWithinBlock==1
  idle(1000);
  toggleobject(BlockChangeFlash,'Status','on');
  idle(1000);
  toggleobject(BlockChangeFlash,'Status','off');
  idle(3000);
end

% figure out placement
highDpos = randi([1,6],1); % randomize position of high D cue out of 6 possibilities
lowdpos = mod(highDpos-1+3,6) + 1; % put the low d cue on the opposite side
% randomize whether cue is Position 1, 2, or 3 in the search array
cueInArray = randi([1,3],1);
% subtract that from [1,2,3] to make cue's position 0
% add currentCond to make the cue's position the one according to condition
highDPosArray = ([1,2,3] - cueInArray) + highDpos;
% mod by 8 (and 1-indexing)
highDPosArray = 1 + mod(highDPosArray - 1,6);
% get cue and fake mask positions and put them there
fakeMask1Pos = highDPosArray(1+mod(cueInArray,3));
fakeMask2Pos = highDPosArray(1+mod(cueInArray+1,3));
reposition_object(highDmaskArray(1),positions(highDpos,1),positions(highDpos,2));
reposition_object(highDcue,positions(highDpos,1),positions(highDpos,2));
reposition_object(highDmaskArray(2),positions(fakeMask1Pos,1),positions(fakeMask1Pos,2));
reposition_object(highDmaskArray(3),positions(fakeMask2Pos,1),positions(fakeMask2Pos,2));

lowdPosArray = ([1,2,3] - cueInArray) + lowdpos;
lowdPosArray = 1 + mod(lowdPosArray - 1,6);
fakeMask1Pos = lowdPosArray(1+mod(cueInArray,3));
fakeMask2Pos = lowdPosArray(1+mod(cueInArray+1,3));
reposition_object(lowdmaskArray(1),positions(lowdpos,1),positions(lowdpos,2));
reposition_object(lowdcue,positions(lowdpos,1),positions(lowdpos,2));
reposition_object(lowdmaskArray(2),positions(fakeMask1Pos,1),positions(fakeMask1Pos,2));
reposition_object(lowdmaskArray(3),positions(fakeMask2Pos,1),positions(fakeMask2Pos,2));
eventmarker([100+highDpos,110+lowdpos]);


masks = [highDmaskArray,lowdmaskArray];
cues = [highDcue,lowdcue];

[TimeTrialGateOn] = toggleobject(trialGate, 'eventmarker',1,'status','on');

% acquire fixation on FP within wait_for_fix
[TimeFixOn] = toggleobject(fixation_point,'eventmarker',3,'status','on');
ontarget = eyejoytrack('acquirefix', fixation_point, FP_fix_radius, wait_for_fix);
if ~ontarget 
  [TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',2,'status','off');
  toggleobject(fixation_point,'eventmarker',4,'status','off');
  trialerror(4); % no fixation
  return
end

% hold FP fixation for the duration of initial_fix 
ontarget = eyejoytrack('holdfix', fixation_point, FP_fix_radius, initial_fix);
if ~ontarget
  [TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',12,'status','off');
  toggleobject(fixation_point,'eventmarker',14,'status','off');
  trialerror(3); % broke fixation
  return
end

% turn off FP
toggleobject(fixation_point,'eventmarker',24,'status','off');
% turn on masks
[TimeMaskOn] = toggleobject(masks,'eventmarker',25,'status','on'); 


interaction_remainder = interaction_time;
interaction_end = trialtime + interaction_time;
chosenCue = 0; %0: unchosen, 1:highD, 2:lowd
chosenMasks = 1:6; %start from unchosen state
while true 
  acquireFixMask = eyejoytrack('acquirefix', masks(chosenMasks), target_fix_radius, interaction_remainder);
  if acquireFixMask==0
    % never initiate fixation during the entire interaction time, turn off masks and reward 
    toggleobject(masks,'eventmarker',35,'status','off');
    break;
  else % initiated fixation 
    ontarget = eyejoytrack('holdfix', masks(chosenMasks(acquireFixMask)), target_fix_radius, reveal_fix);
    if ~ontarget % but fixation is broken, 
      interaction_remainder = interaction_end - trialtime;
  	  if interaction_remainder > reveal_fix 
  	    continue; % as long as there's still time, keep trying 
  	  else
  	    % if there's not enough time, wait it out and jump to reward 
  	    idle(max(0,interaction_remainder));
  	    toggleobject(masks,'eventmarker',35,'status','off');
  	    break;
  	  end
    else % fixation is maintained for the duration of reveal_fix
	    if chosenCue == 0
	      if acquireFixMask<=3
		      chosenCue = 1; chosenMasks = [1,2,3]; unchosenMasks = [4,5,6];
        else
		      chosenCue = 2; chosenMasks = [4,5,6]; unchosenMasks = [1,2,3]; acquireFixMask = acquireFixMask - 3;
        end
		    eventmarker(35-chosenCue); % note down choice
      end
      toggleobject(masks([chosenMasks(acquireFixMask),unchosenMasks]),'eventmarker',35,'status','off');
	    if acquireFixMask==1
    	  toggleobject(cues(chosenCue),'eventmarker',35+chosenCue,'status','on'); % reveal 
      end
	    % use the line below to see if fixation is broken from now till end of interaction time 
	    ontarget = eyejoytrack('holdfix', masks(chosenMasks(acquireFixMask)), target_fix_radius, interaction_end - trialtime);
	    if ~ontarget
	    	% fixation was broken, reapply mask and if there's still time, do the loop again
		    toggleobject(cues(chosenCue), 'eventmarker',46,'status','off');
		    toggleobject(masks(chosenMasks(acquireFixMask)), 'eventmarker',45,'status','on');
		    interaction_remainder = interaction_end - trialtime;
        if interaction_remainder > reveal_fix
		      continue;
		    else % not enough time left, just wait it out 
		      idle(max(0,interaction_remainder));
	        toggleobject(masks,'eventmarker',35,'status','off');
		      break;
        end
	    else % fixation is maintained for the entire duration of interaction_remainder, reward 
		    toggleobject(cues,'eventmarker',46,'status','off');
			toggleobject(masks,'eventmarker',35,'status','off');
		    break;
	    end 
	  end
	end 
end
  








% reward
% condition number determines cue identity
% eventmarker determines reward size
if strcmp(TrialRecord.CurrentConditionInfo.RewardSize,'average')
  goodmonkey(reward_average, 'NumReward', 1);
  eventmarker(92);
elseif strcmp(TrialRecord.CurrentConditionInfo.RewardSize,'large')
  goodmonkey(reward_large, 'NumReward', 1);
  eventmarker(93);
else
  goodmonkey(reward_small, 'NumReward', 1);
  eventmarker(91);
end

idle(half_iti);
[TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',100,'status','off');
idle(half_iti);
trialerror(0);
return
