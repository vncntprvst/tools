function y=sc_remap(x,a,b,a_n,b_n)
    

    y= ((x-a)*((b_n-a_n)/(b-a)) )+a_n;
