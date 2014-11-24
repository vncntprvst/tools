switch whichKernel
    case 'linear'
        kernelfun = @kernel_lin;
    case 'gaussian'
        kernelfun = @kernel_gauss;
    case 'polynomial'
        kernelfun = @kernel_poly;
    otherwise
        error('specified kernel not found');
end
