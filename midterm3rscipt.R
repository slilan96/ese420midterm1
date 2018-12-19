# Shadrack Lilan and Abdurrahman Cam Midterm 3 - ESE 420 - R script

library("RNetLogo")
# Change this path to where the NetLogo Model and R script are
nl.path <- "C:/Users/Abdurrahman/Desktop/UPenn20182019Senior/ESE420/ese420midterm1/"
# This path should point to your netlogo installed folder
NLStart("C:/Program Files/NetLogo 6.0.4/app", gui = FALSE, nl.jarname = "netlogo-6.0.4.jar")
# name of the NetLogo model
model.path <- "modelForR.nlogo"
# the full string for the Netlogo model
absolute.model.path <- paste(nl.path,model.path,sep="")

# loading the model into R
#NLLoadModel(absolute.model.path)

###################

# Part 1: We extracted H14 (Exponential Dist.) and H6: Log Normal (Log Normal Dist.)
library(MASS)
set.seed(101)

data = read.csv(paste(nl.path, "TableCSV.csv", sep=""), header=TRUE, row.names="Persons")

# without the cluster averages
data_persons = data[-c(5, 14, 18),]

H6fit <- fitdistr(data_persons$H6, "exponential")
H6_rate <- H6fit$estimate

H14fit <- fitdistr(data_persons$H14, "log-normal")
H14fit$loglik
H14_mean <- H14fit$estimate[1]
H14_sd <- H14fit$estimate[2]

# Part 2:

# loading the model into R
NLLoadModel(absolute.model.path)

##
# (b) Sample from each PDF and plot to show that we are sampling correctly.
##

# number of times to sample
n <- 100

# rexp(n times to sample, lambda rate of arrival)
H6_sampling <- rexp(n, H6_rate)
H14_sampling <- rlnorm(n, H14_mean, H14_sd)

# the exponential distribution plot of H6
plot(density(H6_sampling))

# the log normal distribution plot of H14
plot(density(H14_sampling))

##
# (a) Use R package that lets you pick a random number from a distribution for each pdf
#     For combinatorial samples, sample from each pdf at random (without keeping one
#     constant) and run the model.
##

# H6: Influence of a Close One Losing a Bet
# H14: The Decay of Affects of Violation of Principles

# Running model combinatorially with these samples
response_data <- list()
# rexp(n times to sample, lambda rate of arrival)
H6_sample <- rexp(1, H6_rate)
# rlnorm(n times to sample, mean, sd)
H14_sample <- rlnorm(1, H14_mean, H14_sd)

for(i in 1:3){
  NLCommand("setup")
  # Setting H6 and H14 Values
  NLCommand(sprintf("ask turtles [ set agent-winning-losing-influence %s]", H6_sample))
  NLCommand(sprintf("ask turtles [ set agent-shame-decay %s]", H14_sample))
  NLDoCommandWhile("ticks < 15000", "go")
  list_to_report <- c(i, "ticks", "sum [agent-shame] of turtles", "sum [bankrupt] of turtles",
                      "sum [money] of turtles", "sum [sentiment] of turtles")
  list_col_names <- c("Replication Number of Total Responses", "Ticks","Shame", "Bankrupt",
                      "Money", "Sentiment")
  response_data[[i]] <- NLDoReport(1, "go", list_to_report, as.data.frame=TRUE, 
                                   df.col.names=list_col_names)
}

# (d) Write out the outputs to a saved csv file.
write.csv(response_data, file=sprintf("%sh6=%2.5f_h14=%2.5f.csv", nl.path, H6_sample, H14_sample))  

##
# (c) Sample the results of the model multiple times at the same numbers to show that
#     we have stochastic outcomes
##

# At H6=0.52793, and H14=0.02488
data = read.csv(paste(nl.path, "Part2CValuesInRows.csv", sep=""), header=TRUE)

plot(c(1:3),data$Shame, main="Total Shame at H6=0.52793, and H14=0.02488",
     xlab="Replications", ylab="Shame Value", col="red", pch=19)
plot(c(1:3),data$Bankrupt, main="Total Bankrupt at H6=0.52793, and H14=0.02488",
     xlab="Replications", ylab="Bankrupt Value", col="red", pch=19)
plot(c(1:3),data$Money, main="Total Money at H6=0.52793, and H14=0.02488",
     xlab="Replications", ylab="Money Value", col="red", pch=19)
plot(c(1:3),data$Sentiment, main="Total Sentiment at H6=0.52793, and H14=0.02488",
     xlab="Replications", ylab="Sentiment Value", col="red", pch=19)

##
# (e) Display a cross run output graph 
##

##
## Keep H6 Constant and Vary H14 for 20 Runs
##

response_data <- list()
H6_sample <- rexp(1, H6_rate)
NLLoadModel(absolute.model.path)

for(i in 1:20){
  
  # Varying H14
  H14_sample <- rlnorm(1, H14_mean, H14_sd)
  
  NLCommand("setup")
  # Setting H6 and H14 Values
  NLCommand(sprintf("ask turtles [ set agent-winning-losing-influence %s]", H6_sample))
  NLCommand(sprintf("ask turtles [ set agent-shame-decay %s]", H14_sample))
  NLDoCommandWhile("ticks < 15000", "go")
  list_to_report <- c(H14_sample, i, "ticks", "sum [agent-shame] of turtles", "sum [bankrupt] of turtles",
                      "sum [money] of turtles", "sum [sentiment] of turtles")
  list_col_names <- c("H14_sample","Replication Number of Total Responses", "Ticks","Shame", "Bankrupt",
                      "Money", "Sentiment")
  response_data[[i]] <- NLDoReport(1, "go", list_to_report, as.data.frame=TRUE, 
                                   df.col.names=list_col_names)
}

write.csv(response_data, file=sprintf("%sPart2E_H6Const_VaryH14_h6=%2.5f.csv", nl.path, H6_sample))  

##
## Keep H14 Constant and Vary H6 for 20 Runs
##

response_data <- list()
H14_sample <- rlnorm(1, H14_mean, H14_sd)
NLLoadModel(absolute.model.path)

for(i in 1:20){
  
  # Varying H6
  H6_sample <- rexp(1, H6_rate)
  
  NLCommand("setup")
  # Setting H6 and H14 Values
  NLCommand(sprintf("ask turtles [ set agent-winning-losing-influence %s]", H6_sample))
  NLCommand(sprintf("ask turtles [ set agent-shame-decay %s]", H14_sample))
  NLDoCommandWhile("ticks < 15000", "go")
  list_to_report <- c(H6_sample, i, "ticks", "sum [agent-shame] of turtles", "sum [bankrupt] of turtles",
                      "sum [money] of turtles", "sum [sentiment] of turtles")
  list_col_names <- c("H6_sample","Replication Number of Total Responses", "Ticks","Shame", "Bankrupt",
                      "Money", "Sentiment")
  response_data[[i]] <- NLDoReport(1, "go", list_to_report, as.data.frame=TRUE, 
                                   df.col.names=list_col_names)
}

write.csv(response_data, file=sprintf("%sPart2E_H14Const_VaryH6_h14=%2.5f.csv", nl.path, H14_sample))  

## Cross Run Graphs of H14 vs Constant H6, and H6 vs Constant H14




# Part 3 & 4: Design a parametric sensitivity analysis, Explore 5 factors in a 2^k 
#             factorial design to find the main effects of your model.

# Part 5: Output Analysis
# - Run the parametric sensitivity analysis above that explores the 5 factors (3 replications)
# - Analyze one of the most significant factors by running a What if scenario...
#   (different from PDFs in 1 and 2)





