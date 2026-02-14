function parameter = WordLists(mainDir, test, group, keyGroup)
    % Creates randomized word lists for practice or main blocks
    % test: 'practice' or 'main'
    % group: 'R' (Recognition) or 'D' (Detection)

    fprintf("WordLists Function start: group = '[%s]', keyGroup = %d\n", group, keyGroup);
    %% Load word lists
    load([mainDir, 'Functions\spin functions\WordLists.mat'], 'Lists');
    %load(wordListsPath, 'Lists')
    %load([mainDir, '\Functions\spin functions\WordLists.mat'], 'Lists');
    
    %% Create word list structure based on block type
    if strcmpi(test, 'practice')
        % Practice Block - single list      
        % Get living and non-living words
        livingWords = Lists.PracticeWords.Living;      
        nonLivingWords = Lists.PracticeWords.NonLiving; 
        
        if strcmpi(group, 'R')     % Recognition: Living vs NonLiving judgment
            numLiving = length(livingWords);
            numNonLiving = length(nonLivingWords);
            totalWords = numLiving + numNonLiving;
            
            % Combine with labels (1=living, 2=non-living)
            allWords = [livingWords, nonLivingWords];
            if keyGroup == 1
                allLabels = [ones(1, numLiving), 2*ones(1, numNonLiving)];
            elseif keyGroup == 2
                allLabels = [2*ones(1, numLiving), ones(1, numNonLiving)];
            end
            
            % Word folder
            parameter.wordFolder = fullfile(mainDir, 'Stimuli', 'Word Lists', 'Practice List', 'Recognition');
            
        elseif strcmpi(group, 'D')   % Dtection: High vs Low pitch judgment
           
            % Use all words (both living and non-living) and assign balanced pitch
            allWords = [livingWords, nonLivingWords];
            totalWords = length(allWords);
            
            % Create balanced high/low pitch labels
            numHigh = floor(totalWords / 2);
            numLow = totalWords - numHigh;
            if keyGroup == 1
                allLabels = [ones(1, numLow), 2*ones(1, numHigh)];
            elseif keyGroup == 2
                allLabels = [ones(1, numHigh), 2*ones(1, numLow)];
            end
            
            % Randomize the order of labels
            shuffleIdx = randperm(totalWords);
            allLabels = allLabels(shuffleIdx);
            
            % Base folder for Detection
            parameter.wordFolderBase = fullfile(mainDir, 'Stimuli', 'Word Lists', 'Practice List', 'Detection');
        end
        
        % Randomize order
        parameter.numTrials = totalWords;
        parameter.randOrder = randperm(totalWords);

        allLabels = allLabels(parameter.randOrder);
        allWords = allWords(parameter.randOrder);
        
        % Create trial list in randomized order
        parameter.trialList = cell(totalWords, 1);
        for i = 1:totalWords
            idx = parameter.randOrder(i);
            parameter.trialList{i}.word = allWords{idx};
            parameter.trialList{i}.label = allLabels(idx);
            
            % Set folder and filename based on group
            if strcmpi(group, 'R')        
                parameter.trialList{i}.filename = [allWords{idx} '.wav'];
                parameter.trialList{i}.filepath = fullfile(parameter.wordFolder, parameter.trialList{i}.filename);
            elseif strcmpi(group, 'D')
                % Choose HighPitch or LowPitch folder based on label
               if keyGroup == 1
                   if  parameter.trialList{i}.label == 1
                        pitchFolder = 'LowPitch';
                   elseif parameter.trialList{i}.label == 2
                        pitchFolder = 'HighPitch';
                   else
                       error('Could not determine Pitch')
                   end

                elseif keyGroup == 2
                   if  parameter.trialList{i}.label == 1
                        pitchFolder = 'HighPitch';
                   elseif parameter.trialList{i}.label == 2
                        pitchFolder = 'LowPitch';
                   else
                       error('Could not determine Pitch')
                   end
                else
                    error('Invalid keyGroup. Must be 1 or 2.');
                end

                parameter.trialList{i}.filename = [allWords{idx} '.wav'];
                parameter.trialList{i}.filepath = fullfile(parameter.wordFolderBase, pitchFolder, parameter.trialList{i}.filename);
            end
        end
        
    elseif strcmpi(test, 'main')
            % Get words from main list
    livingWords = Lists.MainWords.Living;
    nonLivingWords = Lists.MainWords.NonLiving;
    
    if strcmpi(group, 'R')   % Recognition: Living vs NonLiving judgment          
        numLiving = length(livingWords);
        numNonLiving = length(nonLivingWords);
        totalWords = numLiving + numNonLiving;
        
        % Combine with labels
        allWords = [livingWords, nonLivingWords];
        if keyGroup == 1
            allLabels = [ones(1, numLiving), 2*ones(1, numNonLiving)];
        elseif keyGroup == 2
            allLabels = [2*ones(1, numLiving), ones(1, numNonLiving)];
        end              
        
        % Word folder
        parameter.wordFolder = fullfile(mainDir, 'Stimuli', 'Word Lists', 'Main Block', 'Recognition');
        
    elseif strcmpi(group, 'D')   % Detection: High vs Low pitch judgment
        
        allWords = [livingWords, nonLivingWords];
        totalWords = length(allWords);

        % Create balanced high/low pitch labels
        numHigh = floor(totalWords / 2);
        numLow = totalWords - numHigh;
        if keyGroup == 1
            allLabels = [ones(1, numLow), 2*ones(1, numHigh)];
        elseif keyGroup == 2
            allLabels = [ones(1, numHigh), 2*ones(1, numLow)];
        end
        
        % Randomize the order of labels
        shuffleIdx = randperm(totalWords);
        allLabels = allLabels(shuffleIdx);
        
        % Base folder
        parameter.wordFolderBase = fullfile(mainDir, 'Stimuli', 'Word Lists', 'Main Block', 'Detection');
    end
    
    % Randomize order
    parameter.numTrials = totalWords;
    parameter.randOrder = randperm(totalWords);
    
    allLabels = allLabels(parameter.randOrder);
    allWords = allWords(parameter.randOrder);
    
    % Create trial list
    parameter.trialList = cell(totalWords, 1);
    for i = 1:totalWords
        idx = parameter.randOrder(i);
        parameter.trialList{i}.word = allWords{idx};
        parameter.trialList{i}.label = allLabels(idx);
        
        % Set filepath based on group
        if strcmpi(group, 'R')
            parameter.trialList{i}.filename = [allWords{idx} '.wav'];
            parameter.trialList{i}.filepath = fullfile(parameter.wordFolder, parameter.trialList{i}.filename);
        elseif strcmpi(group, 'D')
            if keyGroup == 1
               if parameter.trialList{i}.label == 1
                    pitchFolder = 'LowPitch';
               elseif parameter.trialList{i}.label == 2
                    pitchFolder = 'HighPitch';
               else
                   error('Could not determine Pitch')
               end

            elseif keyGroup == 2
               if parameter.trialList{i}.label == 1
                    pitchFolder = 'HighPitch';
               elseif parameter.trialList{i}.label == 2
                    pitchFolder = 'LowPitch';
               else
                   error('Could not determine Pitch')
               end
            else
                error('Invalid keyGroup. Must be 1 or 2.');
            end
            parameter.trialList{i}.filename = [allWords{idx} '.wav'];
            parameter.trialList{i}.filepath = fullfile(parameter.wordFolderBase, pitchFolder, parameter.trialList{i}.filename);
        end
    end        
    else
        error('Invalid test type. Use "practice" or "main".');
    end
end

