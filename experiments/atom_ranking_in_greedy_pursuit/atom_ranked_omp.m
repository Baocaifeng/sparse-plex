function result = atom_ranked_omp(Phi, y, K, atoms_to_match, matching_mode)
% dimensions
[n, d] = size(Phi);
% active indices
omega = [];
% residual
r = y;
% residual norm
r_norm = norm(r);
% result
z = zeros(d, 1);
atom_index_sum = 0;
selected_atoms = 1:d;
if nargin == 3
    atoms_to_match = n;
end
if nargin < 5
    matching_mode = 3;
end

% array to hold inner products in the original atom order.
abs_inner_products = zeros(1, d);
for iter=1:K
    % Compute inner products with atoms arranged in the order 
    % based on their ranking [for selected atoms]
    inner_products = abs(Phi(:, selected_atoms)' * r);
    %inner_products(omega) = 0;
    inner_products = abs(inner_products) / r_norm;
    % Find the highest inner product
    [~, max_index] = max(inner_products);
    % maximum index
    %fprintf('chosen atom index: %d\n', max_index);
    % we need to get the original index at this point.
    original_index = selected_atoms(max_index);
    % store the updated inner products for the selected indices here.
    abs_inner_products(selected_atoms) = inner_products;
    % Add this index to support
    omega = [omega, original_index];
    % track the atom index position
    atom_index_sum = atom_index_sum + max_index;
    % Solve least squares problem
    subdict = Phi(:, omega);
    tmp = linsolve(subdict, y);
    % Updated solution
    z(omega) = tmp;
    % Let us update the residual.
    r = y - subdict * tmp;
    % residual norm
    r_norm = norm(r);
    if r_norm < 1e-6
        % no point going forward. we have already recovered the signal
        break;
    end
    update_atom_order();
end
% Solution vector
result.z = z;
% Residual obtained
result.r = r;
% Solution support
result.support = omega;
% Number of iterations
result.iterations = iter;
% Average atom index
result.atom_index_average = atom_index_sum / iter;

function update_atom_order()
    switch matching_mode
        case 1
            % select all atoms in original order
            selected_atoms = 1:d;
        case 2
            % select all atoms in rank order
            [~, selected_atoms] = sort(abs_inner_products, 'descend');
        case 3
            % select a percentage of atoms in rank order
            [~, selected_atoms] = sort(abs_inner_products, 'descend');
           selected_atoms  = selected_atoms(1:atoms_to_match);
        otherwise
            error('Not supported.');
    end
end

end
