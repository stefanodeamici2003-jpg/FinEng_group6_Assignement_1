function Bermudan_price = BermudanOptionPrice(F0, K, T, B, sigma, q, M)

% Calcoliamo r a partire dal fattore di sconto B
r = -log(B) / T;

% 2. Setup dell'Albero Binomiale
dt = T / M;
Exer_times = [ceil(M/4), ceil(M/2), ceil(3*M/4)];

% Parametri albero in misura Forward
u = exp(sigma * sqrt(dt));
d = 1 / u;
p = (1 - d) / (u - d); % Probabilità per la martingala Forward

% 3. Generazione dei nodi finali (Scadenza T)
j = 0:M; % Numero di up-moves
F_T = F0 * (u.^j) .* (d.^(M - j));

% Payoff a scadenza in misura forward 
V = max(F_T - K, 0);

% 4. Backward Induction con condizione Bermudiana
for i = (M - 1):-1:0
    
    % Continuation Value (misura Forward, no sconto r*dt qui)
    V = p * V(2:end) + (1 - p) * V(1:end-1);
    
    % Controllo se il nodo corrisponde alla fine di un mese
    if ismember(i, Exer_times)
        t_i = i * dt; % Tempo corrente in anni
        
        % Vettore dei prezzi Forward correnti
        j_current = 0:i;
        F_t = F0 * (u.^j_current) .* (d.^(i - j_current));
        
        % Calcolo dello Spot Price corrente (S_t) a partire dal Forward
        S_t = F_t * exp(-(r - q) * (T - t_i));
        
        % Payoff di esercizio reale normalizzato per il numerario P(t_i, T)
        P_t_T = exp(-r * (T - t_i));
        Payoff_esercizio = max(S_t - K, 0) / P_t_T;
        
        % Condizione Bermudiana: massimo tra continuazione ed esercizio
        V = max(V, Payoff_esercizio);
    end
end

% 5. Conversione finale al tempo 0
% Moltiplichiamo il valore dell'albero per il numerario al tempo 0, P(0,T) che equivale a B
Bermudan_price = B * V(1);

end