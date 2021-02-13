function norm_m = bj_norm(M)
% BJ_NORM Performs the norm function on multiple vectors.
%
% NORM_M = BJ_NORM(M) Takes as input M, an n x 3 matrix containing n
% vectors of length 3 whose norm is to be found. Outputs the norms of those
% vectors in an n x 1 vector.

num_vectors = size(M,1);
norm_m = zeros(num_vectors, 1);

for i = 1:num_vectors,
    norm_m(i) = norm(M(i,:));
end