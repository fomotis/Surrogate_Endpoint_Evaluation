## ----setup, include=FALSE------------------------------------------------
rm(list=ls())
library(tidyverse)
library(readxl)
library(ggplot2)
library(GGally)
library(knitr)
library(exactRankTests)
library(glmnet)
library(Biobase)
library(siggenes)
library(limma)
library(multtest)
library(IntegratedJM)
library(nlme)
library(Surrogate)
library(xtable)
knitr::opts_chunk$set(echo=F,message=F,warning=F)

## ----reading_data--------------------------------------------------------
p_data <- read_excel("./Data/Dataset_Thesis.xlsx",sheet=1,range="A1:AJ17",col_names=T)
p_data$trt[p_data$treatment=="own_feces"] <- 0
p_data$trt[p_data$treatment=="donorfeces"] <- 1
#taking log of the counts
datalog <- data.frame(apply(p_data %>% dplyr::select(-patient,-age,-treatment,-rdt0,
                                     -rdt6,-Diff_rdt6_rdt0,-trt),2,log))
#all counts of bacteria logged
p_datalog <- data.frame(bind_cols(p_data %>% dplyr::select(patient,age,treatment,rdt0,rdt6,
                                         Diff_rdt6_rdt0), datalog))

## ----exploration---------------------------------------------------------
#matrix of only surrogates
S <- data.frame(p_data %>% dplyr::select(-treatment,-patient,-age,-rdt0,-rdt6,-Diff_rdt6_rdt0,-trt))
S_log <- data.frame(p_datalog %>% dplyr::select(-treatment,-patient,-age,-rdt0,-rdt6,-Diff_rdt6_rdt0))
pps <- seq(0,27,3)
for(i in 1:10){
  par(mfrow=c(3,2))
  a <- pps[i]
  for(j in 1:3){
    a <- a+1
    if(a > 30) break
    #original
    #experimental treatment
    plot(S[,a],p_data$Diff_rdt6_rdt0,type="n", xlab="Surrogate",
         ylab="True",main=paste0("Counts","(Surrogate",a,")"))
    points(S[p_data$treatment=="donorfeces",a],p_data$Diff_rdt6_rdt0[p_data$treatment=="donorfeces"],pch=19,col="green3")
    #control treatment
    points(S[p_data$treatment=="own_feces",a],p_data$Diff_rdt6_rdt0[p_data$treatment=="own_feces"],pch=19,col="red3")
    
    #log version
    plot(S_log[,a],p_datalog$Diff_rdt6_rdt0,type="n",xlab="Surrogate",ylab="True",main=paste0("Logcounts","(Surrogate",a,")"))
    #experimental treatment
    points(S_log[p_datalog$treatment=="donorfeces",a],p_datalog$Diff_rdt6_rdt0[p_datalog$treatment=="donorfeces"],pch=19,col="green3")
    #control treatment
  points(S_log[p_datalog$treatment=="own_feces",a],p_datalog$Diff_rdt6_rdt0[p_datalog$treatment=="own_feces"],pch=19,col="red3")
  }
}
##experimental treatment == green
##control treatment == red

##Log appears to show some relationship not observed with the ordinary counts


## ----trueEndpoint_test---------------------------------------------------
#t test version(assumption of normalty is questionable)
t.test(Diff_rdt6_rdt0~treatment,data=p_data,alternative="two.sided",conf.int=T)
#wilcoxon
wilcox.test(Diff_rdt6_rdt0~treatment,data=p_data,alternative="two.sided",conf.int=T,
            conf.level=0.95,exact=F)

