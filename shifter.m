function v = shifter(data,template)
% data is the data set to be matched
% template is the template to match
% v is an array of variances of the residual at each shifted point

p = 1 : length(data) - length(template);
q = 0 : length(template) - 1;
[P,Q] = ndgrid(p,q);
dataarray = data(P+Q);
temparray = repmat(template,length(data)-length(template),1);
v = var(dataarray-temparray,[],2);