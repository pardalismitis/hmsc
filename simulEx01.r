##########################################################################################
#
# THIS SCRIPT FITS A JSDM WITH RANDOM EFFECTS AT TWO LEVELS
#
##########################################################################################

#=========================================================================================
# SECTION 0 - PRELIMINARIES
#=========================================================================================

### Fetching the HMSC package from library and ensuring reproducibility of the results
#============================================
rm(list = ls())
library(HMSC)
set.seed(1)

### Set working directory
#============================================
setwd("C:/Users/parda/Dropbox/SCRIPTS/hmsc-data_0/HMSC-data")

### Load the simulated data
#============================================
# From .csv-files
### Community matrix
Y <- apply(read.csv("simulated/Y.csv"),2,as.numeric)
### Covariates
X <- read.csv("simulated/X.csv")
### Random effects
Pi <- read.csv("simulated/Pi.csv")
### Covert all columns of Pi to a factor
Pi <- data.frame(apply(Pi,2,as.factor))

### Covert all daat to HMSCdata format
#============================================
simulEx1data <- as.HMSCdata(Y=Y, X=X, Random=Pi, interceptX=FALSE, scaleX=FALSE)

# Or ready made data objects (which we will use now on)
data("simulEx1")



#=========================================================================================
# SECTION 1 - MODEL FITTING
#=========================================================================================

### In case one wants to define the priors or a specific set of parameters for the MCMC algorithm
simulEx1prior <- as.HMSCprior(simulEx1data)
simulEx1param <- as.HMSCparam(simulEx1data, simulEx1prior)

### True parameter values
#============================================
# For this example, we know the "true parameters" as the data analyzed here
# has been re generated by the HMSC model itself

data("simulParamEx1")

### Build the model
#============================================
# The scaling is done automatically when constructing the HMSC object 
# with the scaleX = TRUE/FALSE and scaleTr = TRUE/FALSE options

model<-hmsc(simulEx1,family="probit",niter=10000,nburn=1000,thin=10)

### Save the model
#============================================
save(model, file = "case studies/simulated example 1/model.RData")




#=========================================================================================
# SECTION 2 - PRODUCING MODEL OUTPUTS
#=========================================================================================

### Loading the fitted model from file
#============================================
load(file = "case studies/simulated example 1/model.RData")

### Constructing MCMC trace/mixing plots
#============================================

### Mixing object
mixing <- as.mcmc(model, parameters = "paramX")

### Draw trace and density plots for all combination of parameters
plot(mixing)

### Constructing posterior summaries
#============================================

### Convert the mixing object to a matrix
mixingDF <- as.data.frame(mixing)

### Draw beanplots
#install.packages("beanplot")
library(beanplot)
par(mar = c(7, 4, 4, 2))
beanplot(mixingDF, las = 2)

### Draw boxplot for each parameters
par(mar = c(7, 4, 4, 2))
boxplot(mixingDF, las = 2)

### True values
truth <- as.vector(simulParamEx1$param$paramX)
### Average
average <- apply(model$results$estimation$paramX, 1:2, mean)
### 95% confidence intervals
CI.025 <- apply(model$results$estimation$paramX, 1:2, quantile,
                probs = 0.025)
CI.975 <- apply(model$results$estimation$paramX, 1:2, quantile, 
                probs = 0.975)
CI <- cbind(as.vector(CI.025), as.vector(CI.975))

### Draw confidence interval plots
plot(0, 0, xlim = c(1, nrow(CI)), ylim = range(CI, truth), type = "n", 
     xlab = "", ylab = "", main="paramX")
abline(h = 0,col = "grey")
arrows(x0 = 1:nrow(CI), x1 = 1:nrow(CI), y0 = CI[, 1], y1 = CI[, 2], 
       code = 3, angle = 90, length = 0.05)
points(1:nrow(CI), average, pch = 15, cex = 1.5)
points(1:nrow(CI), truth, col = "red", pch = 19)