## ----surrogates_test,eval=FALSE------------------------------------------
## #test using raw counts
## surrogates <- data.frame(p_data %>% dplyr::select(-Diff_rdt6_rdt0,-age,-rdt0,-rdt6,-patient,-trt))
## #t-test parameters
## fc <- numeric(31)
## t_stat <- numeric(31)
## p.val <- numeric(31)
## #wilcoxon test parameters
## w_stat <- numeric(31)
## p.val2 <- numeric(31)
## 
## for(i in 2:31){
##   ##Using t-test
##  t_tests <- t.test(surrogates[,i]~surrogates[,1],alternative="two.sided")
##  #fold change
##  fc[i] <- t_tests$estimate[1] - t_tests$estimate[2]
##  # test statistic
##  t_stat[i] <- t_tests$statistic
##  #p_value
##  p.val[i] <- t_tests$p.value
##  ##Using Wilcoxon test
##   w_tests <- wilcox.exact(surrogates[,i]~surrogates[,1],alternative="two.sided")
##   w_stat[i] <- w_tests$statistic
##   p.val2[i] <- w_tests$p.value
## }
## 
## #remove the first 0's
## fc <- fc[-1]
## p.val <- p.val[-1]
## p.val2 <- p.val2[-1]
## t_stat <- t_stat[-1]
## w_stat <- w_stat[-1]
## 
## #Volcano plot 1(t-test)
## plot(x=fc,y=-log(p.val),main="Volcano Plot for t-test",pch=20,type="n")
## points(x=fc[p.val<0.05],y=-log(p.val)[p.val<0.05],col="red2",pch=20)
## points(x=fc[p.val>=0.05],y=-log(p.val)[p.val>=0.05],col="black",pch=20)
## 
## #Volcano plot 2(wilcoxon-test)
## plot(x=fc,y=-log(p.val2),main="Volcano Plot for wilcoxon test",type="n")
## points(x=fc[p.val2<0.05],y=-log(p.val2)[p.val2<0.05],col="red2",pch=20)
## points(x=fc[p.val2>=0.05],y=-log(p.val2)[p.val2>=0.05],col="red2",pch=20)
## 
## #adjusting the raw p-values(t-test)
## t.adj_pval <- mt.rawp2adjp(p.val,proc=c("BH"))
## kable(data.frame(Surrogate=t.adj_pval$index,t.adj_pval$adjp,fc),caption="T-Test")
## #
## w.adj_pval <- mt.rawp2adjp(p.val2,proc=c("BH"))
## kable(data.frame(Surrogate=w.adj_pval$index,w.adj_pval$adjp,fc),caption="W-Test")

## ------------------------------------------------------------------------
###test using the log of counts of the surrogates
surrogates_log <- data.frame(apply(surrogates[,-1],2,log))
surrogates_log$treatment <- surrogates$treatment
#t-test parameters
fc_log <- numeric(30)
tlog_stat <- numeric(30)
p.val_log <- numeric(30)
#wilcoxon test parameters
wlog_stat <- numeric(30)
plog.val2 <- numeric(30)

for(i in 1:30){
  ##Using t-test
 t_tests <- t.test(surrogates_log[,i]~surrogates_log[,31],alternative="two.sided")
 #fold change
 fc_log[i] <- t_tests$estimate[1] - t_tests$estimate[2]
 # test statistic
 tlog_stat[i] <- t_tests$statistic
 #p_value
 p.val_log[i] <- t_tests$p.value
 ##Using Wilcoxon test
  w_tests <- wilcox.exact(surrogates_log[,i]~surrogates_log[,31],alternative="two.sided")
  wlog_stat[i] <- w_tests$statistic
  plog.val2[i] <- w_tests$p.value
}

#Volcano plot 3(t-test)
plot(x=fc_log,y=-log(p.val_log),main="Volcano Plot for t-test(log counts)",pch=20,type="n")
points(x=fc_log[p.val_log<0.05],y=-log(p.val_log)[p.val_log<0.05],col="red2",pch=20)
text(x=fc_log[p.val_log<0.05],y=-log(p.val_log)[p.val_log<0.05],labels=c(1:30)[p.val_log<0.05])
points(x=fc_log[p.val_log>=0.05],y=-log(p.val_log)[p.val_log>=0.05],col="red2",pch=20)

#Volcano plot 4(wilcoxon-test)
plot(x=fc_log,y=-log(plog.val2),main="Volcano Plot for wilcoxon test(log counts)",pch=20,type="n")
points(x=fc_log[plog.val2<0.05],y=-log(plog.val2)[plog.val2<0.05],col="red2",pch=20)
text(x=fc_log[plog.val2<0.05],y=-log(plog.val2)[plog.val2<0.05],labels=c(1:30)[plog.val2<0.05])
points(x=fc_log[plog.val2>=0.05],y=-log(plog.val2)[plog.val2>=0.05],col="black",pch=20)

