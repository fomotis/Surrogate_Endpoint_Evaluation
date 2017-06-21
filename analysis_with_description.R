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

#surrogate 6
S01 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[6] )
S11 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[6] )

#surrogate 15
S02 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[15] )
S12 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[15] )

#surrogate 18
S03 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[18] )
S13 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[18] )

#surrogate 29
S04 <- p_datalog %>% filter(treatment=="own_feces") %>% dplyr::select( names(S_log)[29] )
S14 <- p_datalog %>% filter(treatment=="donorfeces") %>% dplyr::select( names(S_log)[29] )

#creating the 8x8 matrix for sigma
sigma_matrix <- matrix(data=NA, ncol=8,nrow=8)
rownames(sigma_matrix) <- colnames(sigma_matrix) <- c("T_0","T_1","S6_0","S6_1","S15_0","S15_1","S18_0","S18_1")
#the variances
diag(sigma_matrix) <- c(var(T_control_endpoint),
                        var(T_Exp_endpoint), 
                        var(S01),
                        var(S11),
                        var(S02),
                        var(S12),
                        var(S03),
                        var(S13))
#other identifiable part of the matrix
#T0
sigma_matrix[1,3] <- sigma_matrix[3,1] <- cov(T_control_endpoint,S01)
sigma_matrix[1,5] <- sigma_matrix[5,1] <- cov(T_control_endpoint,S02)
sigma_matrix[1,7] <- sigma_matrix[7,1] <- cov(T_control_endpoint,S03)
#T1
sigma_matrix[2,4] <- sigma_matrix[4,2] <- cov(T_Exp_endpoint,S11)
sigma_matrix[2,6] <- sigma_matrix[6,2] <- cov(T_Exp_endpoint,S12)
sigma_matrix[2,8] <- sigma_matrix[8,2] <- cov(T_Exp_endpoint,S13)
#Surrogate 1 control
sigma_matrix[3,5] <- sigma_matrix[5,3] <- cov(S01,S02)
sigma_matrix[3,7] <- sigma_matrix[7,3] <- cov(S01,S02)
#surrogate 1 experimental
sigma_matrix[4,6] <- sigma_matrix[6,4] <- cov(S11,S12)
sigma_matrix[4,8] <- sigma_matrix[8,4] <- cov(S11,S13)
#surrogate 2 control
sigma_matrix[5,7] <- sigma_matrix[7,5] <- cov(S02,S03)
#surrogate 2 experimental
sigma_matrix[6,8] <- sigma_matrix[8,6] <- cov(S12,S13)

#based on the correlation matrix, surrogate 15 and 18 tend to agree 
#more than any other combination
#removing surrogate 6 from the equation
sigma_matrix2 <- sigma_matrix[-c(3,4),-c(3,4)]
gs1518 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix2,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs1518$R2_H,col="green2",xlab=expression(R[H]^2),main="S15 and S18")
#Adjusted MICA
hist(gs1518$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S15 and S18")

#removing surrogate 18 from the equation
sigma_matrix4 <- sigma_matrix[-c(7,8),-c(7,8)]
gs615 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix4,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs615$R2_H,col="green2",xlab=expression(R[H]^2),main="S6 and S15")
#Adjusted MICA
hist(gs615$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S6 and S15")

###top 2 from joint modelling approach
sigma_jm <- matrix(NA,ncol=6,nrow=6)
rownames(sigma_jm) <- colnames(sigma_jm) <- c("T_0","T_1","S18_0","S18_1","S29_0","S29_1")
diag(sigma_jm) <- c(var(T_control_endpoint),
                        var(T_Exp_endpoint), 
                        var(S03),
                        var(S13),
                        var(S04),
                        var(S14))

#other identifiable part of the matrix
#T0
sigma_jm[1,3] <- sigma_jm[3,1] <- cov(T_control_endpoint,S03)
sigma_jm[1,5] <- sigma_jm[5,1] <- cov(T_control_endpoint,S04)
#T1
sigma_jm[2,4] <- sigma_jm[4,2] <- cov(T_Exp_endpoint,S13)
sigma_jm[2,6] <- sigma_jm[6,2] <- cov(T_Exp_endpoint,S14)
#
sigma_jm[3,5] <- sigma_jm[5,3] <- cov(S03,S04)
sigma_jm[4,6] <- sigma_jm[6,4] <- cov(S13,S14)
#mica
gs1829 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_jm,
                              Show.Progress=T,Seed=1545)
par(mfrow=c(1,2))
#unadjusted MICA
hist(gs1829$R2_H,col="green2",xlab=expression(R[H]^2),main="S18 and S29")
#Adjusted MICA
hist(gs1829$Corr.R2_H,col="green2",xlab=expression(R[H_adj]^2),main="S18 and S29")


#plotting the uncertainties
lower_range <- c(range(gs1518$R2_H)[1],range(gs1829$R2_H)[1],
                 range(gs615$R2_H)[1])

upper_range <- c(range(gs1518$R2_H)[2],range(gs1829$R2_H)[2],
                 range(gs615$R2_H)[2])

med_com <- c(median(gs1518$R2_H),median(gs1829$R2_H)[1],
            median(gs615$R2_H))


####not yet finished
#removing surrogate 15 from the equation(top 2 from ICA)
sigma_matrix3 <- sigma_matrix[-c(5,6),-c(5,6)]
gs618 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix3,
                              Show.Progress=T,Seed=1545)

#mulrivariate causal association (top 3 surrogates from ICA)
gs61518 <- ICA.ContCont.MultS(M=500,N=16,Sigma=sigma_matrix,
                              Show.Progress=T,Seed=1545)




# msurrogate <- bind_cols( p_datalog %>% dplyr::select(patient,Diff_rdt6_rdt0,treatment), S_log %>% dplyr::select( names(S_log)[c(6,15,18)] ))
# ###control
# msurrogate_control <- msurrogate %>% dplyr::filter(treatment=="donorfeces")
# ###Experimental
# msurrogate_experiment <- msurrogate %>% dplyr::filter(treatment=="own_feces")
#cmatrix1 <- cor(p_datalog[,6:ncol(p_datalog)])
#variance-covariance matrix by treatment
#donor_feces
#dfeces <- p_datalog %>%  filter(treatment=="donorfeces") %>% select(-patient,-age,-rdt0,-rdt6,-treatment) 
#renaming dfeces columns
#names(dfeces) <- paste0("df_",names(dfeces))
#ownfeces
#ofeces <- p_datalog %>% filter(treatment=="own_feces") %>%  select(-patient,-age,-rdt0,-rdt6,-treatment)
#renaming ofeces columns
#names(ofeces) <- paste0("of_",names(ofeces))
#variance_covariance matrix