### Summary table
paramXCITable <- cbind(unlist(as.data.frame(average)),
                       unlist(as.data.frame(CI.025)), 
                       unlist(as.data.frame(CI.975)))
colnames(paramXCITable) <- c("paramX", "lowerCI", "upperCI")
rownames(paramXCITable) <- paste(rep(colnames(average), 
                                 each = nrow(average)), "_", 
                                 rep(rownames(average), 
                            	 ncol(average)), sep="")
write.csv(paramXCITable, file='case studies/simulated example 1/beta.csv')

### Constructing variation partitioning
#============================================
variationPart <- variPart(model, c(rep("climate",2),"habitat"))

par(mar=c(3,3,5,1))
barplot(t(variationPart), las=2, cex.names=0.75, cex.axis=0.75,
		legend.text=paste(colnames(variationPart)," ",signif(100*colMeans(variationPart),2),"%",sep=""), 
		args.legend=list(y=1.2, xjust=1, horiz=F, bty="n",cex=0.75))


### Plotting association networks
#============================================

### Plot random effect estimation through correlation matrix
corMat <- corRandomEff(model,cor=FALSE)

### Sampling units level
#--------------------------------------------
### Isolate the values of interest
ltri <- lower.tri(apply(corMat[, , , 1], 1:2, quantile, probs = 0.025), diag=TRUE)

### True values
truth <- as.vector(tcrossprod(simulParamEx1$param$paramLatent[[1]])[ltri])

### Average
average <- as.vector(apply(corMat[, , , 1], 1:2, mean)[ltri])

### 95% confidence intervals
corMat.025 <- as.vector(apply(corMat[, , , 1], 1:2, quantile, 
                              probs = 0.025)[ltri])
corMat.975 <- as.vector(apply(corMat[, , , 1], 1:2, quantile, 
                              probs=0.975)[ltri])
CI <- cbind(corMat.025, corMat.975)

### Plot the results
plot(0, 0, xlim = c(1, nrow(CI)), ylim = range(CI, truth), type = "n", 
     xlab = "", ylab = "", main = "cov(paramLatent[[1, 1]])")
abline(h = 0, col = "grey")
arrows(x0 = 1:nrow(CI), x1 = 1:nrow(CI), y0 = CI[, 1], y1 = CI[, 2], 
       code = 3, angle = 90, length = 0.05)
points(1:nrow(CI), average, pch = 15,cex = 1.5)
points(1:nrow(CI), truth, col = "red", pch=19)

### Mixing object
mixing <- as.mcmc(model, parameters = "paramLatent")

### Draw trace and density plots for all combination of parameters
plot(mixing[[1]])

### Convert the mixing object to a matrix
mixingDF <- as.data.frame(mixing[[1]])

### Draw boxplot for each parameters
par(mar=c(7, 4, 4, 2))
boxplot(mixingDF, las = 2)

### Draw beanplots
par(mar = c(7, 4, 4, 2))
beanplot(mixingDF, las = 2)

### Draw estimated correlation matrix
#install.packages("corrplot")
library(corrplot)
corMat <- corRandomEff(model, cor = TRUE)
averageCor <- apply(corMat[, , , 1], 1:2, mean)
corrplot(averageCor, method = "color", 
         col = colorRampPalette(c("blue", "white", "red"))(200))

### Draw chord diagram
#install.packages("circlize")
library(circlize)
corMat <- corRandomEff(model, cor = TRUE)
averageCor <- apply(corMat[, , , 1], 1:2, mean)
colMat <- matrix(NA, nrow = nrow(averageCor), ncol = ncol(averageCor))
colMat[which(averageCor > 0.4, arr.ind = TRUE)] <- "red"
colMat[which(averageCor < -0.4, arr.ind = TRUE)] <- "blue"
chordDiagram(averageCor, symmetric = TRUE, 
             annotationTrack = c("name", "grid"), 
             grid.col = "grey",col=colMat)