#adjusting the raw p-values
#t test
tlog.adj <- mt.rawp2adjp(p.val_log,proc=c("BH"))
kable(data.frame(Surrogate=tlog.adj$index,tlog.adj$adjp,fc),caption="T-test")

#wilcoxon
wlog.adj <- mt.rawp2adjp(plog.val2,proc=c("BH"))
kable(data.frame(Surrogate=wlog.adj$index,wlog.adj$adjp,fc),caption="W-test")

## ----jointmodelling------------------------------------------------------
### Joint Model 2 using log of counts
# true_endpoint
resVector <- p_data$Diff_rdt6_rdt0
#treatment
trt <- p_data$trt
#matrix for surrogates
#Slog_matrix <- t(as.matrix(S_log))
#JM2 <- fitJM(dat=Slog_matrix,responseVector=resVector,covariate=trt,methodMultTest="fdr")
#kable(JM2)
#topkGenes(JM2,subset_type="Effect and Correlation",ranking="Pearson",sigLevel=0.10)

####Having to program the joint model
pearsonADJ <- numeric(30)
pearsonADJ_interval <- vector("list",30)
pearsonUNADJ <- numeric(30)
s_trt_effect <- numeric(30)
spval_trt_effect <- numeric(30)
rho_pval <- numeric(30)

for(i in 1:30){
joint_data <- p_data %>% dplyr::select(Patients=patient,T=Diff_rdt6_rdt0,Treatment=trt) %>% mutate(S=S_log[,i]) %>%
  gather(key=Endpoint,value=Measure,-Treatment,-Patients)
joint_data <- data.frame(joint_data)
#true endpoint=1
joint_data$EP[joint_data$Endpoint=="S"] <- 1
#surrogate=2
joint_data$EP[joint_data$Endpoint=="T"] <- 2

#fitting the joint models with gls function (assuming unadjusted association is not 0)
jm <- gls(Measure~Treatment*as.factor(EP),correlation=corSymm(form=~EP|Patients),weights=varIdent(form=~1|EP),data=joint_data,method="ML")
#getting the variance covariance matrix
vcovjm <- getVarCov(jm)

# reduced joint model
jmR <- gls(Measure~Treatment*as.factor(EP),weights=varIdent(form=~1|EP),data=joint_data,method="ML")

#adjusted association
pearsonADJ[[i]] <- vcovjm[1,2]/sqrt(vcovjm[1,1]*vcovjm[2,2])
#confidence interval
Z_adj <- 0.5*log((1 + pearsonADJ[[i]])/(1 - pearsonADJ[[i]]))
upperZ_adj <- Z_adj + (qnorm(1 - 0.05/2) * sqrt(1/(16 - 3)))
lowerZ_adj <- Z_adj - (qnorm(1 - 0.05/2) * sqrt(1/(16 - 3)))
##backtransform
pearsonADJ_interval[[i]] <- round((exp(2*c(lowerZ_adj,upperZ_adj)) - 1)/(exp(2*c(lowerZ_adj,upperZ_adj)) + 1),2)

##testing if adjusted association is 0
rho_pval[i] <- anova(jm,jmR)["jmR","p-value"]

#unadjusted association
pearsonUNADJ[i] <- cor(joint_data$Measure[joint_data$EP==1],joint_data$Measure[joint_data$EP==2])
#treatment effect on surrogate
s_trt_effect[i] <- summary(jm)$tTable["Treatment","Value"]
#pvalue
spval_trt_effect[i] <- summary(jm)$tTable["Treatment","p-value"]
}

#pvalues adjusted for multiplicity(adjusted association)
rho_pvaladj <- mt.rawp2adjp(rho_pval,proc=c("BH"))
#re-order accordingly
rho_pvaladj <- data.frame(index=rho_pvaladj$index,BH=rho_pvaladj$adjp[,"BH"])
rho_pvaladj <- rho_pvaladj[order(rho_pvaladj$index),"BH"]

#treatment effect adjusted for multiplicity
spvaladj <- mt.rawp2adjp(spval_trt_effect,proc=c("BH"))
#re-order accordingly
spvaladj <- data.frame(index=spvaladj$index,BH=spvaladj$adjp[,"BH"])
spvaladj <- spvaladj[order(spvaladj$index),"BH"]

