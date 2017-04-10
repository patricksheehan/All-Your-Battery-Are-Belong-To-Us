library(lpSolveAPI) # linear programming solver utilizing a variant of the simplex method
IMAGE.WIDTH <- 2560
IMAGE.HEIGHT <- 1440
IMAGE.RES <- 180

runExample <- function(output.diagnostics=F) {
  # example usage -- set wd to location of files
  setwd('~/all-your-batteries-are-belong-to-us/')
  usage.and.rates <- read.csv('usage_solar_rate_one_month.csv')
  battery <- lpSolve(usage.and.rates, output.diagnostics)
  for (i in 1:(length(battery) - 1)) {
    if (battery[i+1] != battery[i]) {
      battery[i] = battery[i+1] - battery[i]
    }
  }
  usage.and.rates$battery <- battery
  write.csv(usage.and.rates, file="optimization_result.csv")
  return (usage.and.rates)
}

lpSolve <- function(usage.and.rates, output.diagnostics=F) {
  usage <- usage.and.rates$usage
  objective <- usage.and.rates$rate
  storage <- 10 # kwh
  power <- 5 # kW
  
  num.vars <- length(usage) # length of the battery schedule
  num.constraints <- (num.vars-1)*2 + 1
  lp <- make.lp(num.constraints, num.vars) # number of constratins = num of non-slack decision variables
  set.bounds(lp, upper=rep(storage, num.vars))  # upper is always storage size of battery
  
  objective[1] = -1*usage.and.rates$rate[1]
  for (i in 2:num.vars) {
    objective[i] = usage.and.rates$rate[i-1] - usage.and.rates$rate[i]
  }
  
  set.objfn(lp, objective)
  
  for (i in 1:(num.vars-1)) { # set up constraints
    add.constraint(lp, c(1,-1), "<=", rhs = power, indices = c(i, i+1), lhs = -1*power)
  }
  add.constraint(lp, c(1), "=", 0, indices = c(1))
  
  lp.control(lp, sense="min", verbose=ifelse(output.diagnostics, "full", "important"), scaling="extreme")
  
  status.code <- solve(lp)
  optimum.schedule <- get.variables(lp)
  
  if (output.diagnostics == TRUE) {
    plotInputsOutputs(usage.and.rates, demand.rates, optimum.schedule) 
    write.lp(lp, "optimization_model.lp", type="lp")
  }
  
  return (optimum.schedule) # return kWh figures
}


# optional diagnostic plots
plotInputsOutputs <- function(usage.and.rates, demand.rates, optimum.schedule) {
  png('before_usage.png', width=IMAGE.WIDTH, height=IMAGE.HEIGHT, res=IMAGE.RES) # first, plot original usage
  plot(usage.and.rates$usage, type='l', col='blue',
       main="Load Profile Before Optimization", xlab="Interval (Hour)", ylab=' kWh')
  dev.off()
  
  png('rates.png', width=IMAGE.WIDTH, height=IMAGE.HEIGHT, res=IMAGE.RES) # first, plot original usage
  max.rate <-  max(usage.and.rates$rate)
  min.rate <- min(usage.and.rates$rate)
  plot(usage.and.rates$rate, type='l', col='red', xlab="Interval (Hour)", ylab='Rate ($/kWh)',
       main="Grid Variable Rate", ylim=c(min.rate,max.rate))
  dev.off()
  
  png('after_profile_combined.png', width=IMAGE.WIDTH, height=IMAGE.HEIGHT, res=IMAGE.RES)
  plot(usage.and.rates$usage, type='l', main='Grid Consumption and Onsite Generation after Optimization',
       xlab="Interval (Hour)", ylab="kWh", ylim=c(0,max(usage.and.rates$usage)), lty=2, col='blue')
  lines(optimum.schedule, col='red')
  legend("topright", c("Original Load","Battery Level"), lty=c(2,1), lwd=c(2.5,2.5),col=c("blue","red"))
  dev.off()
  # 
  # png('before_after_costs.png', width=IMAGE.WIDTH, height=IMAGE.HEIGHT, res=IMAGE.RES)
  # results <- data.frame(gen.kwh = optimum.schedule,
  #                       grid.kwh = usage.and.rates$usage - optimum.schedule)
  # before.grid.cost <- sum(usage.and.rates$usage * usage.and.rates$rate)
  # after.grid.cost <- sum(results$grid.kwh*usage.and.rates$grid.variable.rate)
  # after.demand.cost <- sum(by(results, as.factor(months(results$from)),
  #                             function(x) max(x$grid.kwh) * demand.rates$rate[1]))
  # after.gen.cost <- sum(results$gen.kwh * usage.and.rates$gen.variable.rate)
  # blah <- data.frame(before=c(before.grid.cost, before.demand.cost, 0),
  #                    after=c(after.grid.cost, after.demand.cost, after.gen.cost))
  # barplot(as.matrix(blah), col = c('blue', 'purple', 'red'), width=0.5,
  #         legend.text=c("Consumption Cost (variable)", "Demand Cost", "Generation Cost (variable)"),
  #         args.legend=list(x='topright'),
  #         ylab="Cost ($)",
  #         main="Total Variable Costs Before / After Optimization")
  # dev.off()
}





