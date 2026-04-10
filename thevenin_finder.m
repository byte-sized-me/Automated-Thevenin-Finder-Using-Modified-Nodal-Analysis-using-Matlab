function [Vth, Zth] = thevenin_finder(circuit, n1, n2, analysis)
    % 1. Calculate Vth (Open-Circuit Voltage)
    X_oc = solve_mna(circuit, analysis);
    v1 = 0; v2 = 0;
    if n1 > 0 && n1 <= size(X_oc,1), v1 = X_oc(n1); end
    if n2 > 0 && n2 <= size(X_oc,1), v2 = X_oc(n2); end
    Vth = v1 - v2;

    % 2. Calculate Zth (Thevenin Impedance)
    dead_circuit = circuit;
    
    % Zero all Independent Voltage Sources
    if ~isempty(dead_circuit.vsources)
        dead_circuit.vsources(:,3) = 0;  % Zero magnitude
        dead_circuit.vsources(:,4) = 0;  % Zero phase
    end
    
    % Zero all Independent Current Sources
    if ~isempty(dead_circuit.currents)
        dead_circuit.currents(:,3) = 0; 
        dead_circuit.currents(:,4) = 0;
    end
    
    test_source = [n2 n1 1 0]; % Inject 1A from n1 to n2
    if isempty(dead_circuit.currents)
        dead_circuit.currents = test_source; % Initialize if empty
    else
        dead_circuit.currents = [dead_circuit.currents; test_source]; % Append
    end
    
    % Solve for Test Case
    X_test = solve_mna(dead_circuit, analysis);
    vt1 = 0; vt2 = 0;
    if n1 > 0 && n1 <= size(X_test,1), vt1 = X_test(n1); end
    if n2 > 0 && n2 <= size(X_test,1), vt2 = X_test(n2); end
    
    % Zth = V_measured / I_test (where I_test = 1)
    Zth = vt1 - vt2;
end