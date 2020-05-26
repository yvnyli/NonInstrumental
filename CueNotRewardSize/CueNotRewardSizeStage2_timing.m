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
mask = 4;
cue = 3;
BlockChangeFlash = 5;

% DEFINE EDITABLE VARIABLES
editable('wait_for_fix');
editable('initial_fix');
editable('reveal_fix');
editable('interaction_time');
editable('half_iti');
editable('fix_radius');
editable('reward_small');
editable('reward_large');
editable('reward_average');
editable('remask');

% define time intervals (in ms):
wait_for_fix = 1000;
initial_fix = 1000; 
reveal_fix = 400;
interaction_time = 2000;
half_iti = 500;

% fixation window (in degrees):
fix_radius = 2.5; % = 60 pixels calculated from the cfg.mat, and cue is 80 by 80, so there's more of a border

% reward
reward_small = 20;
reward_large = 200;
reward_average = 110;

% remask: 0 for no remasking, 1 for remasking
remask = 1;


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
ontarget = eyejoytrack('acquirefix', fixation_point, fix_radius, wait_for_fix);
if ~ontarget 
  [TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',2,'status','off');
  toggleobject(fixation_point,'eventmarker',4,'status','off');
  trialerror(4); % no fixation
  return
end

% hold FP fixation for the duration of initial_fix 
ontarget = eyejoytrack('holdfix', fixation_point, fix_radius, initial_fix);
if ~ontarget
  [TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',12,'status','off');
  toggleobject(fixation_point,'eventmarker',14,'status','off');
  trialerror(3); % broke fixation
  return
end

% turn off FP
toggleobject(fixation_point,'eventmarker',24,'status','off');
% turn on mask
[TimeMaskOn] = toggleobject(mask,'eventmarker',25,'status','on'); 

if ~remask % this is the version where a revealed cue stays revealed

  % interact with mask/cue for the duration of interaction_time
  % 1 if fixation on mask is never initiated, just turn off mask and jump to reward 
  %   if fixation on mask is initiated, 
  % 2    then broken, keep trying (thus loop) for the remainder of interaction_time
  % 3    then maintained for the duration of reveal_fix, reveal and elapse remainder 
  interaction_remainder = interaction_time;
  interaction_end = trialtime + interaction_time;
  while true % taken care of inside of the loop 
    ontarget = eyejoytrack('acquirefix', mask, fix_radius, interaction_remainder);
    if ~ontarget
      % 1
      toggleobject(mask,'eventmarker',35,'status','off');
	  break;
    else
      ontarget = eyejoytrack('holdfix', mask, fix_radius, reveal_fix)
      if ~ontarget
	    % 2
        interaction_remainder = interaction_end - trialtime;
	    if interaction_remainder > reveal_fix % as long as there is still time to reveal, keep looping
	      continue;
	    else % otherwise just wait it out and turn off the mask and jump to reward 
	      idle(max(0,interaction_remainder));
		  toggleobject(mask,'eventmarker',35,'status','off');
		  break;
	    end 
	  else
	    % 3
	    % reveal: mask off, cue on
	    toggleobject(mask,'eventmarker',35,'status','off');
	    toggleobject(cue,'eventmarker',36,'status','on');
	    idle(max(0,interaction_end - trialtime)); % elapse the rest of interaction time
	    % cue off, go to reward
	    toggleobject(cue,'eventmarker',46,'status','off');
	    break;
	  end
    end
  end 
  
  
else % remask=1: in this version, mask is back on when he looks away

  interaction_remainder = interaction_time;
  interaction_end = trialtime + interaction_time;
  while true 
    ontarget = eyejoytrack('acquirefix', mask, fix_radius, interaction_remainder);
	if ~ontarget
	  % never initiate fixation during the entire interaction time, turn off mask and reward 
	  toggleobject(mask,'eventmarker',35,'status','off');
	  break;
	else % initiated fixation 
	  ontarget = eyejoytrack('holdfix', mask, fix_radius, reveal_fix)
	  if ~ontarget % but fixation is broken, 
	    interaction_remainder = interaction_end - trialtime;
		if interaction_remainder > reveal_fix 
		  continue; % as long as there's still time, keep trying 
		else
		  % if there's not enough time, wait it out and jump to reward 
		  idle(max(0,interaction_remainder));
		  toggleobject(mask,'eventmarker',35,'status','off');
		  break;
		end
      else % fixation is maintained for the duration of reveal_fix
	    toggleobject(mask,'eventmarker',35,'status','off');
		toggleobject(cue,'eventmarker',36,'status','on'); % reveal 
		% use the line below to see if fixation is broken from now till end of interaction time 
		ontarget = eyejoytrack('holdfix', cue, fix_radius, interaction_end - trialtime)
		if ~ontarget
		  % fixation was broken, reapply mask and if there's still time, do the loop again
		  toggleobject(cue, 'eventmarker',46,'status','off');
		  toggleobject(mask, 'eventmarker',45,'status','on');
		  interaction_remainder = interaction_end - trialtime;
		  if interaction_remainder > reveal_fix
		    continue;
		  else % not enough time left, just wait it out 
		    idle(max(0,interaction_remainder));
			toggleobject(mask,'eventmarker',55,'status','off');
			break;
		  end
		else % fixation is maintained for the entire duration of interaction_remainder, reward 
		  toggleobject(cue,'eventmarker',46,'status','off');
		  break;
		end 
	  end
	end 
  end
  
  
end  % stay revealed or remask 







% reward
% condition number determines cue identity
% eventmarker determines reward size
if strcmp(TrialRecord.CurrentConditionInfo.RewardSize,'average')
  goodmonkey(reward_average, 'NumReward', 1);
  eventmarker(92);
else
  if rand>0.5
    goodmonkey(reward_large, 'NumReward', 1);
    eventmarker(93);
  else
    goodmonkey(reward_small, 'NumReward', 1);
    eventmarker(91);
  end
end

idle(half_iti);
[TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',100,'status','off');
idle(half_iti);
trialerror(0);
return
