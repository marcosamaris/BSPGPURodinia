library(e1071)
library(ggplot2)
library(plyr)
library(randomForest)

dirpath <- "~/Dropbox/Doctorate/GIT/BSPGPURodinia/"
setwd(paste(dirpath, sep=""))

# source("./R-code/include/common.R")
source("./R-code/include/sharedFunctions.R")

gpus <- read.table("./R-code/deviceInfo.csv", sep=",", header=T)
NoGPU <- dim(gpus)[1]

apps <-  c(
    "bpnn_layerforward_CUDA",
    "bpnn_adjust_weights_cuda",
    "Fan1",
    "Fan2",
    "kernel",
    "calculate_temp",
    "hotspotOpt1",
    "kernel_gpu_cuda",
    "lud_diagonal",
    "lud_perimeter",
    "lud_internal",
    "needle_cuda_shared_1",
    "needle_cuda_shared_2"
)

Parameters <- c("input.size.1", "input.size.2", "duration", "achieved_occupancy",
                "gld_request",	"gst_request",
                "global_load_transactions_per_request",	"global_store_transactions_per_request",
                "shared_load_transactions",	"shared_store_transactions",
                "shared_memory_load_transactions_per_request",
                "shared_memory_store_transactions_per_request", 
                # "totalLoadGM", "totalStoreGM", "totalLoadSM", "totalStoreSM",
                "floating_point_operations.single_precision.",
                "floating_point_operations.double_precision.",
                "grid.x",	"grid.y",	"block.x",	"block.y",
                "max_clock_rate",	"num_of_cores",	"bandwidth",
                "name",	"kernel", "gpu_name"
)

ParametersNCA <- c("input.size.1", "input.size.2", "duration", "achieved_occupancy",
                "totalLoadGM", "totalStoreGM", "totalLoadSM", "totalStoreSM",
                "floating_point_operations.single_precision.",
                "floating_point_operations.double_precision.",
                "grid.x",	"grid.y",	"block.x",	"block.y", "totalThreads",
                "max_clock_rate",	"num_of_cores",	"bandwidth",
                "name",	"kernel", "gpu_name"
)

