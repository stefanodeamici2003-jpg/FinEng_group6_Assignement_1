function Vega = VegaAmericanKO(F0, K, KO, B, T, sigma, q)
% Let's program the functino in the same style as we did for Vega

h = sigma/100;
% Just use the closed formula since we can
up_value = EuropeanOptionAmericanBarrier(F0, K, KO, B, T, sigma+h, q);
down_value = EuropeanOptionAmericanBarrier(F0, K, KO, B, T, sigma-h, q);
% Using centered differences we get a much better convergence
Vega = (up_value - down_value)/(2*h);
return