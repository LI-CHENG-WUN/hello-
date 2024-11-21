clc,clear
%產生新package不會100%發送
%如果在t-1時在backlog裡的node超過2個，用產生的機率傳送，低於兩個直接傳輸

K=100;              %slot數_100000
M=10 ;              %node數_100
theta=1/(M);      %生成新package的機率
threshold=floor(exp(1)*M-(1/theta)+1);   %固定的threshold
gen=rand(M,K)  ; %生成package的機率
send=zeros(M,K); %傳送package的機率
backlog=zeros(M,K) ;  %待傳送的package池
N=zeros(1,K);   %n(k),n(0)=0
w=zeros(M,K);   %source的瞬時AoI
h=ones(M,K);   %destination的瞬時AoI
pb=zeros(M,K);  %機率
sendA=rand(M,1);

suc=0;  %成功次數
ES=0;   %平均S
PAoI=zeros(1,K); 

Z=min(M*theta,exp(1)^(-1)); %Algorithm 2  說明 使用min取代原本的Mθ

%=============================================%

%t=1時
for i=1:M
        if gen(i,1)<theta
            send(i,1)=1;
        else 
            send(i,1)=0;
       end
end
Sum_s=sum(send) ; %t時有幾個node有package要傳送
for i=1:M
    if Sum_s(1,1)<2
        N(1,1)=max(Z,Z-1);
    else
        N(1,1)=Z+(exp(1)-2)^(-1);
    end
pb(i,1)=min(1,1/N(1,1));
    if send(i,1)==1 && Sum_s(1,1)>1
        backlog(i,1)=1;
    else
        backlog(i,1)=0;
    end
Sum_b=sum(backlog);
end 
%=============================================%
%t=2
for t=2:K
    sendA=rand(M,1);
    for i=1:M
        if gen(i,t)<theta
            w(i,t)=0;
            backlog(i,t-1)=1;
        else 
            if backlog(i,t-1)==1 && sendA(i,1)<=pb(i,t-1) %有尚未傳輸的封包，用更新的機率傳輸
               
                send(i,t)=1;
            else
                send(i,t)=0;
            end
            w(i,t)=w(i,t-1)+1;
        end
    end 
    Sum_s(1,t)=sum(send(1:M,t),1);
    for i=1:M
        h(i,t)=h(i,t-1)+1;
        if backlog(i,t-1)==1
            backlog(i,t)=1;
        else
            backlog(i,t)=0;
        end
        if Sum_s(1,t-1)<2
            N(1,t)=max(Z,N(1,t-1)+Z-1);
        else
            N(1,t)=N(1,t-1)+Z+(exp(1)-2)^(-1);
        end
        pb(i,t)=min(1,1/N(1,t));
        if send(i,t)==1
            if Sum_s(1,t)==1
                backlog(i,t)=0;
                h(i,t)=w(i,t-1)+1; %AoI降到source的AoI

            else
                backlog(i,t)=1;
            end
        end
        Sum_b(1,t)=sum(backlog(1:M,t),1);
        if (h(i,t)-w(i,t))>threshold
            pb(i,t)=pb(i,t);
        else
            pb(i,t)=0;
        end
    end 
end

n=1;

%計算AoI
for t=2:K
    if send(1,t)==1 && Sum_s(1,t)==1
        ES=ES+w(1,t-1);
        PAoI(1,t)=h(1,t-1)+1;
        suc=suc+1;
        n=n+1;
        j(1,n)=t;
    else
        ES=ES;
    end
end

AoI_A=0;
j(1,1)=1;
for o=2:n
    q=j(1,o-1);
    AoI_A=AoI_A+((j(1,o)-j(1,o-1))^2)/2+(j(1,o)-j(1,o-1))*w(1,q);
end

P=0;
for i=1:K
    P=P+PAoI(1,i);
end
MaxP=max(PAoI);
MinP=min(PAoI(PAoI~=0));
throughput=suc/K;
ave_P=P/suc;
ES=ES/suc;

AoI=AoI_A/(M*K) ;
%fprintf('The AoI is %5.4f\n',AoI)