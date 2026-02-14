function results = runSPINBlock(subID, parameter, adaptive, group, keyGroup, window, wordList, continuousNoise, noisePlayer, wordPlayer)
   
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
    numTrials = wordList.numTrials; % Fixed at 100 trials
    avgAudioLen = 0.5;    % Estimated word length

    if numTrials >= 50  
        experimentDuration = 720; % 12 minutes in seconds
        fixedTimeTotal = numTrials * (parameter.ITI + avgAudioLen);
        totalISITime = experimentDuration - fixedTimeTotal;
        rawISIs = 2 + (10-2) * rand(1, numTrials); 
        isiList = rawISIs * (totalISITime / sum(rawISIs)); 
        isiList(isiList > 10) = 10;
        isiList = isiList(randperm(numTrials));
    else 
        minISI = 2;
        maxISI =10;
        isiList = minISI + (maxISI - minISI) * rand(1, numTrials);
    end 
  

    % Calculate total time dedicated to "non-ISI" activities
    % fixedTimeTotal = numTrials * (parameter.ITI + avgAudioLen);
    % totalISITime = experimentDuration - fixedTimeTotal;

    % Generate 100 random ISI values between 2 and 10 that sum to totalISITime
    % We use a simple normalization trick:
    % rawISIs = 2 + (10-2) * rand(1, numTrials); 
    % isiList = rawISIs * (totalISITime / sum(rawISIs)); 
    % isiList(isiList > 10) = 10;
    % isiList = isiList(randperm(numTrials));  % Shuffle them so they are truly random

    % minISI = 2;
    % maxISI =10;
    % isiList = minISI + (maxISI - minISI) * rand(1, numTrials);
    % 
    % Start Noise
    PsychPortAudio('Start', noisePlayer, 2, 0, 1);
    taskStartTime = GetSecs; % Start global clock

    correctCount = 0;
    incorrectCount = 0;
    
    % Trial loop
    for i = 1:numTrials
        
        % Use pre-calcuated ISI 
        currentISI = isiList(i); 
        
        % Safety check: Stop if next ISI exceeds 12-minute limit
        
        % if (GetSecs - taskStartTime + currentISI) > experimentDuration
        %     fprintf('Time limit reached at trial %d. Ending task.\n', i-1);
        %     break; 
        % end

        fprintf('Trial %d — ISI: %.2f seconds\n', i, currentISI);
        %WaitSecs(currentISI);

        % Early response check during ISI
        startTime = GetSecs;
        respInfo.earlyResponse = false;
        while (GetSecs - startTime) < currentISI
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                respInfo.earlyResponse = true;
                respInfo.keyName = KbName(find(keyCode,1));
                respInfo.reactionTime = secs - startTime; 
            end
            WaitSecs(0.005); 
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

        [respInfo] = spin_CollectResponse(respInfo, correct_ans, parameter, wordPlayer, noisePlayer);
       
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
         fprintf('Test Type: %s | Group: %s  | Trial %2d | Word: %s| Participant Response: %s | Answer: %s | SNR: %4.1f dB | %s | RT: %.3f sec\n', ...
        adaptive.test, group, i, word, respInfo.keyName, respInfo.correctKeyName, adaptive.snrCurrent, respInfo.feedback, respInfo.reactionTime);

        % if i == 100
        % fprintf('100 trials completed. Ending task now.\n');
        % break; % This exits the loop as soon as the 100th trial is logged
        % end
       

    end
    actualDuration = GetSecs - taskStartTime;
    fprintf('Actual duration: %.1f minutes\n', actualDuration / 60);
    PsychPortAudio('Stop', noisePlayer);

    % Store summary stats
    results(1).summary.subjectID = subID;
    results(1).summary.correctCount = correctCount;
    results(1).summary.incorrectCount = incorrectCount; 
    results(1).summary.totalTrials = i;
    results(1).summary.percentCorrect = (correctCount / i) * 100;

    % Partial save 
    % if ~isempty(results)
    % saveName = sprintf('SPIN_partialresults_subject_%s_%s.mat', subID);
    % save(saveName, 'results');
    % fprintf('Data saved to %s\n', saveName);
    % else
    %     fprintf ('No trials were completed; nothing to save.\n');
    % end 
end
