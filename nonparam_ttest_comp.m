%compare ttest and non-parametric ttest through permutations (see statcond)

sample_length=10;
nperm=200;

data=rand(1,sample_length);
two_data={data, (data./(1.08))+(rand(1,sample_length)./8)};
[h, p, ~, stats] = ttest(two_data{1}', two_data{2}');
[ori_vals, df] = ttest_cell( two_data{1}, two_data{2});% ttest_cell_select(bla, 'on', 'inhomogenous');
res = surrogdistrib( two_data, 'method', 'perm', 'pairing', 'on', 'naccu', nperm);
surrogval = ttest_cell( res{1}, res{2}); % ttest_cell_select( res, 'on', 'inhomogenous');
pvals = stat_surrogate_pvals(surrogval, ori_vals, 'both');

[p, pvals]