#extracting the confidence intervals
lower <- base::sapply(pearsonADJ_interval,"[",1)
upper <- base::sapply(pearsonADJ_interval,"[",2)

#putting things together
jm_results <- data.frame(UN_Assoc=pearsonUNADJ,ADJ_ASSOC=pearsonADJ,Lower_CI=lower,Upper_CI=upper,rhopval=rho_pval,rhopvaladj=rho_pvaladj,S_Trt=s_trt_effect,pval=spval_trt_effect,pvaladj=spvaladj)
#sorting and arranging by adjusted association
jm_results <- jm_results[order(jm_results$ADJ_ASSOC,decreasing=T),]
kable(jm_results)
print(xtable(jm_results),include.rownames=F)

## ----univariate----------------------------------------------------------
set.seed(123)
#T == True Endpoint, S == Surrogate
#CONTROL
T_control_endpoint <- p_datalog %>% filter(p_data$treatment=='own_feces') %>% dplyr::select(Diff_rdt6_rdt0)
S_control_endpoint <- p_datalog %>% filter(p_data$treatment=='own_feces') %>% dplyr::select(-patient,-age,-treatment,-rdt0,-rdt6,-Diff_rdt6_rdt0,-trt)

#Experimental
T_Exp_endpoint <- p_datalog %>% filter(p_data$treatment=='donorfeces') %>% dplyr::select(Diff_rdt6_rdt0)
S_Exp_endpoint <- p_datalog %>% filter(p_data$treatment=='donorfeces') %>% dplyr::select(-patient,-age,-treatment,-rdt0,-rdt6,-Diff_rdt6_rdt0,-trt)

#loop over all surrogates
icas <- numeric(30)
good <- vector("list",30)
pd_mat <- vector("list",30)
t0s0 <- numeric(30)
t0s0_interval <- vector("list",30)
t1s1 <- numeric(30)
t1s1_interval <- vector("list",30)

for(i in 1:30){
  #observed association under control
  t0s0[[i]] <- cor(T_control_endpoint,S_control_endpoint[,i])
  #confidence interval
  Z_t0s0 <- 0.5*log((1 + t0s0[[i]])/(1 - t0s0[[i]]))
  upperZ_t0s0 <- Z_t0s0 + (qnorm(1 - 0.05/2) * sqrt(1/(16 - 3)))
  lowerZ_t0s0 <- Z_t0s0 - (qnorm(1 - 0.05/2) * sqrt(1/(16 - 3)))
  t0s0_interval[[i]] <- round((exp(2*c(lowerZ_t0s0,upperZ_t0s0)) - 1)/(exp(2*c(lowerZ_t0s0,upperZ_t0s0)) + 1),2)
  
  #observed association under experimental
  t1s1[[i]] <- cor(T_Exp_endpoint,S_Exp_endpoint[,i])
  #confidence interval
  Z_t1s1 <- 0.5*log((1 + t1s1[[i]])/(1 - t1s1[[i]]))
  upperZ_t1s1 <- Z_t1s1 + (qnorm(1 - 0.05/2) * sqrt(1/(16 - 3)))
  lowerZ_t1s1 <- Z_t1s1 - (qnorm(1 - 0.05/2) * sqrt(1/(16 - 3)))
  t1s1_interval[[i]] <- round((exp(2*c(lowerZ_t1s1,upperZ_t1s1)) - 1)/(exp(2*c(lowerZ_t1s1,upperZ_t1s1)) + 1),2)
  
  #Computation of ICA
  mod_ica <- ICA.ContCont(T0S0=t0s0[[i]], T1S1=t1s1[[i]],T1T1=1, S0S0=1, S1S1=1,T0T1=seq(-1, 1, by=.1), 
                          T0S1=seq(-1, 1, by=.1), T1S0=seq(-1, 1, by=.1), S0S1=seq(-1, 1, by=.1))
  icas[i] <- mod_ica$ICA
  good[[i]] <- mod_ica$GoodSurr
  pd_mat[[i]] <- mod_ica$Pos.Def
}

