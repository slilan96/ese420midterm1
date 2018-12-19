# Shadrack Lilan and Abdurrahman Cam Midterm 3 - ESE 420 - R script

library("RNetLogo")
# Change this path to where the NetLogo Model and R script are
nl.path <- "C:/Users/Abdurrahman/Desktop/UPenn20182019Senior/ESE420/ese420midterm1/"
# This path should point to your netlogo installed folder
NLStart("C:/Program Files/NetLogo 6.0.4/app", gui = FALSE, nl.jarname = "netlogo-6.0.4.jar")
# name of the NetLogo model
model.path <- "midtermOne.nlogo"
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

##
# (a) Use R package that lets you pick a random number from a distribution for each pdf
#     For combinatorial samples, sample from each pdf at random (without keeping one
#     constant) and run the model.
##

# H6: Influence of a Close One Losing a Bet
# H14: The Decay of Affects of Violation of Principles

# loading the model into R
NLLoadModel(absolute.model.path)

# rexp(n times to sample, lambda rate of arrival)
H6_sample <- rexp(1, H6_rate)
H14_sample <- rlnorm(1, H14_mean, H14_sd)

# ##TODO Think about whether we should be separetely coming up with values
# For each cluster...

# Running model combinatorially with these samples
NLCommand(sprintf("ask turtles [ set agent-winning-losing-influence %s]", H6_sample))
NLCommand(sprintf("ask turtles [ set agent-shame-decay %s]", H14_sample))
NLCommand("setup")
NLDoCommandWhile("number-of-bets-made < 100", "go")
ret <- NLReport("sum [agent-shame] of turtles")
ret

#timedata[[i]] <- NLGetAgentSet(c("who", "xcor", "ycor", "agent-shame","bankrupt"), "turtles")}
#timedata
#for (i in 1:10){write.csv(timedata[i], file="C:/Users/Abdurrahman/Desktop/UPenn20182019Senior/ESE420/ese420midterm1/log.csv")}

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
# (c) Sample the results of the model multiple times at the same numbers to show that
#     we have stochastic outcomes
##

sim <- function(numofpeople) {
  NLLoadModel(absolute.model.path)
  NLCommand("setup")
  
  NLCommand("set num-people", numofpeople)
  NLDoCommandWhile("number-of-bets-made < 100", "go")
  
  #NLCommand("set num-people", numofpeople, "setup")
  ret <- NLReport("company-wins")
  return(ret)
}

rep.sim <- function(numpeople, rep)
  lapply(numpeople, function(dens) replicate(rep, sim(dens)))
d.2 <- seq(45, 70, 5)
res <- rep.sim(d.2, 10)
boxplot(res, names = d.2, xlab = "num of people", ylab = "company winnings")

##
# (d) Write out the outputs to a saved csv file.
##

#NLLoadModel(file.path(nl.path, model.path))
NLLoadModel(absolute.model.path)

nruns <- 30
rm(list=ls())
timedata <- list()
for(i in 1:10) {
  NLCommand("setup")
  NLDoCommand(10,"go")
  timedata[[i]] <- NLGetAgentSet(c("who", "xcor", "ycor", "agent-shame","bankrupt"), "turtles")}
NLCommand("setup")
NLCommand("go")

# to view the output
timedata
# to save this output to CSV (and then work on it in Excel)
for (i in 1:10){write.csv(timedata[i], file="C:/Users/Abdurrahman/Desktop/UPenn20182019Senior/ESE420/ese420midterm1/log.csv")}

##
# (e) Display a cross run output graph 
#     (Possible Responses and Parameters for our model)
#     Responses: money, sentiment, success, heard-of-bet, salary, bankrupt, agent-shame
#     Parameters: salary, agent-friend-influence, agent-affect-of-advertisement, 
#                 times-bet-advertised (patches own), agent-principle, 
#                 agent-taxation-influence, agent-shame-decay
#                                 
##


# Part 3 & 4: Design a parametric sensitivity analysis, Explore 5 factors in a 2^k 
#             factorial design to find the main effects of your model.

# Part 5: Output Analysis
# - Run the parametric sensitivity analysis above that explores the 5 factors (3 replications)
# - Analyze one of the most significant factors by running a What if scenario...
#   (different from PDFs in 1 and 2)





