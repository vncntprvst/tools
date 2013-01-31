function MakeASCII4(whichfile, whatch)
load([whichfile '.mat']);
eval(['data = ' whichfile '_Ch' num2str(whatch,'%d')]);

FID = fopen([whichfile '.txt'], 'w');
eno = 0;
fprintf(FID, '%d\t%d\tet\n',25,data.items);
data.times = round(data.times.*50000);
data.values = abs(data.values);
for a = 1:25
        newrow = [];
    for b = 1:data.items
        if (b == data.items)
        newrow = [newrow sprintf('%7.7f',data.values(a,b))];  
        else
        newrow = [newrow sprintf('%7.7f\t',data.values(a,b))];  
        end
    end
    if a == 25
    fprintf(FID, ['%d\t%d\t' newrow],eno,data.times(a));
    else
    fprintf(FID, ['%d\t%d\t' newrow '\n'],eno,data.times(a));    
    %keyboard;
    end
end
fclose(FID);
%keyboard;
end