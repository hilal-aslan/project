function outText = getDrawMainText(group, keyGroup)

    if strcmpi(group, 'R') && keyGroup == 1

        outText = ['Decide if the word is living or non-living.\n\n' ...
            'Z = living\n' ...
            'M = non-living'];

    elseif strcmpi(group, 'D') && keyGroup == 1
        outText = ['Decide if the word is high pitch or low pitch.\n\n' ...
            'Z = low pitch\n' ...
            'M = high pitch'];

    elseif strcmpi(group, 'R') && keyGroup == 2

        outText = ['Decide if the word is living or non-living.\n\n' ...
            'Z = non-living\n' ...
            'M = living'];

    elseif strcmpi(group, 'D') && keyGroup == 2
        outText = ['Decide if the word is high pitch or low pitch.\n\n' ...
            'Z = high pitch\n' ...
            'M = low pitch'];
    else
        error('Could not determine group and/or keyGroup')
    end
    end

