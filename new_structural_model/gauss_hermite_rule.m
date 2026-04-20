function [nodes, weights] = gauss_hermite_rule(n)
% Golub-Welsch rule for:
%   integral exp(-x^2) f(x) dx ~= sum_j weights_j f(nodes_j)

    i = (1:n-1)';
    offdiag = sqrt(i / 2);
    J = diag(offdiag, 1) + diag(offdiag, -1);

    [V, D] = eig(J);
    nodes = diag(D);
    [nodes, order] = sort(nodes);
    V = V(:, order);

    weights = sqrt(pi) * (V(1, :) .^ 2)';
end