#plots of ICA and delta(PMSE)
lower_ICA <- numeric(30)
upper_ICA <- numeric(30)

for(i in 1:10){
  par(mfrow=c(3,2))
  a <- pps[i]
  for(j in 1:3){
    a <- a+1
    if(a > 30) break
    hist(good[[a]]$ICA,probability=T,col="cyan3",xlab=expression(rho[Delta]),main=paste0("Surrogate",a))
    hist(good[[a]]$delta,probability=T,col="cyan3",xlab=expression(delta),main=paste0("Surrogate",a)) 
    lower_ICA[[a]] <- range(good[[a]]$ICA)[1]
    upper_ICA[[a]] <- range(good[[a]]$ICA)[2]
  }
}

#how many icas > 0.8
ica0.8 <- numeric(30)
for(k in 1:30){
ica0.8[[k]]  <- round((sum(good[[k]]$ICA > 0.8)/length(good[[k]]$ICA))*100,0)
}

###Putting things together in a table
lower_t0s0 <- sapply(t0s0_interval,"[",1)
upper_t0s0 <- sapply(t0s0_interval,"[",2)

lower_t1s1 <- sapply(t1s1_interval,"[",1)
upper_t1s1 <- sapply(t1s1_interval,"[",2)

ICA_table <- data.frame(Surrogates=1:30,rho0=t0s0,Lower_CI0=lower_t0s0,Upper_CI0=upper_t0s0,rho1=t1s1,Lower_CI1=lower_t1s1,Upper_CI1=upper_t1s1,ICA=icas,lower_range=lower_ICA,upper_range=upper_ICA)

#plotting before ordering
plot(x=1:30,y=icas,type="n",xlab="Surrogates",ylab=expression(rho[Delta]))
axis(side=1,at=1:30,labels=paste0("S",1:30))
axis(side=3,at=1:30,labels=ica0.8)
#median of the icas for each surrogate
icamed <- numeric(30)
for(i in 1:length(good)){
  icamed[[i]] <- median(good[[i]]$ICA)
}
points(x=1:30, y=icamed, pch=20,col="red")
segments(x0=1:30, y0=lower_ICA,y1=upper_ICA)
abline(h=0.5,lty=2,col="green3")
abline(h=-0.5,lty=2,col="green3")

kable(ICA_table[order(ICA_table$ICA,decreasing=T),])
#print(xtable(ICA_table[order(ICA_table$ICA,decreasing=T),]),include.rownames=F)

## ----MICA----------------------------------------------------------------
#variance-covariance matrix and correlation for the top three surrogates with #median above 0.5

#using the top 2 surrogates from the joint modelling approach(18,29)
s_rank <- c(18,6,15,17,19,24,29,14,5,22,26,4)

#surrogate 18
S18_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[18] )
S18_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[18] )

#surrogate 6
S6_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[6] )
S6_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[6] )

#surrogate 15
S15_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[15] )
S15_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[15] )

#surrogate 17
S17_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[17] )
S17_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[17] )

#surrogate 19
S19_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[19] )
S19_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[19] )

#surrogate 24
S24_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[24] )
S24_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[24] )

#surrogate 29
S29_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[29] )
S29_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[29] )

#surrogate 14
S14_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[14] )
S14_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[14] )

#surrogate 5
S5_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[5] )
S5_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[5] )

#surrogate 22
S22_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[22] )
S22_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[22] )

#surrogate 26
S26_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[26] )
S26_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[26] )

#surrogate 44
S4_0 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[4] )
S4_1 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[4] )

T0T1S0S1 <- list(T_control_endpoint,T_Exp_endpoint,S18_0,S18_1,S4_0,
                 S4_1,S15_0,S15_1,S17_0,S17_1,S19_0,S19_1,S24_0,S24_1,S29_0,
                 S29_1,S14_0,S14_1,S5_0,S5_1,S22_0,S22_1,S26_0,S26_1,S6_0,S6_1)

#creating the 8x8 matrix for sigma
sigma_matrix <- matrix(data=NA, ncol=26,nrow=26)
rownames(sigma_matrix) <- colnames(sigma_matrix) <- c("T_0","T_1","S18_0","S18_1","S4_0","S4_1","S15_0","S15_1","S17_0","S17_1",
  "S19_0","S19_1","S24_0","S24_1","S29_0","S29_1","S14_0","S14_1","S5_0",
  "S5_1","S22_0","S22_1","S26_0","S26_1","S6_0","S6_1")
