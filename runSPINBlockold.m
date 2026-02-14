function results = runSPINBlockold(subID, parameter, adaptive, group, keyGroup, window, wordList, continuousNoise, noisePlayer, wordPlayer)
   
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
    numTrials = wordList.numTrials;
    correctCount = 0;
    incorrectCount = 0;

    % Start Noise
    PsychPortAudio('Start', noisePlayer, 2, 0, 1);

    
    % Trial loop
    for i = 1:numTrials
        parameter.ISI = 2 + rand() * 8; % Random interstimulus interval (2-10seconds)
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
                fprintf('Early response detected: %s at %.3f sec\n', respInfo.keyName, respInfo.reactionTime);
                break; % exit ISI early if you want
            end
        end

        % Load word
        currentTrial = wordList.trialList{i};
        word = currentTrial.word;
        correct_ans = currentTrial.label;
        wordFilepath = currentTrial.filepath;
              
        format shortg; c = clock; trialStart = [c(4), c(5), c(6)]; format short;   % Record trial start

        [wordAudio, parameter.fs] = audioread(wordFilepath);

        % if strcmpi(group, 'R')
        %  gn_word = 0.004;
        % elseif strcmpi(group, 'D')
        %     if strcmpi(pitchFolder, 'LowPitch')
        %         gn_word = 0.004;   % same as R
        %     elseif strcmpi(pitchFolder, 'HighPitch')
        %         gn_word = 0.003;   % high pitch adjustment
        %     else
        %         error('Unknown pitch type: must be ''low'' or ''high''.');
        %     end
        % end

        wordAudio = wordAudio / max(abs(wordAudio) + eps);  % normalize to peak = 1
        wordRMS = rms(wordAudio);
        
        minFloor = 0.1;   % your chosen floor
        if wordRMS < minFloor
            scaleFactor = minFloor / wordRMS;
            wordAudio = wordAudio * scaleFactor;
            wordRMS = rms(wordAudio);  % <-- recompute after boost
        end

        % Compute target gain for this word
        noiseRMS = rms(continuousNoise);
        targetGain = (noiseRMS * 10^(adaptive.snrCurrent/20)) / wordRMS;
        
        % Apply global calibration gain (set from SPL meter check)
        %calibrationGain = 0.7;   % adjust until typical words read ~64 dB SPL
        scaledWord = wordAudio * targetGain;
        % Safety limiter
        peakVal = max(abs(scaledWord));
        if peakVal > 0.99
            scaledWord = scaledWord * (0.99 / peakVal);
        end

        % Play word audio      
        PsychPortAudio('FillBuffer', wordPlayer, scaledWord');
        PsychPortAudio('Start', wordPlayer, 1, 0, 0);
        PsychPortAudio('Stop', wordPlayer, 1);
        
        % Initilize the Response Information
        [respInfo] = Spin_initializeResponse(correct_ans);  % initialize 

        timeOut = parameter.ITI;

        % Collect response
        [respInfo] = spin_CollectResponse(respInfo, correct_ans, timeOut, wordPlayer, noisePlayer);

       
        % Record trial end
        format shortg; c = clock; trialEnd = [c(4), c(5), c(6)]; format short;
        
        % Store data
        results(i).subjectID              = subID;
        results(i).testType               = adaptive.test;
        results(i).group                  = group;
        %results(i).wordList.trialList     = wordList.trialList;
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
        
        % Print to console
        fprintf('Test Type: %s | Group: %s  | Trial %2d | Word: %s| Participant Response: %s | Answer: %s | SNR: %4.1f dB | %s | RT: %.3f sec\n', ...
        adaptive.test, group, i, word, respInfo.keyName, respInfo.correctKeyName, adaptive.snrCurrent, respInfo.feedback, respInfo.reactionTime);
        
        if strcmp(respInfo.feedback, 'Correct')
            correctCount = correctCount +1;
        else
            incorrectCount = incorrectCount +1;
        end
        
    end
    
    if strcmp(adaptive.test, 'practice')
         PsychPortAudio('Stop', noisePlayer);
         PsychPortAudio('Stop', wordPlayer);
    end 

     % Store summary stats
     results(1).summary.subjectID = subID;
     results(1).summary.correctCount = correctCount;
     results(1).summary.incorrectCount = incorrectCount; 
     results(1).summary.totalTrials = numTrials;
     results(1).summary.percentCorrect = (correctCount / numTrials) * 100; 
     results(1).summary.snr = currentSNR;    
     results(1).summary.rt = mean(respInfo.reactionTime);
     
end
