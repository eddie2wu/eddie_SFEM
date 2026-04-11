function ll_im = ll_im_b(gamma,A, match, min_match, max_match, id, min_id, max_id, strg)

% modified version of ll_im as proposed by PDB, namely it imposes the same
% machine on all obs from a given subject

% input

% gamma is a scalar estimate
% A: 1 = cooperate, 0 = defect
% match: indicates the match, > 0
% min_match: = min(match)
% max_match: = max(match)
% id: subject specific identifier
% min_id: = min(id)
% max_id: = max(id)
% strg_M: Matrix with each colum giving a different machine. Each row gives the choice that machine would make. 

% output

% -loglikelihood
%--------------------------------------------------------------------------

% computations begin
p_imr = ( ( 1 ./ ( 1 + exp(- (strg) / gamma) ) ).*( A ) ) +...
    (( 1 ./ ( 1 + exp( (strg) / gamma) ) ).*( 1 - A ));

ij = 0;
for i = min_id:max_id
    ij = ij + 1;
    p_im(ij,1) = prod(p_imr(find(id == i)));
end

ll_im = p_im;
