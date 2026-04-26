function p = stable_logit(z)

    p = zeros(size(z));
    idx = z >= 0;
    p(idx) = 1 ./ (1 + exp(-z(idx)));
    ez = exp(z(~idx));
    p(~idx) = ez ./ (1 + ez);

end
