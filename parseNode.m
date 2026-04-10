function n = parseNode(str)
% Parses and validates node numbers
% Node must be a non-negative integer

    str = strtrim(str);

    if isempty(str)
        error('Empty node value');
    end

    n = str2double(str);

    if isnan(n)
        error('Invalid node (not a number): "%s"', str);
    end

    if n < 0
        error('Node number cannot be negative: "%s"', str);
    end

    if mod(n,1) ~= 0
        error('Node must be an integer: "%s"', str);
    end

    % Optional: enforce integer type
    n = round(n);
end