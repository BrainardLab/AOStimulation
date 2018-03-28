function gradient_ana(mv)

len = length(mv);

%g = mv(2)-mv(1);
for i = 1:len-1
    g(i)=mv(i+1)-mv(i);
end

figure;plot(g)
