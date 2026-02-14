function results = runSPINBlock2(subID, parameter, adaptive, group, keyGroup, window, wordList, continuousNoise, noisePlayer, wordPlayer)
   
    % Colors   
    white = WhiteIndex(window);
    black = BlackIndex(window);
    
    % Adaptive parameters
    if strcmpi(adaptive.test,'practice')
        adaptive.snrCurrent = adaptive.workloadSNR;
    elseif strcmpi(adaptive.test,'main')
        adaptive.snrCurrent = adaptive.mainSNR;
    else
        error('Could not define test type');
    end
    currentSNR = adaptive.snrCurrent;
    
    % On-screen instruction
    Instruction = getDrawMainText(group, keyGroup);
    
    % Display instruction
    Screen('FillRect', window, black);
    DrawFormattedText(window, Instruction, 'center', 'center', white);
    Screen('Flip', window);

    % Initialize
    results = struct([]);
    numTrials = 100; % Fixed at 100 trials
    experimentDuration = 720; % 12 minutes in seconds
    
    % Start Noise
    PsychPortAudio('Start', noisePlayer, 2, 0, 1);
    taskStartTime = GetSecs; % Start global clock

    correctCount = 0;
    incorrectCount = 0;
    
    % Trial loop
    for i = 1:numTrials
        
        % ISI adjusted to fit 100 trials in 12 mins (Average ISI ~4.2s)
        parameter.ISI = 2 + rand() * 4.4; 
        
        % Safety check: Stop if next ISI exceeds 12-minute limit
        if (GetSecs - taskStartTime + parameter.ISI) > experimentDuration
            fprintf('Time limit reached at trial %d. Ending task.\n', i-1);
            break; 
        end

        fprintf('Trial %d — ISI: %.2f seconds\n', i, parameter.ISI);
        WaitSecs(parameter.ISI);

        % Early response check during ISI
        startTime = GetSecs;
        respInfo.earlyResponse = false;
        while (GetSecs - startTime) < parameter.ISI
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                respInfo.earlyResponse = true;
                respInfo.keyName = KbName(find(keyCode,1));
                respInfo.reactionTime = secs - startTime;
                break; 
            end
        end

        % Load word (Using mod to loop list if it has fewer than 100 words)
        listIdx = mod(i-1, wordList.numTrials) + 1;
        currentTrial = wordList.trialList{listIdx};
        word = currentTrial.word;
        correct_ans = currentTrial.label;
        wordFilepath = currentTrial.filepath;
              
        format shortg; c = clock; trialStart = [c(4), c(5), c(6)]; format short; 

        [wordAudio, parameter.fs] = audioread(wordFilepath);

        % Audio processing
        wordAudio = wordAudio / max(abs(wordAudio) + eps);  
        wordRMS = rms(wordAudio);
        
        minFloor = 0.1;   
        if wordRMS < minFloor
            scaleFactor = minFloor / wordRMS;
            wordAudio = wordAudio * scaleFactor;
        end

        noiseRMS = rms(continuousNoise);
        targetGain = (noiseRMS * 10^(adaptive.snrCurrent/20)) / rms(wordAudio);
        scaledWord = wordAudio * targetGain;
        
        % Safety limiter
        if max(abs(scaledWord)) > 0.99
            scaledWord = scaledWord * (0.99 / max(abs(scaledWord)));
        end

        % Play word audio      
        PsychPortAudio('FillBuffer', wordPlayer, scaledWord');
        PsychPortAudio('Start', wordPlayer, 1, 0, 0);
        PsychPortAudio('Stop', wordPlayer, 1);
        
        % Initialize Response
        [respInfo] = Spin_initializeResponse(correct_ans);  

        % Collect response (Ensuring timeout doesn't exceed experiment end)
        timeLeft = experimentDuration - (GetSecs - taskStartTime);
        timeOut = min(parameter.ITI, timeLeft); 

        [respInfo] = spin_CollectResponse(respInfo, correct_ans, timeOut, wordPlayer, noisePlayer);
       
        % Record trial end
        format shortg; c = clock; trialEnd = [c(4), c(5), c(6)]; format short; 
        
        % Store data (Your Original Structure)
        results(i).subjectID              = subID;
        results(i).testType               = adaptive.test;
        results(i).group                  = group;
        results(i).trial                  = i;
        results(i).word                   = word;
        results(i).snr                    = currentSNR;
        results(i).responsekeyName        = respInfo.keyName;
        results(i).correctKeyName         = respInfo.correctKeyName;
        results(i).correctanswer          = correct_ans;
        results(i).feedback               = respInfo.feedback;
        results(i).reactionTime           = respInfo.reactionTime;
        results(i).trialStart             = trialStart;
        results(i).trialEnd               = trialEnd;
        
        if strcmp(respInfo.feedback, 'Correct')
            correctCount = correctCount + 1;
        else
            incorrectCount = incorrectCount + 1;
        end
        
        % Print status
        fprintf('Time: %.1fs | Trial %d | Word: %s | RT: %.3f | %s\n', ...
            GetSecs - taskStartTime, i, word, respInfo.reactionTime, respInfo.feedback);
    end
    
    PsychPortAudio('Stop', noisePlayer);

    % Store summary stats
    results(1).summary.subjectID = subID;
    results(1).summary.correctCount = correctCount;
    results(1).summary.incorrectCount = incorrectCount; 
    results(1).summary.totalTrials = i;
    results(1).summary.percentCorrect = (correctCount / i) * 100; 
end
