function [respInfo] = spin_CollectResponse(respInfo, correctKey, parameter, wordPlayer, noisePlayer)
   
    % Define correct and wrong keys
    respInfo.correctKey = correctKey;
    if correctKey == 1
        respInfo.correctKeyName = 'z';
        wrongKey = 'm';
    elseif correctKey == 2
        respInfo.correctKeyName = 'm';
        wrongKey = 'z';
    end

    % Initialize
    keyIsDown = 0;
    startTime = GetSecs;
    respInfo.reactionTime = [];
    respInfo.keyName = '';
    respInfo.feedback = 'NoResponse';
    

    % Response loop
    while ~keyIsDown && (GetSecs - startTime < parameter.ITI)

        [keyIsDown, secs, keyCode] = KbCheck;

        if keyIsDown
            pressedKey = find(keyCode,1);
            respInfo.keyCode = pressedKey;
            respInfo.keyName = KbName(pressedKey);
            respInfo.reactionTime = secs - startTime;

            % ==== ESCAPE handling ====
            if strcmpi(respInfo.keyName,'ESCAPE')
                sca; % Close all screens
                PsychPortAudio('Close');
                return;
            end

            % ==== Pause handling ====
            if strcmpi(respInfo.keyName,'p')
                PsychPortAudio('Stop', noisePlayer);
                PsychPortAudio('Stop', wordPlayer);
                disp('Experiment Paused. Press any key to continue');
                KbStrokeWait;   % wait until subject presses a key
                disp('Resuming Experiment');
                pause(1);
                KbReleaseWait;
                while true
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown && keyCode(KbName('space'))
                        break; % resume
                    elseif keyIsDown && keyCode(escKey)
                        Screen('CloseAll');
                        error('User pressed ESC. Task terminated.');
                    end
                end
                % After resume, reset loop
                keyIsDown = 0;
                continue;
            end

            % ==== Correct/Incorrect handling ====
             % Key pressed but too late 
            if respInfo.reactionTime > 2
                respInfo.feedback = 'Overrun'; 
                return; 
            elseif strcmpi(respInfo.keyName, respInfo.correctKeyName)
                respInfo.feedback = 'Correct';
            elseif strcmpi(respInfo.keyName, wrongKey)
                respInfo.feedback = 'Incorrect';
            else
                respInfo.feedback = 'Incorrect';
            end
              break;
        end     
     end
   
    %If no key pressed within timeout
    if isempty(respInfo.reactionTime)
        respInfo.feedback = 'NoResponse';
        respInfo.reactionTime =NaN;
    end
end

