% Mean and standard deviation of noisy samples
x = linspace(0, 1, 100);
y = sin(2*pi*x) + 0.1*randn(size(x));
fprintf('mean = %.3f, std = %.3f\n', ...
        mean(y), std(y));
