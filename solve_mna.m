function X = solve_mna(c, ana)
    % Modified Nodal Analysis (MNA) Solver
    % Supports: R, L, C, V, I, VCVS, VCCS, CCVS, CCCS
    
    isAC = strcmpi(ana.type, 'AC');
    n = c.N;
    w = ana.omega;
    
    %% --- PASS 1: Build the Global Branch Map ---
    v_list = c.v_names; 
    
    if ~isAC && isfield(c, 'inductor_names') && ~isempty(c.inductor_names)
        v_list = [v_list, c.inductor_names];
    end
    
    num_v = length(v_list);
    A = zeros(n + num_v, n + num_v);
    Z = zeros(n + num_v, 1);
    
    branch_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    if num_v > 0
        branch_map = containers.Map(v_list, (n+1):(n+num_v));
    end

    gmin = 1e-12;
    for i = 1:n, A(i,i) = A(i,i) + gmin; end

    %% --- PASS 2: STAMPING ---

    % Counters for safe sequential mapping
    v_counter = 0;
    vcvs_counter = 0;
    ccvs_counter = 0;

    % 1. Resistors
    if ~isempty(c.resistors)
        for i = 1:size(c.resistors,1)
            n1=c.resistors(i,1); n2=c.resistors(i,2); G=1/c.resistors(i,3);
            if n1>0, A(n1,n1)=A(n1,n1)+G; end
            if n2>0, A(n2,n2)=A(n2,n2)+G; end
            if n1>0 && n2>0, A(n1,n2)=A(n1,n2)-G; A(n2,n1)=A(n2,n1)-G; end
        end
    end

    % 2. Capacitors
    if isAC && ~isempty(c.capacitors)
        for i = 1:size(c.capacitors,1)
            n1=c.capacitors(i,1); n2=c.capacitors(i,2); Y=1j*w*c.capacitors(i,3);
            if n1>0, A(n1,n1)=A(n1,n1)+Y; end
            if n2>0, A(n2,n2)=A(n2,n2)+Y; end
            if n1>0 && n2>0, A(n1,n2)=A(n1,n2)-Y; A(n2,n1)=A(n2,n1)-Y; end
        end
    end

    % 3. Inductors
    if ~isempty(c.inductors)
        for i = 1:size(c.inductors,1)
            n1=c.inductors(i,1); n2=c.inductors(i,2);
            if isAC
                Y = 1/(1j*w*c.inductors(i,3));
                if n1>0, A(n1,n1)=A(n1,n1)+Y; end
                if n2>0, A(n2,n2)=A(n2,n2)+Y; end
                if n1>0 && n2>0, A(n1,n2)=A(n1,n2)-Y; A(n2,n1)=A(n2,n1)-Y; end
            else
                idx = branch_map(c.inductor_names{i});
                if n1>0, A(n1,idx)=1; A(idx,n1)=1; end
                if n2>0, A(n2,idx)=-1; A(idx,n2)=-1; end
                Z(idx) = 0;
            end
        end
    end

    % 4. Current Sources
    if ~isempty(c.currents)
        for i = 1:size(c.currents,1)
            n1=c.currents(i,1); n2=c.currents(i,2);
            val = c.currents(i,3) * exp(1j*deg2rad(c.currents(i,4)));
            if n1>0, Z(n1) = Z(n1) - val; end
            if n2>0, Z(n2) = Z(n2) + val; end
        end
    end

    % 5. Independent Voltage Sources
    if ~isempty(c.vsources)
        for i = 1:size(c.vsources,1)
            % find next pure 'V' (not VCVS/CCVS)
            while true
                v_counter = v_counter + 1;
                name = c.v_names{v_counter};
                if startsWith(name,'V') && ~startsWith(name,'VCVS') && ~startsWith(name,'CCVS')
                    break;
                end
            end
            idx = branch_map(name);

            n1=c.vsources(i,1); n2=c.vsources(i,2);
            val = c.vsources(i,3) * exp(1j*deg2rad(c.vsources(i,4)));

            if n1>0, A(n1,idx)=1; A(idx,n1)=1; end
            if n2>0, A(n2,idx)=-1; A(idx,n2)=-1; end
            Z(idx) = val;
        end
    end

    % 6. VCVS
    if ~isempty(c.vcvs)
        for i = 1:size(c.vcvs,1)
            while true
                vcvs_counter = vcvs_counter + 1;
                name = c.v_names{vcvs_counter};
                if startsWith(name,'VCVS')
                    break;
                end
            end
            idx = branch_map(name);

            out_p=c.vcvs(i,1); out_n=c.vcvs(i,2); 
            ctrl_p=c.vcvs(i,3); ctrl_n=c.vcvs(i,4); gain=c.vcvs(i,5);

            if out_p>0, A(out_p,idx)=1; A(idx,out_p)=1; end
            if out_n>0, A(out_n,idx)=-1; A(idx,out_n)=-1; end
            if ctrl_p>0, A(idx,ctrl_p) = A(idx,ctrl_p) - gain; end
            if ctrl_n>0, A(idx,ctrl_n) = A(idx,ctrl_n) + gain; end
        end
    end

    % 7. VCCS 
    if ~isempty(c.vccs)
        for i = 1:size(c.vccs,1)
            out_p=c.vccs(i,1); out_n=c.vccs(i,2); 
            ctrl_p=c.vccs(i,3); ctrl_n=c.vccs(i,4); gm=c.vccs(i,5);
            if out_p>0 && ctrl_p>0, A(out_p,ctrl_p)=A(out_p,ctrl_p)+gm; end
            if out_p>0 && ctrl_n>0, A(out_p,ctrl_n)=A(out_p,ctrl_n)-gm; end
            if out_n>0 && ctrl_p>0, A(out_n,ctrl_p)=A(out_n,ctrl_p)-gm; end
            if out_n>0 && ctrl_n>0, A(out_n,ctrl_n)=A(out_n,ctrl_n)+gm; end
        end
    end

    % 8. CCVS
    if isfield(c, 'ccvs_data') && ~isempty(c.ccvs_data)
        for i = 1:length(c.ccvs_data)
            data = c.ccvs_data{i};
            out_p=data{1}; out_n=data{2}; ctrl_name=data{3}; rm=data{4};
            
            while true
                ccvs_counter = ccvs_counter + 1;
                name = c.v_names{ccvs_counter};
                if startsWith(name,'CCVS')
                    break;
                end
            end
            idx = branch_map(name);
            
            if out_p>0, A(out_p,idx)=1; A(idx,out_p)=1; end
            if out_n>0, A(out_n,idx)=-1; A(idx,out_n)=-1; end
            
            if isKey(branch_map, ctrl_name)
                ctrl_idx = branch_map(ctrl_name);
                A(idx, ctrl_idx) = A(idx, ctrl_idx) - rm;
            else
                error('CCVS error: Controller %s not found.', ctrl_name);
            end
        end
    end

    % 9. CCCS
    if isfield(c, 'cccs_data') && ~isempty(c.cccs_data)
        for i = 1:length(c.cccs_data)
            data = c.cccs_data{i};
            out_p=data{1}; out_n=data{2}; ctrl_name=data{3}; alpha=data{4};
            
            if isKey(branch_map, ctrl_name)
                ctrl_idx = branch_map(ctrl_name);
                if out_p>0, A(out_p, ctrl_idx) = A(out_p, ctrl_idx) + alpha; end
                if out_n>0, A(out_n, ctrl_idx) = A(out_n, ctrl_idx) - alpha; end
            else
                error('CCCS error: Controller %s not found.', ctrl_name);
            end
        end
    end

    %% --- Solve ---
    X = A \ Z;
end