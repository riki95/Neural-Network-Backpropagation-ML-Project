function [nn, train_acc, test_acc, train_err, test_err, best_err, iter, best_var] = KFold(assessment,use, X, y, fold, inp_dim, out_dim, iterations, bias, threshold_grad, tr_perc, test_perc, shuffle)


% use, inp_dim, out_dim, iterations, bias, threshold_grad are hyperparameters of neural network
% X, y are the dataset and target
% tr_perc, test_perc, shuffle specify the training set and test set splitting size. Shuffle is a boolean to choose whether to shuffle or not the dataset while constructing partitions.
% assessment specifies if Kfold is used for model selection or model assessment


% it returns trained (best) neural network, and the values of statistics on train, validation and test set


    [X, y, ~, ~, x_test, y_test] = train_validation_test_split(X, y, tr_perc, test_perc, shuffle);
    fold_dim = floor(size(X, 1)/fold);
    
         
    hidden_dim = {[30 30]};
    
    eta = [0.01 0.1 0.2];
    
    lambda = [1e-4 1e-3];
    alpha = [0.5 0.7 0.9];

    training_iterations = 2;
    
    %mb_size = 32;%good for monks
    mb_size = fold_dim;%good for wines
    best_err = inf;
    single_val_errors = zeros(1, training_iterations);
    single_tr_errors = zeros(1, training_iterations);
    fold_val_error = zeros(1,fold);
    fold_tr_error = zeros(1,fold);
    
    best_d = 1; % hidden dimension
    best_e = 1; % eta
    best_l = 1; % lambda 
    best_a = 1; % alpha
    best_var = 1;
    tot_iter = size(hidden_dim, 1) *  size(eta, 2) * size(alpha, 2) * size(lambda,2);
    iter = 1;
    for d = 1 : size(hidden_dim, 1)
        for e = 1 : size(eta, 2)
            for l = 1 : size(lambda, 2)
                for a = 1 : size(alpha, 2)
                    index = 0;
                    for i = 1 : fold
                        for it = 1 : training_iterations
                            nn = NeuralNetwork(use,inp_dim, out_dim, hidden_dim{d,:}, iterations, eta(e), lambda(l), alpha(a), bias, threshold_grad, mb_size);
                            [~,~,train_err,~,~] = nn.fit([X(1 : index , :); X(index + fold_dim + 1 : end, :)], [y(1 : index , :); y(index + fold_dim + 1 : end, :)]);
                            [~, ~, val_err] = nn.test(X(index + 1 : index + fold_dim, :), y(index + 1 : index + fold_dim, :));
                            single_val_errors(1,it) = val_err;
                            single_tr_errors(1,it) = train_err(end);
                        end
                        index = index + fold_dim;
                        fold_val_error(1,i) = mean(single_val_errors);
                        fold_tr_error(1,i) = mean(single_tr_errors);
                    end
                    fprintf("Iterazione %d/%d completata.\n",iter,tot_iter);
                    iter = iter + 1;
                    mean_val_fold = mean(fold_val_error);
                    mean_tr_fold = mean(fold_tr_error);
                    
                    % calculate the variance of the current model
                    variance_fold = var(fold_val_error);
                    
                    if mean_val_fold < best_err
                        best_err = mean_val_fold;
                        best_d = d;
                        best_e = e;
                        best_l = l;
                        best_a = a;
                        best_var = variance_fold;
                    end
                end
            end
        end
    end
    % re-train on training set + validation set
    nn = NeuralNetwork(use,inp_dim, out_dim, hidden_dim{best_d,:}, iterations, eta(best_e), lambda(best_l), alpha(best_a), bias, threshold_grad, mb_size);
    if ~assessment
        [train_acc,test_acc,train_err,test_err, iter] = nn.fit(X, y, x_test, y_test);
    else
        test_acc = NaN;
        train_acc = NaN;
        best_err = mean_val_fold;
        best_var = variance_fold;
        %[train_acc, ~, train_err, ~, iter] = nn.fit(X, y, x_test, y_test);
        train_err = mean_tr_fold;
        test_err = NaN;
    end
end