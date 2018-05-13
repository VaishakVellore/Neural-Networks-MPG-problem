fid = fopen('auto-mpg1.csv');
c = textscan(fid, '%f%d%f%f%f%f%d%d%s','Delimiter','\n');
Cylinder = c{1};
Displacement= c{2};
HorsePower = c{4};
Carweight= c{5};
Acceleration = c{6};
fclose(fid);


