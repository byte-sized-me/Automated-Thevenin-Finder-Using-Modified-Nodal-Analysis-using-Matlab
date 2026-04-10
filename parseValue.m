function val = parseValue(str)
% Parses numeric values with engineering suffixes
% Example:
%   '10k'  -> 10000
%   '4.7u' -> 4.7e-6
%   '1e3'  -> 1000

    % Clean input
    str = lower(strtrim(str));

    if isempty(str)
        error('Empty value string');
    end

    % Define suffix multipliers
    multipliers = struct( ...
        'g',   1e9, ...
        'meg', 1e6, ...
        'k',   1e3, ...
        'm',   1e-3, ...
        'u',   1e-6, ...
        'n',   1e-9, ...
        'p',   1e-12 ...
    );

    % Try direct numeric conversion first
    val = str2double(str);
    if ~isnan(val)
        return;
    end

    % Check suffixes (longer ones first like 'meg')
    suffixList = {'meg','g','k','m','u','n','p'};

    for i = 1:length(suffixList)
        suffix = suffixList{i};

        if endsWith(str, suffix)
            numPart = extractBefore(str, strlength(str) - strlength(suffix) + 1);
            numVal = str2double(numPart);

            if isnan(numVal)
                error('Invalid numeric format: "%s"', str);
            end

            val = numVal * multipliers.(suffix);
            return;
        end
    end

    % If nothing matched
    error('Invalid value or unknown suffix: "%s"', str);
end