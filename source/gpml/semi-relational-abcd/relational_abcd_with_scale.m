function [ varargout ] = relational_abcd_with_scale(model, hyp, sn,  cov_fS, cov_f, x, y, xs, ys)
%RELATIONAL_ABCD Summary of this function goes here
%   Detailed explanation goes here

if nargin < 7 || nargin > 9
    disp('Usage [nlZ ndlZ] = relationa_abcd(hyp_fS, hyp_f, x, y, xs, ys)');
end



try
if nargin > 7
    %do something
else
    if nargout == 1
        [post nlZ] = inf_scale(hyp, mean, cov, lik, x, y); dnlZ = {};
    else
        [post nlZ dnlZ] = inf_scale(hyp, sn, cov_fS, cov_f, x, y, model);
    end
end
catch
    msgstr = lasterr;
    warning('Inference method failed [%s] .. attempting to continue',msgstr)
    varargout = {NaN, 0*hyp, 0}; return
end

if nargin == 7
    varargout = {nlZ, dnlZ, post};
end
    


end

function [post nlZ dnlZ] = inf_scale(hyp0, sn, cov_fS, cov_f, x, y, model)

[scale hyp_fS, hyp_f] = seperate_hyp_with_scale(model, hyp0);

[N, D] = size(x);
M = size(y,2);
% cov = {@covSum, {{@covConst}, {@covProd, {@covConst, cov_fS}}, cov_f}};
cov = {@covSum, {{@covSum, {{@covConst}, {@covProd, {@covConst, cov_fS}}}}, cov_f}};

for i = 1:M
    hyp{i} = vertcat(scale{i}, hyp_fS, hyp_f{i}); % calculation here
end
sn2 = exp(2*sn);
for i = 1:M
    K{i} = feval(cov{:}, hyp{i}, x);
    L{i} = chol(K{i}/sn2+eye(N)); 
    alpha{i} = solve_chol(L{i},y(:,i))/sn2;
end

post.alpha = alpha;
post.L = L;

if nargout > 1
    nlZ = 0;
    for m = 1:M
        nlZ = nlZ + y(:,m)'*alpha{m}/2 + sum(log(diag(L{m}))) + N*log(2*pi*sn2)/2;
    end
    if nargout > 2
        dnlZ = zeros(size(hyp0)); % input here
        for m = 1:M
            Q{m} = solve_chol(L{m},eye(N))/sn2 - alpha{m}*alpha{m}';
        end
        
        for m = 1:M
            dnlZ(2*m - 1) = sum(sum(Q{m}.*feval(cov{:}, hyp{m}, x, [], 2*m - 1)))/2;
            dnlZ(2*m) = sum(sum(Q{m}.*feval(cov{:}, hyp{m}, x, [], 2*m)))/2;
        end
        for i = 1: numel(hyp_fS)
%             dnlZ(2*M + i) = 0;
            for m = 1:M
                dnlZ(2*M + i) = dnlZ(2*M + i) + sum(sum(Q{m}.*feval(cov{:}, hyp{m}, x, [], 2*M + i)))/2;
            end
        end
        index = 2*M + numel(hyp_fS);
        for m = 1:M
            for i = 1:length(hyp_f{m})
                index = index + 1;
                dnlZ(index) = sum(sum(Q{m}.*feval(cov{:}, hyp{m}, x, [], 2 + numel(hyp_fS) + i)))/2;
            end
        end
    end
end

end

