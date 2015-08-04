%%%%%%%%%%%%%%%%%%%%%%%%%%
% John P Cunningham
% 2013
%
% skewSymAffineRegress
%
% This is the same as skewSymRegress but it adds an affine term, regressing
% dX = XM + repmat(y) (that is, dx(t) = x(t)*M + y ). The incremental
% changes are entirely to pad the solution with that extra affine term y.
%
% This function does least squares regression between a matrix dX and X.
% It finds a matrix M such that dX = XM (as close as possible in the 
% least squares sense).  Unlike regular least squares regression (M = X\dX)
% this function find M such that M is a skew symmetric matrix, that is, 
% M = -M^T.
%
% Put another way, this is least squares regression over the constrained set
% of skew-symmetric matrices.  
%
% This can be solved by treating M as a vector of the unique elements that
% exist in a skew-symmetric matrix. A skew-symmetric matrix M of size n by n really only
% has n*(n-1)/2 unique entries.  That is, the diagonal is 0, and the
% upper/lower triangle is the negative transpose of the lower/upper.  So,
% we can just think of such a matrix as a vector x of size n(n-1)/2.
%
% Corresponding to this change in M, we would have to change X to be quite
% big and quite redundant.  That can be done, but an easier and 
% faster and more stable thing to do is to use an iterative solver
% that takes a function and gradient evaluation. 
% This iterative procedure is numerically accurate, etc, etc.
% So, this allows us to never make a big X skew matrix, and we just have to
% reshape M between vector and skew-symmetric matrix form as appropriate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ M , y , fM ]  = skewSymAffineRegress(dX,X)
    
    % check that dX and X are appropriately sized.
    if ~isequal(size(dX),size(X))
        fprintf('ERROR: dX and X are not matched in size... a skew symmetric matrix can not result.\n');
        keyboard
    end
    if size(dX,2) > 20 || size(X,2) > 20 || size(dX,1) < 20 || size(X,1) < 20
        fprintf('ERROR (likely): dX and X should be ct by k, where ct is big and k is small, like 6.  Currently your ct is small or k is big.\n');
        keyboard
    end
    if size(dX,1) < size(dX,2) || size(X,1) < size(X,2)
        fprintf('ERROR (almost definitely): dX and/or X are fat, not skinny.  This will result in a subrank solution.\n');
        keyboard
    end
   
    % initialize m0 somehow. It does not matter, as this function is
    % convex... ie there is provable one unique minimizer.  But a good
    % initialization will help the optimization converge faster in theory
    % (though in practice this is so fast anyway that it is unnoticed).
    M0 = X\dX; % the non-skew-symmetric matrix.
    M0k = 0.5*(M0 - M0'); % the skew-symmetric matrix component... this is jPCA in the original form.
    m0 = reshapeSkew(M0k);
    % now initialize y0.  y0 is closed form given M, so we start there...
    % note that y0 is really a row vector, since it is shaped the same as
    % any x(t) or dx(t) (which are rows of X and dX).
    y0 = mean(dX - X*M0k);
    % now the variable of interest is 
    z0 = [m0; y0'];
    
    %%%%%%%
    % the following call does all the work
    %%%%%%%
    % just call minimize.m with the appropriate function...
    [z, fM, i] = minimize( z0 , 'skewSymAffineLSeval' , 1000, dX , X );
    
    
    % check to make sure that nothing was funky.
    if i > 500
        fprintf('Warning: more than 500 line searches were required for minimize to complete.  It should complete much more quickly.  Check the code or the conditioning of the matrices.\n');
        keyboard
    end
    
    % now partition the result back into M and y
    m = z(1 : end-size(X,2));
    y = z(end-size(X,2)+1:end)';
    % return the matrix
    M = reshapeSkew(m);
    
end
