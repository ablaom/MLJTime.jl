#using  NearestNeighbors: Metric
#import Distances: evaluate
using StatsBase: mode

#evaluate(dist::dwt, a, b) = dtw_distance(a, b, dist.w)

"""
   `dtw_distance(a, b, w)` is the basic dynamic time wraping function.
where `a` & `b` are the time series matrices and `w` is the percentage 
of window for warping.
"""
function dtw_distance(a, b, w)
    l_a, l_b = length(a), length(b)
    FloatMax = maxintfloat(Float64)
    if w <= 0
        band = max(l_b, l_a)
    else
        band = floor(Int, w*max(l_b, l_a))
    end
    M = zeros(l_a+1,l_b+1)
    M[1, 2:end] .= FloatMax
    M[2:end, 1] .= FloatMax
    for k=2:l_a 
        M[k, 2:end] =  (a .-  b[k]).^2
    end
    for i=2:l_a+1
        jstart = max(2, i-band)
        jstop = min(l_b+1, i+band+1)
        idx_inf_left = i-band-1
        
        if idx_inf_left >= 1
            M[i, idx_inf_left] = FloatMax
        end
        for j=jstart:jstop
            im = i-1
            jm = j-1
            M[i,j] = M[i,j] + min(min(M[im,j], M[i,jm]), M[im,jm])
        end
        if jstop < l_b + 1
            M[i,jstop] = FloatMax
        end
    end
    return M[l_a+1,l_b+1]   
end

function Predict_new(m, X::Array, Y::Array, yplane::Array) 
    k = m.n_neighbors
    n_train, serieslength = size(X)
    n_test = size(Y, 1)
    y_pred = zeros(n_test)
    DistanceMatrix = zeros(n_test, n_train)
    for i=1:n_test
        for j=1:n_train
            DistanceMatrix[i, j] = dtw_distance(X[j,:],Y[i,:], m.metric_params[1])
        end
    end
    index = select_sort(DistanceMatrix, k)
    y_index = yplane[Int.(index)]
    for i=1:n_test
        y_pred[i] = mode(y_index[i, :])
    end
    return y_pred, DistanceMatrix
end

function select_sort(A, k) # some times we get consicative indx
    n_test, n_train = size(A)
    index = zeros(n_test, k)
    for l=1:n_test
        for i=1:n_train
            if i > k
                break 
            end
            min_idx = i 
            for j=i+1:n_train
                if A[l, min_idx] > A[l, j] 
                    min_idx = j    
                end             
            end    
            A[l, i], A[l, min_idx] = A[l, min_idx], A[l, i]
            index[l, i] = min_idx
        end
    end
    return index
end

# Add tuning and fit!, predic interface