library(Hmisc)
library(zoo)
library(plyr)
library(mlbench)
library(e1071)
library(randomForest)

dirpath <- "~/rodiniaSched/"
setwd(paste(dirpath, sep = ""))

source("./R-code/include/common.R")
source("./R-code/include/sharedFunctions.R")

set.seed(5)

# tempTime <- matrix()
# for(i in 1:2){
#   temp <- read.csv(paste("./data/backprop-GPU-", i, ".csv", sep = ""), header = FALSE)
#   tempTime <- cbind(temp[grep("adjust", temp$V2),]["V4"], tempTime)
# }
#
# tempTime$tempTime <- NULL
# duration <- rowMeans(tempTime)


features <-  c(
    "multiprocessor_activity" ,
    "elapsed_cycles_sm",
    "device_memory_read_transactions",
    "global_store_transactions",
    "issued_control.flow_instructions",
    
    "load.store_instructions",
    "executed_load.store_instructions",
    "active_cycles",
    "misc_instructions",
    "control.flow_instructions"
)


createCounter <- function(value) {function(i) {value <<- value + i}}

predictFeatures <- function(trainingData, testingData) {
    # 
    # trainingData <- trainingData[!(names(trainingData) %in% features)]
    # testingData  <- testingData[!(names(testingData) %in% features)]
    # 
    # trainingData$duration <-NULL
    # testingData$duration <- NULL
    for (i in features) {
        counter <- createCounter(0)
        rss <- matrix(nrow = 10, ncol = 3)
    
        trainFeatures <- data.frame(trainingData[names(trainingData) == i],  trainingData[12:length(trainingData)])
        testFeatures <- data.frame(testingData[c(12:length(testingData))])
    
        png(filename = paste("./images/fitModels/",names(kernelsDict[kernel]), "-", names(trainFeatures[i]), ".png", sep = ""), 
            width = 1200, height = 800)
        par(family = "Times", mfrow = c(2, 5))
        
        for (resultY in c("", "log2")) {
            for (FeaturesX in c("", "log2",  "exp", "sqrt", "poly")) {
                count <- counter(1)
                
                fit <- lm(as.formula(
                    paste(resultY, "(", names(trainFeatures[i]),  ifelse(resultY == "log2", "+ 0.0000000001", ""),") ~",
                       paste(FeaturesX, "(",ifelse(FeaturesX == "exp", "normalizeMax(",""),  
                         colnames(trainFeatures[!names(trainFeatures) == i]), 
                         ifelse(FeaturesX == "poly", ",3,raw = TRUE",""),
                         ifelse(FeaturesX == "log2", "+ 0.0000000001", ""),
                         ifelse(FeaturesX == "exp", ")", "") , ")",
                        collapse = " + " ))), data =  trainFeatures)
                
                rss[count, 1] <- summary(fit)$r.squared
                rss[count, 2] <- resultY
                rss[count, 3] <- FeaturesX
                
                qqnorm(
                    residuals(fit),
                    ylab = "Studentized Residual",
                    xlab = "t Quantiles",
                    main = paste(" Model: ", resultY, "(y) = ", FeaturesX,"X_i", sep = ""),
                    cex.lab = 2,
                    cex.main = 2,
                    cex = 1.5,
                    cex.axis = 2
                )
                qqline(residuals(fit), col = 2, lwd = 5)
            }
        }
        dev.off()
        rss
        
        key <- which(rss[, 1] == max(rss[as.numeric(rss[,1]) < 1, 1]))[1]
        
        featurePredicted <- predict(lm(as.formula(
            paste(rss[key,2], "(", names(trainFeatures[i]),  ifelse(rss[key,2] == "log2", "+ 0.0000000001", ""),") ~",
                  paste(rss[key,3], "(",ifelse(rss[key,3] == "exp", "normalizeMax(",""),  
                        colnames(trainFeatures[!names(trainFeatures) == i]), 
                        ifelse(rss[key,3] == "poly", ",3,raw = TRUE",""),
                        ifelse(rss[key,3] == "log2", "+ 0.0000000001", ""),
                        ifelse(rss[key,3] == "exp", ")", "") , ")",
                        collapse = " + " ))), data =  trainFeatures), testFeatures)
        
        # timeKernel <- predict(randomForest(names(trainFeatures[i])~., data =  trainingData), testingData[,-1])
        
       if (rss[key, 2] == "log2")
           featurePredicted <- 2^(featurePredicted) - 0.0000000001 
        
        png( filename = paste("./images/fakeFeatures/", names(kernelsDict[kernel]),"-", names(trainFeatures[i]), ".png", sep = ""),
             width = 1200, height = 800)
        par(mfrow = c(1, 3), xpd= FALSE)
        plot(testingData[,names(testingData) == i]~ featurePredicted, cex.lab = 1.5, 
             cex.axis=2, xlab="Mesaured", ylab="Predited", cex=1.5)
        # abline(testingData[,names(testingData) == i]~ featurePredicted)
        boxplot(testingData[names(testingData) == i] / featurePredicted,
                ylab = "Accuracy  Measured/Predicted",
                cex = 2, cex.axis=2, cex.lab = 1.5, cex.main=1.75, main = paste(kernelsDict[kernel], " | ", 
              names(kernelsDict[kernel]), " | ", names(trainingData[names(trainingData) == i]), sep = "" ))
        # title(paste(kernel, "|  ", rss[key,2], "(Y) = ", rss[key,3], "(X)"), outer=TRUE)
        plot(testingData[,names(testingData) == i],
             ylim = c(min(featurePredicted, testingData[,names(testingData) == i]), 
                      max(featurePredicted, testingData[,names(testingData) == i])),
             col = "blue",
             ylab = names(trainingData[names(trainingData) == i]),
             cex = 2,cex.axis=2, cex.lab = 1.5,
             main = paste("Model=", rss[key, 2], "(y) = ", rss[key, 3], "(X_i)", sep = ""))
        legend("bottomleft", legend = c("Measured", "Predicted"), col = c("blue", "red"),
               lwd = 2, cex = 2 )
        points(featurePredicted, col = "red")
        
        dev.off()
    }
}