#the variances
  diag(sigma_matrix) <- sapply(T0T1S0S1,var)
#other identifiable part of the matrix
for(i in 1:nrow(sigma_matrix)){
  for(j in 1:ncol(sigma_matrix)){
    if(i == j) {
      next }
    else if(i != j & 
            str_sub(rownames(sigma_matrix)[i],start=-1) ==
            str_sub(colnames(sigma_matrix)[j],start=-1)){
      
      sigma_matrix[i,j] <- sigma_matrix[j,i] <- cov(T0T1S0S1[[i]],
                                                    T0T1S0S1[[j]])
    }
  }
}


#based on the correlation matrix, surrogate 15 and 18 tend to agree 
#more than any other combination
#surrogate 15 and 18 
sigma_matrix2 <- sigma_matrix[c("T_0","T_1","S18_0","S18_1","S15_0","S15_1"),
                              c("T_0","T_1","S18_0","S18_1","S15_0","S15_1")]

gs1518 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix2,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs1518$R2_H,col="green2",xlab=expression(R[H]^2),main="S15 and S18")
#Adjusted MICA
hist(gs1518$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S15 and S18")

#removing surrogate 18 from the equation
sigma_matrix4 <- sigma_matrix[c("T_0","T_1","S6_0","S6_1","S15_0","S15_1"),
                              c("T_0","T_1","S6_0","S6_1","S15_0","S15_1")]

gs615 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix4,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs615$R2_H,col="green2",xlab=expression(R[H]^2),main="S6 and S15")
#Adjusted MICA
hist(gs615$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S6 and S15")

###top 2 from joint modelling approach
#surrogate 18 and 29
sigma_jm <- sigma_matrix[c("T_0","T_1","S18_0","S18_1","S29_0","S29_1"),
                              c("T_0","T_1","S18_0","S18_1","S29_0","S29_1")]
#mica
gs1829 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_jm,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs1829$R2_H,col="green2",xlab=expression(R[H]^2),main="S18 and S29")
#Adjusted MICA
hist(gs1829$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S18 and S29")

#surrogate 18 and 4
sigma_184 <- sigma_matrix[c("T_0","T_1","S18_0","S18_1","S4_0","S4_1"),
                              c("T_0","T_1","S18_0","S18_1","S4_0","S4_1")]
#mica
gs184 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_184,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs184$R2_H,col="green2",xlab=expression(R[H]^2),main="S18 and S4")
#Adjusted MICA
hist(gs184$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S18 and S4")

#surrogate 18 and 22
sigma_matrix1822 <- sigma_matrix[c("T_0","T_1","S18_0","S18_1","S22_0","S22_1"),c("T_0","T_1","S18_0","S18_1","S22_0","S22_1")]

gs1822 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix1822,
                              Show.Progress=T,Seed=1545)
#plotting things
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs1822$R2_H,col="green2",xlab=expression(R[H]^2),main="S18 and S22")
#Adjusted MICA
hist(gs1822$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S18 and S22")

#surrogate 18 and 6
sigma_matrix186 <- sigma_matrix[c("T_0","T_1","S18_0","S18_1","S6_0","S6_1"),c("T_0","T_1","S18_0","S18_1","S6_0","S6_1")]

gs186 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix186,
                              Show.Progress=T,Seed=1545)
#plotting things
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs186$R2_H,col="green2",xlab=expression(R[H]^2),main="S18 and S6")
#Adjusted MICA
hist(gs186$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S18 and S6")
#S4 and S15
sigma_matrix415 <- sigma_matrix[c("T_0","T_1","S4_0","S4_1","S15_0","S15_1"),c("T_0","T_1","S4_0","S4_1","S15_0","S15_1")]

gs415 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix415,
                              Show.Progress=T,Seed=123)


#####All bivariate causal inference approach
b1 <- c("S18_0","S18_1","S4_0","S4_1","S15_0","S15_1","S17_0","S17_1",
  "S19_0","S19_1","S24_0","S24_1","S29_0","S29_1","S14_0","S14_1","S5_0",
  "S5_1","S22_0","S22_1","S26_0","S26_1","S6_0","S6_1")
