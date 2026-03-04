function value = VegaKO(F0, K, KO, B, T, sigma, N, flagNum)
h=0.01; % a small number to simulate the infinitesimal change in value
    switch (flagNum)
        %utilizzo differenze finite centrali per approssimare la derivata
        case 1  % CRR
            Up = EuropeanOptionKOCRR(F0, K, KO, B, T, sigma+h, N);
            Down = EuropeanOptionKOCRR(F0, K, KO, B, T, sigma-h, N);
            value = (Up - Down)/(2*h*100); %for percentage
    
        case 2  % MC
            %this time we can't call two times the function for KO MC since the
            %results wouldn't be in continuous, we modify here the function
    
            Z = randn(N, 1); %generation of std normal random variables 
    
            %generation of Up value
            ST = F0 * exp(-0.5 * (sigma+h)^2 * T + (sigma+h) * sqrt(T) * Z); 
            for i=1:N
                if ST(i)<KO
                    payoff(i)= max(ST(i) - K, 0); % Call payoff at expiry
                else
                    payoff(i)= 0;
                end
            end
            Up = B * mean(payoff);  %actualizing and taking the mean 
    
            %generation of Down value
            ST = F0 * exp(-0.5 * (sigma-h)^2 * T + (sigma-h) * sqrt(T) * Z); 
            for i=1:N
                if ST(i)<KO
                    payoff(i)= max(ST(i) - K, 0); % Call payoff at expiry
                else
                    payoff(i)= 0;
                end
            end
            Down = B * mean(payoff);  %actualizing and taking the mean 
    
            value = (Up - Down)/(2*h)/100;
    
        case 3  % Exact
            % Controllo logico: se lo strike è oltre la barriera, l'opzione vale 0 (quindi Vega = 0)
        % Usiamo zeros(size(F0)) per restituire un vettore di zeri lungo quanto F0
            if K >= KO
                value_ = zeros(size(F0));
                return;
            end
            
            % Calcolo di d1 e d2 (nota l'uso di 'log' e degli operatori element-wise './')
            d1_K = (log(F0 ./ K) + sigma^2 * T / 2) ./ (sigma * sqrt(T));
            d1_KO = (log(F0 ./ KO) + sigma^2 * T / 2) ./ (sigma * sqrt(T));
            d2_KO = d1_KO - sigma * sqrt(T);
            
            % Calcolo del Vega (nota l'uso spinto di '.*' e './' per i vettori)
            value_ = F0 .* B .* sqrt(T) .* (normpdf(d1_K) - normpdf(d1_KO)) ...
                    + (KO - K) .* B .* normpdf(d2_KO) .* d1_KO ./ sigma;
            value = value_ /100;
        otherwise
            error('FlagNum should be 1, 2 or 3');
    end
end