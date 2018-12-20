# Parameters to consider in our model...
#     (Possible Responses and Parameters for our model)
#     Responses: money, sentiment, success, heard-of-bet, salary, bankrupt, agent-shame
#     Parameters: salary, agent-friend-influence, agent-affect-of-advertisement, 
#                 times-bet-advertised (patches own), agent-principle, 
#                 agent-taxation-influence, agent-shame-decay



############################################################################
#R Marries NetLogo: Introduction to the RNetLogo Package by
# Jan C. Thiele
#Additional Code added by Ryan Farell
#Load RNetLogo Package, Start NetLogo
############################################################################

library("RNetLogo")
nl.path <- "C:/Users/Abdurrahman/Desktop/UPenn20182019Senior/ESE420/ese420midterm1/"
NLStart("C:/Program Files/NetLogo 6.0.4/app", gui = FALSE, nl.jarname = "netlogo-6.0.4.jar")


###########################################################################
#Commands
###########################################################################
model.path <- "midtermOne.nlogo"
absolute.model.path <- paste(nl.path,model.path,sep="")
NLLoadModel(absolute.model.path)
NLCommand("set num-people 50")
NLCommand("setup")
NLCommand("go")
NLCommand("print \"Hello NetLogo, I called you from R.\"")
num_people.in.r <- 88
NLCommand("set num-people ", num_people.in.r, "setup", "go")
NLDoCommand(10, "go")
NLReport("ticks")

NLCommand("setup")
betsmade <- NLDoReport(10, "go", "number-of-bets-made")
print(unlist(betsmade))

NLCommand("set num-people ", 59)
NLCommand("setup")
betsmade <- NLDoReportWhile("number-of-bets-made < 100", "go",
	c("ticks", "number-of-bets-made"),
	as.data.frame = TRUE, df.col.names = c("tick", "number of bets made"))
plot(betsmade, type = "s")


###########################################################################
#Exploratory Analysis & Simulation
###########################################################################
#model.path <- file.path("models", "Sample Models", "Earth Science",
#	"Fire.nlogo")
#NLLoadModel(file.path(nl.path, model.path))

#Next, we define a function which sets the density of trees, executes the simulation until no
#turtles are left, and reports back the percentage of burned trees:



sim <- function(numofpeople) {
  NLLoadModel(absolute.model.path)
  NLCommand("setup")
  
  NLCommand("set num-people", numofpeople)
  NLDoCommandWhile("number-of-bets-made < 100", "go")
  
	#NLCommand("set num-people", numofpeople, "setup")
	ret <- NLReport("company-wins")
	return(ret)
	}
d <- seq(20, 100, 20)
pb <- sapply(d, function(x) sim(x) )
plot(d, pb, xlab = "num of people", ylab = "company winnings")

#Interesting: seems like the 60% density mark is important. Let's test further.

d.1 <- seq(57,63,1)
pb.1 <- sapply(d.1, function(dens) sim(dens))
plot(d.1, pb.1, xlab = "num of people", ylab = "company winnings")

#As we know the region of phase transition (between a density of 45 and 70 percent), we
#can explore this region more precisely. As the Forest Fire model uses random numbers, it
#is interesting to find out how much stochastic variation occurs in this region. Therefore, we
#define a function to repeat the simulations with one density several times:

rep.sim <- function(numpeople, rep)
	lapply(numpeople, function(dens) replicate(rep, sim(dens)))
d.2 <- seq(45, 70, 5)
res <- rep.sim(d.2, 10)
boxplot(res, names = d.2, xlab = "num of people", ylab = "company winnings")

#Now, we have seen that the variation of burned trees at densities below 55 and higher than
#65 is low.

#d.3 <- seq(55, 65, 1); res <- rep.sim(d.3, 20)
#boxplot(res,names = d.3, xlab = "density", ylab = "percent burned")

#The above simulations were not Monte-Carlo simulations. Let's suppose that 
#the underlying forrest density distribution is uniform between 1 and 100. 
#We can run a Monte Carlo simulation capturing the average percent burned.

d.4 <- runif(10,0,100)
pb.4 <- sapply(d.4, function(dens) sim(dens))
mean(pb.4)


###########################################################################
#Monte Carlo Simulation
###########################################################################



#model.path <- file.path("models", "Sample Models", "Biology", "Virus.nlogo")

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

#This  should save it as a file with commas separating the column entries. 
#If you are denied access, then copy the output to the clipboard and save it as a txt file. Then import it to xsl.


############################################################################
#Analytic Comparison of Probability Distributions
############################################################################

#model.path1 <- file.path("models", "Sample Models", "Chemistry & Physics",
# "GasLab")
#model.path2 <- "GasLab Free Gas.nlogo"
#NLLoadModel(file.path(nl.path, model.path1, model.path2))


nl.path <- "C:/Users/Abdurrahman/Desktop/UPenn20182019Senior/ESE420/ese420midterm1/"
NLStart("C:/Program Files/NetLogo 6.0.4/app", gui = FALSE, nl.jarname = "netlogo-6.0.4.jar")
###########################################################################
#Commands
###########################################################################
model.path <- "midtermOne.nlogo"
absolute.model.path <- paste(nl.path,model.path,sep="")
NLLoadModel(absolute.model.path)

NLCommand("set average-salary 500", "no-display", "setup")

#Next, we run the simulation for 40 times of 50 ticks (= 2000 ticks), save the speed of the
#particles after every 50 ticks, and 
#flatten the list of lists (one list for each of the 40 runs) to
#one big vector:

agent.money <- NLDoReport(40, "repeat 50 [go]",
 "[money] of turtles")

agent.money.vector <- unlist(agent.money)

library("Ryacas")
yacasInstall()

shame.mean <- NLReport("mean [agent-shame] of turtles")

B <- function(v, m = 1, k = 1)
  (v * m * k)
yacas(B)
#Then, we define the integral of function B from 0 to infity and register the integral expression
#in Yacas:
B.integr <- expression(integrate(B, 0, Infinity))
yacas(B.integr)
#Now, we calculate a numerical approximation using Yacas's function N() and get the result
#from Yacas in R (the result is in the list element value):
normalizer.yacas <- yacas(N(B.integr))
normalizer <- Eval(normalizer.yacas)
print(normalizer$value)
maxspeed <- max(agent.money.vector)

#Next, we create a sequence vector from 0 to maxspeed, by stepsize, and calculate the
#theoretical values at the points of the sequence vector:

stepsize <- 0.25
v.vec <- seq(0, 10, stepsize)
theoretical <- B(v.vec) / normalizer$value

#At the end, we plot the empirical/simulation distribution together with the theoretical distribution
#of particle speeds

hist(agent.money.vector, breaks = max(agent.money.vector) * 5,
  freq = FALSE, xlim = c(0, as.integer(maxspeed) + 5),
  ylab = "density", xlab = "speed of particles", main = "")
lines(v.vec, theoretical, lwd = 2, col = "blue")