b2 <- seq(1,24,by=2)
med_R2H <- c()
lower_R2H <- c()
upper_R2H <- c()

med_R2AH <- c()
lower_R2AH <- c()
upper_R2AH <- c()
s_names <- c()

for(i in 1:length(b2)){
  if(i == length(b2)) break
  for(j in i:length(b2)){
    if(j == length(b2)) break
    ssmatrix <- sigma_matrix[c("T_0","T_1",b1[b2[i]],b1[b2[i]+1],
                              b1[b2[j+1]],b1[b2[j+1]+1]),
                            c("T_0","T_1",b1[b2[i]],b1[b2[i]+1],
                              b1[b2[j+1]],b1[b2[j+1]+1])]
  gs <- ICA.ContCont.MultS(M=100,N=16,Sigma=ssmatrix,
                              Show.Progress=F,Seed=1545,
                              G=seq(from=-1, to=1, by = .01))
  med_R2H <- c(med_R2H,median(gs$R2_H))
  lower_R2H <- c(lower_R2H,range(gs$R2_H)[1])
  upper_R2H <- c(upper_R2H,range(gs$R2_H)[2])
  #
  med_R2AH <- c(med_R2AH,median(gs$Corr.R2_H))
  lower_R2AH <- c(lower_R2AH,range(gs$Corr.R2_H)[1])
  upper_R2AH <- c(upper_R2AH,range(gs$Corr.R2_H)[2])
  #plotting things
  par(mfrow=c(1,2))
  #unadjusted MICA
  hist(gs$R2_H,col="green2",xlab=expression(R[H]^2),
       main="")
  #Adjusted MICA
  hist(gs$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="")
  s_names <- c(s_names,paste(b1[b2[i]],"and",b1[b2[j+1]]))
  print(paste(b1[b2[i]],"and",b1[b2[j+1]]))
  }
}

####Putting it all together
MICA_results <- data.frame(MMICA=med_R2H,lower_MMICA=lower_R2H,
                           upper_MMICA=upper_R2H,MAMICA=med_R2AH,
                           lower_MAMICA=lower_R2AH,upper_MAMICA=upper_R2AH,
                           S=gsub("_0","",s_names))

MICA_results <- MICA_results[order(MICA_results$MMICA,decreasing = T),]

#using the alternative approach
#gs618_alt <- ICA.ContCont.MultS_alt(M=500,N=16,Sigma=sigma_matrix3,
#                                    Seed=1545,Show.Progress=T,
#                                    Model="Delta_T ~ Delta_S1 + Delta_S2")

#mulrivariate causal association (top 3 surrogates from ICA)
gs61518 <- ICA.ContCont.MultS(M=100,N=16,Sigma=sigma_matrix,
                              Show.Progress=T,Seed=1545,
                              G=seq(from=-1, to=1, by = .01))

