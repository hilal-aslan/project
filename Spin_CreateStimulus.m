function [mixed, startIdx] = Spin_CreateStimulus(wordFilepath, noiseFile, parameter, currentSNR)

    [wordAudio, fs_word] = audioread(wordFilepath);
 
    % Jitter function for timing variation
    jitter = @(base) round((base + (rand()*0.1 - 0.05)) * parameter.fs); % Function to add ±50 ms jitter to silence around words (base is in seconds, fs converts to samples)
    
    % Add jittered silence before and after word
    leadSil = zeros(jitter(0.2), 1);   % Leading silence (random around 0.5 sec ± 50 ms)
    trailSil = zeros(jitter(0.2), 1);  % Trailing silence (random around 0.5 sec ± 50 ms)
    trialAudio = [leadSil; wordAudio; trailSil];  % Concatenate silence + word + silence into one audio vector
    
    % Select Unique segment of noise 
    requiredLength = length(trialAudio);  % Length of the speech signal
    noiseLength = length(noiseFile);        % Total length of the noise file
    maxStartIdx = noiseLength - requiredLength + 1;  % Last valid starting index  

    if maxStartIdx <= 0
        error('Noise is too short to extract a full segment without repetition or extension.');
    end
    
    % Find unique noise segment
    startIdx = randi(maxStartIdx);
      
    % Extract noise segment
    noise = noiseFile(startIdx : startIdx + requiredLength - 1);
    
    % Apply 100 ms raised cosine (Hann) ramp to noise
    rampSamples = round(0.1 * parameter.fs);
    ramp = hann(2 * rampSamples);
    fadeIn = ramp(1:rampSamples);
    fadeOut = ramp(rampSamples+1:end);
    
    noise(1:rampSamples) = noise(1:rampSamples) .* fadeIn;
    noise(end-rampSamples+1:end) = noise(end-rampSamples+1:end) .* fadeOut;
    
    % Adjust noise level for desired SNR
    speechRMS = rms(trialAudio);
    if speechRMS < eps, speechRMS = eps; end
    desiredNoiseRMS = speechRMS / (10^(currentSNR/20));
    currentNoiseRMS = rms(noise);
    if currentNoiseRMS < eps, currentNoiseRMS = eps; end
    noise = noise * (desiredNoiseRMS / currentNoiseRMS);
    
    % Mix speech and noise
    mixed = trialAudio + noise;
    mixed = mixed / max(abs(mixed));  % Normalize to prevent clipping
   
end


