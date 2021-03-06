% Non-instrumental portion timing script

% This task requires that either an "eye" input or joystick (attached to the
% eye input channels) is available to perform the necessary responses.
%
% During a real experiment, a task such as this should make use of the
% "eventmarker" command to keep track of key actions and state changes (for
% instance, displaying or extinguishing an object, initiating a movement, etc).

% DEFINE TASKOBJECTS
fixation_point = 1;
trialGate = 2;
cue = 3;
mask = 4;
fakeMask1 = 5;
fakeMask2 = 6;
maskArray = [4,5,6];
BlockChangeFlash = 7;

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
editable('eccentricity');

% define time intervals (in ms):
wait_for_fix = 1000;
initial_fix = 1000; 
reveal_fix = 400;
interaction_time = 2000;
half_iti = 500;

% fixation window (in degrees):
FP_fix_radius = 2.5;
target_fix_radius = 2.8; % = 67 pixels, cue is 80 by 80, and the largest mask (triangle) is 113.1 by 113.1

% reward
reward_small = 20;
reward_large = 200;
reward_average = 110;

% eccentricity of mask/cue
eccentricity = 8;

% 8 positions starting from right going counterclockwise
positions = [1,0; 1/sqrt(2),1/sqrt(2); 0,1; -1/sqrt(2),1/sqrt(2);...
  -1,0; -1/sqrt(2),-1/sqrt(2); 0,-1; 1/sqrt(2),-1/sqrt(2)] * eccentricity;




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


% get the condition number of current trial
currentCond = TrialRecord.CurrentCondition;
% randomize whether cue is Position 1, 2, or 3 in the search array
cueInArray = randi([1,3],1);
% subtract that from [1,2,3] to make cue's position 0
% multiply by 2 to make spacing 90 degrees (every other position)
% add currentCond to make the cue's position the one according to condition
currentPos = ([1,2,3] - cueInArray) * 2 + currentCond;
% mod by 8 (and 1-indexing)
currentPos = 1 + mod(currentPos - 1,8);
% get cue and fake mask positions and put them there
cuePos = currentPos(cueInArray);
fakeMask1Pos = currentPos(1+mod(cueInArray,3));
fakeMask2Pos = currentPos(1+mod(cueInArray+1,3));
reposition_object(cue,positions(cuePos,1),positions(cuePos,2));
reposition_object(mask,positions(cuePos,1),positions(cuePos,2));
reposition_object(fakeMask1,positions(fakeMask1Pos,1),positions(fakeMask1Pos,2));
reposition_object(fakeMask2,positions(fakeMask2Pos,1),positions(fakeMask2Pos,2));

% these don't need to be time stamped, just a way of saving data
eventmarker([100+cuePos, 110+fakeMask1Pos, 120+fakeMask2Pos]);


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
% turn on mask and fake masks
[TimeMaskOn] = toggleobject(maskArray,'eventmarker',25,'status','on'); 


interaction_remainder = interaction_time;
interaction_end = trialtime + interaction_time;
while true 
  acquireFixMask = eyejoytrack('acquirefix', maskArray,...
    target_fix_radius, interaction_remainder);
	if acquireFixMask==0
	  % never initiate fixation during the entire interaction time, turn off mask and reward 
	  toggleobject(maskArray,'eventmarker',30,'status','off');
	  break;
	else % initiated fixation 
	  ontarget = eyejoytrack('holdfix', maskArray(acquireFixMask), target_fix_radius, reveal_fix);
	  if ~ontarget % but fixation is broken, 
	    interaction_remainder = interaction_end - trialtime;
      if interaction_remainder > reveal_fix 
        continue; % as long as there's still time, keep trying 
      else
        % if there's not enough time, wait it out and jump to reward 
        idle(max(0,interaction_remainder));
        toggleobject(maskArray,'eventmarker',30,'status','off');
        break;
      end
    else % fixation is maintained for the duration of reveal_fix
      toggleobject(maskArray(acquireFixMask),'eventmarker',30+acquireFixMask,'status','off');
      if acquireFixMask==1 % if the revealed mask is the true one, reveal
        toggleobject(cue,'eventmarker',36,'status','on');  
      else % if the revealed mask is a fake one, log an event
        eventmarker(35);
      end
      % use the line below to see if fixation is broken from now till end of interaction time 
      ontarget = eyejoytrack('holdfix', maskArray(acquireFixMask),...
        target_fix_radius, interaction_end - trialtime);
      if ~ontarget
        % fixation was broken, reapply mask and if there's still time, do the loop again
        if acquireFixMask==1 % if the cue was on, turn it off
          toggleobject(cue, 'eventmarker',46,'status','off');
        else % log an event
          eventmarker(45);
        end
        toggleobject(maskArray(acquireFixMask), 'eventmarker',47,'status','on');
        interaction_remainder = interaction_end - trialtime;
        if interaction_remainder > reveal_fix
          continue;
        else % not enough time left, just wait it out 
          idle(max(0,interaction_remainder));
          toggleobject(maskArray,'eventmarker',30,'status','off');
          break;
        end
      else % fixation is maintained for the entire duration of interaction_remainder, reward 
        if acquireFixMask==1 % if the cue was on, turn it off
          toggleobject(cue,'eventmarker',46,'status','off');
        else % log the end of mask viewing
          eventmarker(45);
        end
        toggleobject(maskArray,'eventmarker',30,'status','off');
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