gs61518_alt <- ICA.ContCont.MultS_alt(M=500,N=16,Sigma=sigma_matrix,
                                    Seed=1545,Show.Progress=T,
                                    Model="Delta_T ~ Delta_S1 + 
                                    Delta_S2 + Delta_S3")

#plotting the uncertainties
lower_range <- c(range(gs1518$R2_H)[1],range(gs1829$R2_H)[1],
                 range(gs615$R2_H)[1])

upper_range <- c(range(gs1518$R2_H)[2],range(gs1829$R2_H)[2],
                 range(gs615$R2_H)[2])

med_com <- c(median(gs1518$R2_H),median(gs1829$R2_H)[1],
            median(gs615$R2_H))

#plotting them together
plot(x=1:3,y=med_com,xlab="surrogates",ylab=expression(R[H]^2),type="n",
     axes=F,ylim=c(0,1))
axis(side=2,at=c(0,0.25,0.5,0.75,1.0))
axis(side=1,at=1:3,labels=c("S15+S18","S18+S29","S6+S15"))

points(x=1:3,y=med_com,pch=20)
segments(x0=1:3, y0=lower_range,y1=upper_range)
abline(h=0.5,lty=2,col="green3")



## ------------------------------------------------------------------------
mjoint_MAA <- data.frame()
mjoint_AMAA <- data.frame()
b <- length(s_rank)-1
for(i in 1:b){
  a <- i+1
  for(j in a:length(s_rank)){
    mjdata <- data.frame(Patients=p_data$patient,T=resVector, 
                         Z=trt,S1=S_log[,s_rank[i]],S2=S_log[,s_rank[j]])
    mjdata_long <- mjdata %>% 
      tidyr::gather(key=Endpoint,value=Measure,-Z,-Patients)
    mjdata_long$EP <- NULL
    mjdata_long$EP[mjdata_long$Endpoint=="T"] <- 1
    mjdata_long$EP[mjdata_long$Endpoint=="S1"] <- 2
    mjdata_long$EP[mjdata_long$Endpoint=="S2"] <- 3
    #joint modelling
    mmodel <- gls(Measure~Z*as.factor(EP),correlation=corSymm(form = ~ EP|
                                                                Patients),
                  weights = varIdent(form=~1|EP), data = mjdata_long, 
                  method = "ML")
    #computing adjusted association
  maa <- data.frame(AA.MultS(getVarCov(mmodel),N=16,Alpha=0.05)$Gamma.Delta)
  maa$S <- paste0(s_rank[i],",",s_rank[j])
  amaa <- data.frame(AA.MultS(getVarCov(mmodel),N=16,
                              Alpha = 0.05)$Corr.Gamma.Delta)
  amaa$S <- paste0(s_rank[i],",",s_rank[j])
   mjoint_MAA <- rbind(mjoint_MAA,maa)
   mjoint_AMAA <- rbind(mjoint_AMAA,amaa)
  }
}
mjoint_MAA <- mjoint_MAA[order(mjoint_MAA$Multivariate.AA,decreasing = T),]
mjoint_AMAA <- mjoint_AMAA[order(mjoint_AMAA$Adjusted.multivariate.AA,
                                 decreasing = T),]





####################
#c(var(T_control_endpoint),
                        # var(T_Exp_endpoint), 
                        # var(S18_0),
                        # var(S18_1),
                        # var(S6_0),
                        # var(S6_1),
                        # var(S15_0),
                        # var(S15_1),
                        # var(S17_0),
                        # var(S17_1),
                        # var(S19_0),
                        # var(S19_1),
                        # var(S24_0),
                        # var(S24_1),
                        # var(S29_0),
                        # var(S29_1),
                        # var(S14_0),
                        # var(S14_1),
                        # var(S5_0),
                        # var(S5_1),
                        # var(S22_0),
                        # var(S22_1),
                        # var(S26_0),
                        # var(S26_1),
                        # var(S4_0),
                        # var(S4_1))
#
#T0, S18
# sigma_matrix[1,3] <- sigma_matrix[3,1] <- cov(T_control_endpoint,S01)
# sigma_matrix[1,5] <- sigma_matrix[5,1] <- cov(T_control_endpoint,S02)
# sigma_matrix[1,7] <- sigma_matrix[7,1] <- cov(T_control_endpoint,S03)
# #T1
# sigma_matrix[2,4] <- sigma_matrix[4,2] <- cov(T_Exp_endpoint,S11)
# sigma_matrix[2,6] <- sigma_matrix[6,2] <- cov(T_Exp_endpoint,S12)
# sigma_matrix[2,8] <- sigma_matrix[8,2] <- cov(T_Exp_endpoint,S13)
# #Surrogate 1 control
# sigma_matrix[3,5] <- sigma_matrix[5,3] <- cov(S01,S02)
# sigma_matrix[3,7] <- sigma_matrix[7,3] <- cov(S01,S02)
# #surrogate 1 experimental
# sigma_matrix[4,6] <- sigma_matrix[6,4] <- cov(S11,S12)
# sigma_matrix[4,8] <- sigma_matrix[8,4] <- cov(S11,S13)
# #surrogate 2 control
# sigma_matrix[5,7] <- sigma_matrix[7,5] <- cov(S02,S03)
# #surrogate 2 experimental
# sigma_matrix[6,8] <- sigma_matrix[8,6] <- cov(S12,S13)