for (kernel in 4) {
    for (gpu in 2) {
        #NoGPU){
        temp <- data.frame(read.csv(paste("./datasets/", names(kernelsDict[kernel]), "-", gpus[gpu, "gpu_name"], ".csv", sep = "")))
        tempNvprof <- temp[, which(names(temp) %in% c("duration", "input.size.1", "input.size.2", features))]
        
        temp <- read.csv(
                paste("./data/", kernelsDict[kernel], "-GPU.csv", sep = ""),
                header = FALSE,
                stringsAsFactors = FALSE
            )
        temp <- temp[grep(names(kernelsDict[kernel]), temp$V2), ]
        
        if(kernelsDict[kernel] == "gaussian")
            temp <- temp[temp$V3 <= 4096,]
        
        ifelse(
            kernel %in% kernel_1_parameter,
            data <- data.frame(tempNvprof, temp[3:(dim(temp)[2] - 2)]),
            data <- data.frame(tempNvprof, temp[, 3:(dim(temp)[2] - 2)])
        )
        
        
        if (kernelsDict[kernel] == "backprop") {
            # names(data) <- c("P1")
            trainingData <- data[data$input.size.1 <= 27648,-c(1, 2)]
            testingData <- data[data$input.size.1 >= 27648, -c(1, 2)]
        }
        
        if (kernelsDict[kernel] == "gaussian") {
            trainingData <- data[data$input.size.1 <= 2048,-c(1, 2)]
            testingData <- data[data$input.size.1 == 4096, -c(1, 2)]
        }
        
        if (kernelsDict[kernel] == "kernel") {
            # temp$V3 <- as.numeric(temp$V3)
            # data <- data.frame(tempNvprof, temp[,3:(dim(temp)[2]-2)])
            trainingData <- data[data$input.size.1 == 25,-c(1, 2)][-1, ]
            testingData <- data[data$input.size.1 == 100, -c(1, 2)][-1, ]
        }
        
        if (kernelsDict[kernel] == "calculate_temp") {
            # data <- data.frame(tempNvprof, temp[,3:(dim(temp)[2]-2)])
            trainingData <-
                data[data$input.size.1 <= 256 &
                         data$input.size.2 == 256,-c(1, 2)][-1, ]
            testingData <-
                data[data$input.size.1 >= 256 &
                         data$input.size.2 != 256,-c(1, 2)][-1, ]
        }
        if (kernelsDict[kernel] == "hotspotOpt1") {
            # temp$V3 <- as.numeric(temp$V3)
            # data <- data.frame(tempNvprof, sapply(temp[,3:(dim(temp)[2]-2)], normalizeMax))
            trainingData <-
                data[data$input.size.1 <= 4 &
                         data$input.size.2 <= 100,-c(1, 2)][-1, ]
            testingData <-
                data[data$input.size.1 > 4 & data$input.size.2 > 100, -c(1, 2)][-1, ]
        }
        if (kernelsDict[kernel] == "needle_cuda_shared_1" |
            kernelsDict[kernel] == "needle_cuda_shared_2") {
            # temp$V3 <- as.numeric(temp$V3)
            # data <- data.frame(tempNvprof, temp[,3:(dim(temp)[2]-2)])
            # data <- data.frame(tempNvprof, sapply(temp[,3:(dim(temp)[2]-2)], normalizeMax))
            
            trainingData <-
                data[data$input.size.1 <= 1024 &
                         data$input.size.2 <= 4,-c(1, 2)][-1, ]
            testingData <-
                data[data$input.size.1 == 4096 &
                         data$input.size.2 > 4, -c(1, 2)][-1, ]
        }
        predictFeatures(trainingData, testingData)
    }
}


    
    
    
    # predictParametersTraining <- function(trainingData, testingData){
    #   fakeFeature <- data.frame(matrix(ncol=0,nrow=dim(testingData)[1]),stringsAsFactors=FALSE, check.names = FALSE)
    #   for (feature in 3:7){
    #     counter <- createCounter(0)
    #
    #     rss <- matrix(nrow = 9, ncol = 3)
    #     png(filename = paste("./images/fitModels/", colnames(trainingData[feature]), ".png", sep=""), width = 1600, height = 800)
    #     par(family = "Times", mfrow=c(3,3))
    #     for(resultY in c("", "exp", "log")){
    #         for(FeaturesX in c("", "log", "exp", "poly")){
    #           count <- counter(1)
    #             try(fit <-lm(as.formula(paste(resultY, "(",colnames(trainingData[feature]) , ") ~",
    #                     paste(FeaturesX, "(",colnames(trainingData[,1:2]),")",collapse = " + ")
    #               )), data =  trainingData), TRUE)
    #             rss[count,1] <- mean(fit$residuals)
    #             rss[count,2] <- resultY
    #             rss[count,3] <- FeaturesX
    #
    #             base <- residuals(fit)
    #             qqnorm(base, ylab="Studentized Residual",
    #                    xlab="t Quantiles",
    #                    main=paste(colnames(trainingData[feature]), " Y=", resultY, " X=", FeaturesX, sep=""),
    #                    cex.lab = 2, cex.main=2,cex=1.5,cex.axis=2)
    #             qqline(base, col = 2,lwd=5)
    #
    #         }
    #     }
    #     dev.off()
    #     key <- which(rss[,1] == max(rss[,1]))[1]
    #
    #     tempFeature <- predict(lm(as.formula(paste(rss[key,2], "(",colnames(trainingData[feature]) , ") ~",
    #                               paste(rss[key,3], "(",colnames(trainingData[,1:2]),")",collapse = " + ")
    #     )), data =  trainingData), testingData[,1:2])[1:27]
    #
    #     if(rss[key,2] == "exp")
    #       tempFeature <- log(tempFeature)
    #
    #     if(rss[key,2] == "log")
    #       tempFeature <- exp(tempFeature)
    #
    #     if(rss[key,2] == "")
    #       tempFeature <- tempFeature
    #
    #     fakeFeature <- cbind(fakeFeature, tempFeature)
    #   }
    #   names(fakeFeature) <- names(testingData[3:7])
    #
    #   png(filename = paste("./images/fakeFeatures/", kernel, ".png", sep=""), width = 1600, height = 800)
    #   par(family = "Times", mfrow=c(3,2))
    #   for(i in 1:5){
    #     plot(testingData[,i+2], col="blue", ylab = names(testingData[i+2]))
    #     lines(fakeFeature[,i], col="red")
    #   }
    #   dev.off()
    #   return(fakeFeature)
    # }
    
    #
    #
    # # input<-seq(from=8192, by = 1024, to = 262144)
    # testData <- data.frame(
    # elapsed_cycles_sm=approxExtrap(backprop$input.size.1[1:57],backprop$elapsed_cycles_sm[1:57],xout=input[58:249])$y,
    # device_memory_read_transactions=approxExtrap(backprop$input.size.1[1:57],backprop$device_memory_read_transactions[1:57],xout=input[58:249])$y,
    # global_store_transactions=approxExtrap(backprop$input.size.1[1:57],backprop$global_store_transactions[1:57],xout=input[58:249])$y,
    # issued_control.flow_instructions=approxExtrap(backprop$input.size.1[1:57],backprop$issued_control.flow_instructions[1:57],xout=input[58:249])$y)
    #
    # MA <- trainingData$multiprocessor_activity
    #
    # trainingData$multiprocessor_activity <- NULL
    #
    # # fit <- lda(trainingData$multiprocessor_activity ~., data =  trainingData)
    # # fit <- qda(trainingData$multiprocessor_activity ~., data =  trainingData)
    #
    # fit <- randomForest(MA ~ ., data = trainingData, mtry=2, ntree=20)
    # createdMA <- predict(fit, testData)
    # plot(c(MA,createdMA))
    #
    #
    #
    #
    #
    # createdMA <- predict(fit, testData)
    # createdMA <- log(createdMA)
    # createdMA[createdMA > 100] <- 100
    # testData$multiprocessor_activity <- createdMA
    #
    # testFinalData <- rbind(trainingData, testData)
    #
    #   fit <- lm(duration[1:124] ~ ., data = testFinalData[1:124,])
    #   predictions <- predict(fit, testFinalData[125:249,])
    #
    #     boxplot(duration[125:249]/predictions, main=names(testFinalData))
    #
    #
    # mape <- mean(predictions - duration[58:249])/abs(duration[58:249])*100
    # mape
    #
    # # [7]  multiprocessor_activity
    # # [1]  elapsed_cycles_sm
    # # [10] device_memory_read_transactions
    # # [9]  global_store_transactions
    # # [13] issued_control.flow_instructions
    #
    # # [19] load.store_instructions
    # # [16] executed_load.store_instructions
    # # [6]  active_cycles
    # # [20] misc_instructions
    # # [18] control.flow_instructions
    #
    # temp <- read.csv(paste("./data/gaussian-GPU.csv", sep = ""), header = FALSE,stringsAsFactors = FALSE)
    # tempTime <- temp[grep("Fan1", temp$V2),]
    # tempTime$V3 <- as.numeric(tempTime$V3)
    #
    # # plot(tempTime$V5[tempTime$V3 == 2048]/1000000)
    #
    # gauss <- data.frame(read.csv("./datasets/Fan1-Tesla-K40.csv"))
    # features <- gauss[, which(names(gauss) %in% c("duration","input.size.1", "multiprocessor_activity",
    #                                                         "elapsed_cycles_sm",
    #                                                         "device_memory_read_transactions",
    #                                                         "global_store_transactions",
    #                                                         "issued_control.flow_instructions"))]
    # iterNumber <- count(features$input.size.1)$x
    #
    # for(sizeMatrix in c(256, 512, 1024, 2048)){
    #   # print(i)
    #   trainingData <- features[features$input.size.1 == sizeMatrix,]
    #   trainingData$input.size.1 <- NULL
    #   trainingData$elapsed_cycles_sm <- NULL
    #   trainingData$multiprocessor_activity <- NULL
    #   trainingData$device_memory_read_transactions <-NULL
    #   testData <- data.frame(
    #             # device_memory_read_transactions=approxExtrap(tempTime$V4[tempTime$V3 == sizeMatrix],gauss$device_memory_read_transactions[gauss$input.size.1==sizeMatrix],xout=c(tempTime$V4[tempTime$V3 == sizeMatrix+256], 1))$y
    #             global_store_transactions=approxExtrap(tempTime$V4[tempTime$V3 == sizeMatrix],gauss$global_store_transactions[gauss$input.size.1==sizeMatrix],xout=c(tempTime$V4[tempTime$V3 == sizeMatrix*256], 1))$y,
    #             issued_control.flow_instructions=approxExtrap(tempTime$V4[tempTime$V3 == sizeMatrix],gauss$issued_control.flow_instructions[gauss$input.size.1==sizeMatrix],xout=c(tempTime$V4[tempTime$V3 == sizeMatrix*256], 1))$y
    #   )
    #
    #    # elapsed_cycles_sm=approxExtrap(tempTime$V4[tempTime$V3 == sizeMatrix],gauss$elapsed_cycles_sm[gauss$input.size.1==sizeMatrix],xout=tempTime$V4[tempTime$V3 == sizeMatrix+256])$y
    #   fit <- lm(trainingData$duration ~ ., data = trainingData)
    #   predictions <- predict(fit, testData)
    #   measured <- features$duration[features$input.size.1 == sizeMatrix*2]
    #   length(predictions)
    #   boxplot(predictions/measured, main=paste("Training=",sizeMatrix, "  Testing=",sizeMatrix*2, sep=""))
    # }
    # gauss <- data.frame(read.csv("./datasets/Fan1-Tesla-K40.csv"))
    # trainingData <- gauss[, which(names(gauss) %in% c("duration","input.size.1",
    #                                                   "elapsed_cycles_sm",  "device_memory_read_transactions", "global_store_transactions",
    #                                                   "issued_control.flow_instructions"))]
    #
    # trainingData <- trainingData[trainingData$input.size.1 == 4096,]
    # trainingData$input.size.1 <- NULL
    #
    # trainingData$duration <- NULL
    #
    #
    # predictions <- predict(fit, trainingData)
    # length(predictions)
    #
    # duration <- tempTime$V5[tempTime$V3 == 2048]
    # length(duration)
    # boxplot(predictions/tempTime$V5[tempTime$V3 == 4096])
    #
    # mape <- mean(predictions - tempTime$V5[tempTime$V3 == 6144])/abs(tempTime$V5[tempTime$V3 == 6144])*100
    #
    # length(tempTime$V5[tempTime$V3 == 2048])
    # dim(trainingData)
    #
    #
    # plot(trainingData$duration[trainingData$input.size.1 == 2048])
    #
    #
    # View(tempTime)
    