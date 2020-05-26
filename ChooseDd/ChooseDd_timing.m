%Delayed Match-to-Sample (DMS) timing script

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
highDmask = 4;
BlockChangeFlash = 5;
lowdcue1 = 6;
lowdcue2 = 7;
lowdmask = 8;

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

% 8 positions starting from right going counterclockwise
positions = [1,0; 1/sqrt(2),1/sqrt(2); 0,1; -1/sqrt(2),1/sqrt(2);...
  -1,0; -1/sqrt(2),-1/sqrt(2); 0,-1; 1/sqrt(2),-1/sqrt(2)] * eccentricity;

% decide which low d cue to use in this trial
if rand>0.5
  lowdcue = lowdcue1;
else
  lowdcue = lowdcue2;
end
% figure out placement
highDpos = randi([1,8],1);
lowdpos = mod(highDpos-1+4,8) + 1;
reposition_object(highDmask,positions(highDpos,1),positions(highDpos,2));
reposition_object(highDcue,positions(highDpos,1),positions(highDpos,2));
reposition_object(lowdmask,positions(lowdpos,1),positions(lowdpos,2));
reposition_object(lowdcue,positions(lowdpos,1),positions(lowdpos,2));
eventmarker([100+highDpos,110+lowdpos]);

masks = [highDmask,lowdmask];
cues = [highDcue,lowdcue];

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
chosenMask = 0;
while true 
  if chosenMask == 0
    acquireFixMask = eyejoytrack('acquirefix', masks, target_fix_radius, interaction_remainder);
  else
    acquireFixMask = eyejoytrack('acquirefix', masks(chosenMask), target_fix_radius, interaction_remainder);
  end
  if acquireFixMask==0
    % never initiate fixation during the entire interaction time, turn off masks and reward 
    toggleobject(masks,'eventmarker',35,'status','off');
    break;
  else % initiated fixation 
    if chosenMask == 0
      ontarget = eyejoytrack('holdfix', masks(acquireFixMask), target_fix_radius, reveal_fix);
	else
      ontarget = eyejoytrack('holdfix', masks(chosenMask), target_fix_radius, reveal_fix);
	end
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
	  if chosenMask == 0
	    chosenMask = acquireFixMask;
	  end
      toggleobject(masks,'eventmarker',35,'status','off');
  	  toggleobject(cues(chosenMask),'eventmarker',35+chosenMask,'status','on'); % reveal 
		  % use the line below to see if fixation is broken from now till end of interaction time 
		  ontarget = eyejoytrack('holdfix', cues(chosenMask), target_fix_radius, interaction_end - trialtime);
		  if ~ontarget
		    % fixation was broken, reapply mask and if there's still time, do the loop again
		    toggleobject(cues(chosenMask), 'eventmarker',46,'status','off');
		    toggleobject(masks(chosenMask), 'eventmarker',45,'status','on');
		    interaction_remainder = interaction_end - trialtime;
		    if interaction_remainder > reveal_fix
		      continue;
		    else % not enough time left, just wait it out 
		      idle(max(0,interaction_remainder));
			    toggleobject(masks(chosenMask),'eventmarker',35,'status','off');
			    break;
        end
		  else % fixation is maintained for the entire duration of interaction_remainder, reward 
		    toggleobject(cues(chosenMask),'eventmarker',46,'status','off');
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
