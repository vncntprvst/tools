function [x,y,b]  = sc_ginput(n)

global debugstate;

debuginput= [-1.1 1.2 1 ;  % click load button
  %  -1.1316    1.1370    1.0000;  % do some cluster stuff
    0.0592   -1.0419    1.0000;
    -0.4966    1.1272    1.0000;
    -0.2826    1.0920    1.0000;
    -1.1451    0.1113    1.0000;
    -1.0716   -0.2752    1.0000;
    -1.1355   -0.4222    1.0000;
    -1.0556   -0.5563    1.0000;
    -1.0428   -0.7927    1.0000;
    -1.1483    0.0666    1.0000;
    1.4967    0.5553    1.0000;
    -1.1642   -1.0163    1.0000;
    -0.4519    1.0697    1.0000;
    -0.7394    1.0888    1.0000;
    0.9665    0.9642    1.0000;
    0.9441    0.9834    3.0000;
    -0.8128   -1.1665    1.0000;
    -0.1197   -1.1665    1.0000;
    0.6853   -1.1313    1.0000;
    0.2797   -1.2048    3.0000;
    -0.6883   -1.0387    1.0000;
    -1.1451   -0.6522    1.0000;];


if (debugstate >= size(debuginput,1))
    error('last debug state reached!');
end;

if (debugstate == 0);
    
    [x,y,b] = ginput(n); % draws crosshairs and returns location of click

else
    
    x=debuginput(debugstate,1);
    y=debuginput(debugstate,2);
    b=debuginput(debugstate,3);
    
    debugstate =debugstate+1;
    
end;