### Plot level
#--------------------------------------------
### Isolate the values of interest
ltri <- lower.tri(apply(corMat[, , , 2], 1:2, quantile, probs=0.025),
                  diag=TRUE)

### True values
truth <- as.vector(tcrossprod(simulParamEx1$param$paramLatent[[2]])[ltri])
### Average
average <- as.vector(apply(corMat[, , , 2], 1:2, mean)[ltri])
### 95% confidence intervals
corMat.025 <- as.vector(apply(corMat[, , , 2], 1:2, quantile, 
                              probs = 0.025)[ltri])
corMat.975 <- as.vector(apply(corMat[, , , 2], 1:2, quantile, 
                              probs = 0.975)[ltri])
CI <- cbind(corMat.025, corMat.975)

### Plot the results
plot(0, 0, xlim = c(1, nrow(CI)), ylim = range(CI, truth), type = "n",
     xlab = "", main = "cov(paramLatent[[1,2]])")
abline(h = 0, col = "grey")
arrows(x0 = 1:nrow(CI), x1 = 1:nrow(CI), y0 = CI[, 1], y1 = CI[, 2], 
       code = 3, angle = 90, length = 0.05)
points(1:nrow(CI), average, pch = 15, cex = 1.5)
points(1:nrow(CI), truth, col = "red", pch = 19)

### Mixing object
mixing <- as.mcmc(model, parameters = "paramLatent")

### Draw trace and density plots for all combination of paramters
plot(mixing[[2]])

### Convert the mixing object to a matrix
mixingDF <- as.data.frame(mixing[[2]])

### Draw boxplot for each parameters
par(mar = c(7, 4, 4, 2))
boxplot(mixingDF, las = 2)

### Draw beanplots
library(beanplot)
par(mar = c(7, 4, 4, 2))
beanplot(mixingDF, las = 2)

### Draw estimated correlation matrix
library(corrplot)
corMat <- corRandomEff(model, cor = TRUE)
averageCor <- apply(corMat[, , , 2], 1:2, mean)
corrplot(averageCor, method = "color", 
         col = colorRampPalette(c("blue", "white", "red"))(200))

### Draw chord diagram
library(circlize)
corMat <- corRandomEff(model, cor = TRUE)
averageCor <- apply(corMat[, , , 2], 1:2, mean)
colMat <- matrix(NA, nrow = nrow(averageCor), ncol = ncol(averageCor))
colMat[which(averageCor>0.4, arr.ind = TRUE)] <- "red"
colMat[which(averageCor< -0.4, arr.ind = TRUE)] <- "blue"
chordDiagram(averageCor, symmetric = TRUE, 
             annotationTrack = c("name", "grid"), grid.col = "grey", 
             col = colMat)

### Constructing a plot with R2-values
#============================================
Ymean <- apply(model$data$Y, 2, mean)
R2 <- Rsquared(model, averageSp=FALSE)
plot(Ymean, R2, pch=19, main=paste('Mean R2 value over species',mean(Ymean)))

### Sampling the posterior distribution
#============================================
# For a particular set of parameter, this given directly by the hmsc function
# For example for the beta (paramX)
model$results$estimation$paramX
# For the full joint probability distribution
fullPost <- jposterior(model)

### Generating predictions for training data
#============================================
predTrain <- predict(model)

### Generating predictions for new units outside training data
#============================================

### Simulating "validation" data
X <- matrix(nrow = 10, ncol = 3)
colnames(X) <- colnames(simulEx1$X)
X[, 1] <- 1
X[, 2] <- rnorm(10)
X[, 3] <- rnorm(10)

RandomSel <- sample(200, 10)
Random <- simulEx1$Random[RandomSel, ]
for(i in 1:ncol(Random)){
	Random[, i] <- as.factor(as.character(Random[, i]))
}
colnames(Random) <- colnames(simulEx1$Random)
dataVal <- as.HMSCdata(X = X, Random = Random)

### Prediction for a new set of values
predVal <- predict(model, dataVal)


##########################################################################################
##########################################################################################
##########################################################################################