result <- data.frame()
for( kernelApp in apps[1:8]) {
    DataAppGPU <- read.csv(file = paste("./datasets/", kernelApp, ".csv", sep = ""))
    DataAppGPU <- rbind(DataAppGPU[Parameters])
    DataAppGPU$totalLoadGM <- DataAppGPU$gld_request/as.numeric(DataAppGPU$global_load_transactions_per_request)
    DataAppGPU$totalStoreGM <- DataAppGPU$gst_request/as.numeric(DataAppGPU$global_store_transactions_per_request)
    DataAppGPU$totalLoadSM <- DataAppGPU$shared_load_transactions/as.numeric(DataAppGPU$shared_memory_load_transactions_per_request)
    DataAppGPU$totalStoreSM <- DataAppGPU$shared_store_transactions/as.numeric(DataAppGPU$shared_memory_store_transactions_per_request)
    DataAppGPU$blockSize <- DataAppGPU$block.x*DataAppGPU$block.y
    DataAppGPU$GridSize <- DataAppGPU$grid.x*DataAppGPU$grid.y
    DataAppGPU$totalThreads <- DataAppGPU$blockSize*DataAppGPU$GridSize
    
    Data <- DataAppGPU[ParametersNCA]
    
    if(kernelApp == "bpnn_layerforward_CUDA"){
        Data$floating_point_operations.double_precision. <- NULL
        Data$input.size.2 <- NULL   
    }
    if(kernelApp == "bpnn_adjust_weights_cuda"){
        Data$input.size.2 <- NULL   
        Data$floating_point_operations.single_precision. <- NULL
        Data$totalLoadSM <- NULL
        Data$totalStoreSM <- NULL
    }

    if(kernelApp == "Fan1"){
        Data <- subset(Data,  input.size.1 == 4096)
        Data$floating_point_operations.double_precision. <- NULL
        Data$input.size.2 <- NULL   
        Data$totalLoadSM <- NULL
        Data$totalStoreSM <- NULL
    }
    if(kernelApp == "Fan2"){
        Data <- subset(Data,  input.size.1 == 4096)
        Data$input.size.2 <- NULL   
        Data$totalLoadSM <- NULL
        Data$totalStoreSM <- NULL
        Data$floating_point_operations.double_precision. <- NULL
    }
    if(kernelApp == "kernel"){
        Data$input.size.2  <- NULL
        Data <- subset(Data,  floating_point_operations.single_precision. != 0 & input.size.1 == 100)
        Data$floating_point_operations.double_precision.  <- NULL
       
        # png(filename = paste("./images/features/", kernelApp, ".png", sep = ""), width = 1200, height = 1200)
        # par(mfrow = c(1, 2), oma=c(4, 2, 4, 0), xpd=TRUE)
        # cex.Size <- 2
        # plot(NA, xlim = range(1:102), ylim = range(dens), ylab="Time (seg)", xlab="Samples",
        #      cex.lab = cex.Size, cex.axis = cex.Size)
        # i <- 1
        # for(gpu in c(1:3, 5:6, 8:10)){
        #     lines(1:102,Data$duration[Data$gpu_name == as.character(gpus[gpu, "gpu_name"])], col=cbbPalette[i], lwd=5, lty = i)
        #     i <- i + 1
        # }
        # legend("top",  legend = gpus[c(1:3, 5:6, 8:10), "gpu_name"], fill = 1:8,  col=cbbPalette[1:8],lwd = 5, lty=1:8, cex=1.5, ncol = 2)
        # 
        # boxplot(Data$duration[Data$gpu_name != "GTX-750"]~Data$gpu_name[Data$gpu_name != "GTX-750"], xlab = " ", main = "",
        #         cex.lab = cex.Size, cex.axis = cex.Size, cex.main = cex.Size, las=2)
        # title(main= paste("Time of ", kernelApp, sep=""),outer=TRUE)
        # dev.off()
    }
    
    if(kernelApp == "calculate_temp"){
        Data <- subset(Data, input.size.2 == 256)
        Data$floating_point_operations.double_precision.  <- NULL
        
    }
    if(kernelApp == "hotspotOpt1"){
        Data <- subset(Data, input.size.2 == 1000)
        
        Data$totalLoadGM <- NULL
        Data$totalStoreGM <- NULL
        
        Data$totalLoadSM <- NULL
        Data$totalStoreSM <- NULL
        Data$floating_point_operations.double_precision.  <- NULL
    }
    
    if(kernelApp == "kernel_gpu_cuda"){
        Data$input.size.2  <- NULL
        Data$block.y  <- NULL
        Data$grid.y  <- NULL
        Data$floating_point_operations.double_precision. <- NULL
        Data$floating_point_operations.single_precision. <- NULL
    }
    
    Data <- subset(Data, gpu_name != "GTX-750")
    for( gpu in c(1:3, 5:6, 8:10)) {
        trainingSet <- subset(Data, gpu_name != as.character(gpus[gpu,"gpu_name"]))
        testSet <- subset(Data, gpu_name == as.character(gpus[gpu,"gpu_name"]))
        
        trainingSet$name<- NULL
        trainingSet$gpu_name <- NULL
        trainingSet$kernel <- NULL
        
        testSet$name <- NULL
        testSet$gpu_name <- NULL
        testSet$kernel <- NULL
        
        trainingSet <- log(trainingSet)
        testSet <-  log(testSet)
        
        TestDuration <- testSet$duration
        testSet$duration <- NULL
        
        base <- randomForest(trainingSet$duration ~ ., data = trainingSet, mtry=4, ntre=50)
        
        predictions <- predict(base, testSet)
        
        Acc <- predictions/TestDuration
        AccMin <- min(Acc)
        AccMean <- mean(as.matrix(Acc))
        AccMedian <- median(as.matrix(Acc))
        AccMax <- max(Acc)
        AccSD <- sd(as.matrix(Acc))
        
        mse <- mean((Acc - 1)^2)
        mae <- mean(abs(as.matrix(TestDuration)  - predictions))
        mape <- mean(abs(as.matrix(TestDuration)  - predictions/predictions))
        
        Tempresult <- data.frame(gpus[gpu,"gpu_name"], kernelApp, TestDuration, predictions, Acc, AccMin, AccMax, AccMean, AccMedian, AccSD,mse, mae,mape)
        result <- rbind(result, Tempresult)
    }
}
# result
colnames(result) <-c("Gpus", "Apps", "Measured", "Predicted",  "accuracy", "Min", "max", "Mean", "Median", "SD", "mse", "mae", "mape")

# Tempresult <- data.frame(gpu, kernelApp, TestDuration, predictions, Acc, AccMin, AccMax, AccMean, AccMedian, AccSD, mse, mae,mape)

Result_LM <- result
Graph <- ggplot(data=result, aes(x=Gpus, y=accuracy, group=Gpus, col=Gpus)) + 
    geom_boxplot( size=1.5, outlier.size = 2.5) + scale_y_continuous(limits =  c(0, 2.5)) +
    stat_boxplot(geom ='errorbar') +
    xlab(" ") + 
    theme_bw() +
    ggtitle("Random Forest") +
    ylab(expression(paste("Accuracy ",T[k]/T[m] ))) +
    theme(plot.title = element_text(family = "Times", face="bold", size=40)) +
    theme(axis.title = element_text(family = "Times", face="bold", size=30)) +
    theme(axis.text  = element_text(family = "Times", face="bold", size=20, colour = "Black")) +
    theme(axis.text.x=element_blank()) +
    theme(legend.title  = element_text(family = "Times", face="bold", size=0)) +
    theme(legend.text  = element_text(family = "Times", face="bold", size=20)) +
    theme(legend.direction = "horizontal", 
          legend.position = "bottom",
          legend.key=element_rect(size=5),
          legend.key.size = unit(5, "lines")) +
    # facet_grid(.~Apps, scales="fixed") 
    facet_wrap(~Apps, ncol=2, scales="fixed") +
    theme(strip.text = element_text(size=20))
ggsave(paste("./images/randomForest-Rodinia.png", sep = ""), Graph, height = 20, width = 20)

# ggsave(paste("./images/LinearRegression-Rodinia.pdf",sep=""), Graph, device = pdf, height=10, width=16)
# write.csv(result, file = "./results/LinearRegression-Rodinia.csv")


