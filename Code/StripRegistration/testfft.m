function testfft(y);
% N=1e6;%????1e6?
% 
% fs=150000;%????150kHz
% 
% f1=15000;%15kHz
% 
% f2=35000;%35kHz
% 
% t=0:1/fs:1/fs*(N-1);
% 
% y=sin(2*pi*f1*t)+sin(2*pi*f2*t);

N=length(y);
F=fft(y,N);

%F=abs(F);

F=20*log(abs(F))/log(10);

F=F(1:N/2);

% ft=[0:(fs/N):fs/2];
% 
% ft=ft(1:N/2);

% plot(ft,F);
figure;plot(F)

% method 2
%y= Datain (:,2);

% N= length(y);
% 
% fs=1/(3.9960e-10);%fs???????????fs=1/Ts=1/(419e-6/1048559),Ts??????????????????????
% 
% F=fft(y,N);%FFT??
% 
% F=abs(F);
% 
% F=F(1:N/2);
% 
% ft=[0:(fs/N):fs/2];%???????
% 
% ft=ft(1: N/2);
% 
% plot(ft,F);%?????
% 
% axis([0, 3e5, 0, 3e6]);%???????
% 
% grid on
