function residual_var = template_curve_match(shift,xvals,data,template)
residual = data(xvals)-polyval(template,xvals+round(shift));
residual_var=var(residual);
end