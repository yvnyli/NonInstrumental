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

% define time intervals (in ms):
wait_for_fix = 1000;
initial_fix = 1000;
reveal_fix = 100;
interaction_time = 2000;
half_iti = 1000;

% fixation window (in degrees):
fix_radius = 2.0755; % = 50 pixels calculated from the cfg.mat

% reward
reward_small = 20;
reward_large = 200;
reward_average = 110;


% TASK:
[TimeTrialGateOn] = toggleobject(trialGate, 'eventmarker',1,'status','on');

% initial fixation:
[TimeFixOn] = toggleobject(fixation_point,'eventmarker',3,'status','on');
ontarget = eyejoytrack('acquirefix', fixation_point, fix_radius, wait_for_fix);
if ~ontarget 
  [TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',2,'status','off');
  toggleobject(fixation_point,'eventmarker',4,'status','off');
  trialerror(4); % no fixation
  return
end

% hold FP fixation
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


% interact with mask/cue
ontarget = eyejoytrack('acquirefix', mask, fix_radius, interaction_time);
if ~ontarget
  % no reveal, jump to reward
  toggleobject(mask,'eventmarker',35,'status','off');
else
  % reveal
  % mask off, cue on
  [TimeMaskOff] = toggleobject(mask,'eventmarker',35,'status','off');
  [TimeCueOn] = toggleobject(cue,'eventmarker',36,'status','on');
  idle(max(0,interaction_time - (trialtime - TimeMaskOn))); % elapse the rest of interaction time
end



% turn off mask/cue
toggleobject(mask,'eventmarker',45,'status','off');
toggleobject(cue,'eventmarker',46,'status','off');



% reward
if strcmp(TrialRecord.CurrentConditionInfo.RewardSize,'small')
  goodmonkey(reward_small, 'NumReward', 1);
  eventmarker(91);
elseif strcmp(TrialRecord.CurrentConditionInfo.RewardSize,'average')
  goodmonkey(reward_average, 'NumReward', 1);
  eventmarker(92);
else
  goodmonkey(reward_large, 'NumReward', 1);
  eventmarker(93);
end

idle(half_iti);
[TimeTrialGateOff] = toggleobject(trialGate,'eventmarker',100,'status','off');
idle(half_iti);
trialerror(0);
return
