;;Information:
;;when presented with a bet, the 3 types of gamblers will have different utility functions
;;For risk averse, we will assign a likelihood that will give resemble the utility curve of a risk averse gambler
;;For moderate, gamblers we can randomly distribute utility curves(some a bit risk averse, some problem)
;;For problem, assign utility curve that is risk seeking

;;
;; TURTLE VARIABLES
;;
;extensions [R]


turtles-own[
  money ;; money that turtle has at one point
  sentiment ;; agents sentiment towards betting (influenced by social factors)
  success ;; how successful the agent currently is in bets
  agentcolor ;; give agents a color variable
  heard-of-bet ;; did the agent hear that betting existss
  salary ;; monthly salary
  bankrupt ;; if you are bankrupt

  ;;M2: agent specific values further
  agent-friend-influence
  agent-affect-of-advertisement
  agent-winning-losing-influence
  agent-taxation-influence
  agent-principle
  agent-shame-decay
  agent-shame
]

breed [non-bettors non-bettor-one]
breed [problem-bettors problem-one]
breed [risk-averse-bettors risk-averse-one]


problem-bettors-own [ p-value ]
risk-averse-bettors-own [ p-value ]

;;
;; PATCH VARIABLES
;;

patches-own[
  times-bet-advertised  ;;
  neighborhood ;;
  delay-ticks ;; use this variable to have the patches change color for some ticks (can add to interface...)
]

;;
;; GLOBAL VARIABLES
;;

globals[
  betting-odds ; the global betting odds offered at that tick
  company-wins ;; money betting company wins
  numberBankrupt ;; tracking bankrupt agents
  num-bettors ;; number of betters
  number-of-bets-made
  sum-percentages ;;
  winning-outcome ;;
  average-problem
  average-risk-averse

  average-problem-shame
  average-risk-averse-shame

  total-profit
]

;;;
;;; SETUP
;;;

to setup
  clear-all
  reset-ticks
  setup-globals
  check-percentages
  setup-turtles
  setup-patches
  ifelse seed-randomly? = True
  [ seed-random ]
  [ seed-one ]
end

;;This procedure checks if the user specified percentages sum to 100 to get valid results
to check-percentages
  if sum-percentages != 100[
    user-message (word "The sum of percentages is not 100. Adjust accordingly.")
    stop
  ]
end

to setup-patches
  ask patches[
    set pcolor black
  ]
end

to setup-globals
  set company-wins 0
  set number-of-bets-made 0
  set numberBankrupt 0
  set sum-percentages sum (list percent-problem percent-risk-averse)
  set average-problem []
  set average-risk-averse []
  set average-problem-shame []
  set average-risk-averse-shame []

  if literature-values?
  [
    set average-salary 24631 ;; https://www.averagesalarysurvey.com/kenya
    set affect-of-advertisement 20.1 ;; https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4718651/
    set social-influence 64 ;; (Donati et al., 2013).
    set percent-problem 6.1
    set percent-risk-averse 93.9
    set gamblers-perc 60.5
    set tax-deterrent-perc 20
  ]



  set total-profit 0
end


to setup-turtles
  set-default-shape turtles "person"
  set num-bettors round(num-people * (gamblers-perc * 0.01))
  let new-tax-deterrent-perc tax-deterrent-perc * 0.01 ;; setting tax-deterrent-perc changes ui


  ; number of people that don't bet is number of gamblers minus number of people that bet
  let number-non-bet num-people - num-bettors
  ; 20% of population is problem
  let number-problem floor(percent-problem * 0.01 * num-bettors)
  ; rest is risk averse
  let number-risk-averse num-bettors - number-problem
  ;; temp values, (problem = 0.7, moderate = 0.4, risk-averse = 0.2, pathological=0.9) likelihood for taking the odds
  create-non-bettors number-non-bet
  [ set color magenta
    set shape "turtle" ;; indestructible turtle? ~ love it!

    ;;M2: update these values based on survey (agent-specific)...Nonbettors will not influence weights
    if survey-values?
    [
      set agent-friend-influence 1
      set agent-affect-of-advertisement 1
      set agent-winning-losing-influence 1 ;; average of friend winning vs losing influence
      set agent-taxation-influence 1;; high tax + low tax average weight
      set agent-principle 1
      set agent-shame-decay 1
      set agent-shame 0
    ]
  ]

  create-problem-bettors number-problem
  [ set p-value 0.7

    set color orange

    ;;M2: update these values based on survey (agent-specific)
    ifelse survey-values?
    [
      set agent-friend-influence 0.8
      set agent-affect-of-advertisement 0.7
      set agent-winning-losing-influence (0.70 - 0.53) / 2 ;; average of friend winning vs losing influence
      set agent-taxation-influence (0.83 + 0.44) / 2 ;; high tax + low tax average weight
      set agent-principle 0.57
      set agent-shame-decay 0.34
      set agent-shame 0
    ]
    [
      ;; survey values wasn't ticked, don't influence with weights (all are left as 1)
      set agent-friend-influence p-agent-friend-influence / 100
      set agent-affect-of-advertisement p-agent-affect-of-advertisement / 100
      set agent-winning-losing-influence p-agent-winning-losing-influence / 100  ;; average of friend winning vs losing influence
      set agent-taxation-influence p-agent-taxation-influence / 100 ;; high tax + low tax average weight
      set agent-principle p-agent-principle / 100
      set agent-shame-decay p-agent-shame-decay / 100
      set agent-shame 0
    ]

    set p-value p-value * (1 - new-tax-deterrent-perc * agent-taxation-influence)
  ]
  create-risk-averse-bettors number-risk-averse
  [ set p-value 0.2

    set color green

    ;;M2: update these values based on survey (agent-specific)
    ifelse survey-values?
    [
      set agent-friend-influence 0.43
      set agent-affect-of-advertisement 0.39
      set agent-winning-losing-influence (0.63 - 0.46) / 2 ;; average of friend winning vs losing influence
      set agent-taxation-influence (0.61 + 0.54) / 2 ;; high tax + low tax average weight
      set agent-principle 0.8
      set agent-shame-decay 0.23
      set agent-shame 0
    ]
    [
      ;; survey values wasn't ticked, don't influence with weights (all are left as 1)
      set agent-friend-influence ra-agent-friend-influence / 100
      set agent-affect-of-advertisement ra-agent-affect-of-advertisement / 100
      set agent-winning-losing-influence ra-agent-winning-losing-influence / 100  ;; average of friend winning vs losing influence
      set agent-taxation-influence ra-agent-taxation-influence / 100 ;; high tax + low tax average weight
      set agent-principle ra-agent-principle / 100
      set agent-shame-decay ra-agent-shame-decay / 100
      set agent-shame 0
    ]

    set p-value p-value * (1 - new-tax-deterrent-perc * agent-taxation-influence)
  ]

  ;; general turtle setup
  ask turtles
  [   move-to one-of patches
      set size 1.5 ;; easier to see
      set-initial-turtle-vars
  ]
end


to set-initial-turtle-vars
  set success 0 ;; begin with a success rate of 0
  set sentiment 0.5 ;; neutral sentiment to start from
  set times-bet-advertised 0 ;; they haven't been advertised to yet
  set salary random-normal (average-salary * (1 / 12)) (average-salary * (1 / 12) / 0.3) ;;number based on average salary in kenya. Mean at average-salary and std dev 0.3
  set money salary
  set heard-of-bet False
  set bankrupt False

  if survey-values?
  [
      set ra-agent-friend-influence 0.43 * 100
      set ra-agent-affect-of-advertisement 0.39 * 100
      set ra-agent-winning-losing-influence (0.63 - 0.46) / 2  * 100;; average of friend winning vs losing influence
      set ra-agent-taxation-influence (0.61 + 0.54) / 2 * 100 ;; high tax + low tax average weight
      set ra-agent-principle 0.8 * 100
      set ra-agent-shame-decay 0.23 * 100

      set p-agent-friend-influence 0.8 * 100
      set p-agent-affect-of-advertisement 0.7 * 100
      set p-agent-winning-losing-influence (0.70 - 0.53) / 2  * 100;; average of friend winning vs losing influence
      set p-agent-taxation-influence (0.83 + 0.44) / 2 * 100;; high tax + low tax average weight
      set p-agent-principle 0.57 * 100
      set p-agent-shame-decay 0.34 * 100

  ]


end

;; tell center patch about betting(advertise here)
to seed-one
  ask patch 0 0 [
    hear-bet
  ]
end

;; let random patches know of bet
to seed-random
  ask patches with [times-bet-advertised = 0] [
    if (random-float 100.0) < init-advertisements [
      hear-bet
    ]
  ]
end

;;
;; GO
;;

to go
  ask patches [
    check-patches-ticks
    hear-bet
  ]

  ask turtles [
    move-turtles
    ;;
    spread-bet ;; will spread the bet AND INFLUENCE of the person that says it to neighbors
    show-faces-for-money
  ]

  ;;generate odds and get the winning outcome
  generate-odds
  set winning-outcome seeIfWon betting-odds

  ;; turtles should bet (or be allowed to bet) each day and get income every month.
  ask problem-bettors [
    if not bankrupt [
      bet-problem
      if ticks mod 30 = 0
      [earn-income]
      decay-shame ;; decay shame every tick
    ]
  ]
  ask risk-averse-bettors [
    if not bankrupt [
      bet-risk-averse
      if ticks mod 30 = 0
      [earn-income]
      decay-shame ;; decay shame every tick
    ]
  ]

  ;; stop model if all users are bankrupt
  if all-bankrupt?
  [
    user-message (word "There are " numberBankrupt " Bankrupt People! That's all of the bettors!")
    stop
  ]

  ;; to use if you want to update the graphs to be more smooth
  tick

  if end-at-13k?
  [
    if ticks = 62500
    [
      user-message (word ticks " has passed. The model has stopped. To turn this off, uncheck end-at-13k?")
      stop
    ]

  ]
end

;;
;; PATCH METHODS
;;

;; function that lets patches hear the bet and displays the blue color
to hear-bet
  ;; randomly advertise to advertisement-perc of patches
  if random(100) < advertisement-perc * 0.01
  [
    set times-bet-advertised times-bet-advertised + 1 ;;

    ;; want to implement some sort of ui that shows that a bet was advertised
    if (pcolor != blue) and (pcolor != pink)
    [ set delay-ticks ticks
      set pcolor blue
    ]

    ask turtles-here[
      ifelse not heard-of-bet
      [ set heard-of-bet True] ; now the agent knows betting exists
      [ set sentiment sentiment + (affect-of-advertisement * agent-affect-of-advertisement / 1000)] ; heard of advertisment again. people are likely to only remember 10% of ads they hear about
    ]
  ]
end

;; check the delay-tick variable for each patch, and if >=2 ticks have passed since being
;; set up then, revert the color back to original black
to check-patches-ticks
  if ticks - delay-ticks >= 2
  [ set pcolor black ]
end

;;
;; TURTLE METHODS
;;

;; if winning of individual is high show UI
to show-faces-for-money
  if (([breed] of self) != non-bettors) ;; don't change shape of non-bettors
  [
    ifelse money > 38000
    [ set shape "face happy"]
    [
      ifelse (money < 10000) and (money > 0)
      [ set shape "face sad"]
      [
        ifelse (money <= 0)
        [ set shape "x"
          ;set color red ;; (leave color according to groups for now. Can change to make more obvious)]
        ]
        [ set shape "person"]
      ]
    ]
  ]
end


;;
;; method to spread the betting information around the patches' neighborhood.
;;
to spread-bet
  let neighbor nobody ; making a neighbor value equal no agent for now
  set neighbor one-of turtles-on neighbors ;;

  if random(100) < 33 * agent-friend-influence ;; 33% influence by peers on spreading of problem
  [
    if (neighbor != nobody) and ([breed] of self != non-bettors)
    ;; want to implement some sort of ui that shows that a bet was advertised
    [ ask patch-here
      [
        if (pcolor != blue) and (pcolor != pink)
        [ set delay-ticks ticks
          set pcolor pink
        ]
      ]

      ask neighbor [
        set heard-of-bet True ; now the agent knows betting exists
        set sentiment sentiment + (success * (1 + (social-influence * agent-winning-losing-influence / 100))) * (affect-of-advertisement * agent-affect-of-advertisement / 1000); the success of the one who advertises affect sentiment
      ]
    ]
  ]

end

;; create an array the size of the odds+1, so 7:1 means 8 slots. Randomly fall on one to determine if won or loss.
to-report seeIfWon [odds]
  let winArray n-values odds [0]
  set winArray lput 1 winArray
  let randompick one-of winArray
  report randomPick
end

;; generate a betting option every tick and broadcast. Those that want to participate can.
;; Thought about multiple options, but then you'd need to make some values that'd make agents pick one over other...
to generate-odds
  let max-extreme 16
  let min-extreme 1

  ;; Don't want to deal with arrays at the moment...might need to use extensions for that
  set betting-odds random(max-extreme - min-extreme) + min-extreme ; a random between [min_extreme, max_extreme-1]
end

;; decay agent's shame every time step
to decay-shame
  set agent-shame (agent-shame - agent-shame-decay * agent-shame) ;; decay the shame based on agents shame decay rate
end


;; the function that risk-averse-bettors use to bet
to bet-risk-averse

  if (heard-of-bet)
  [
    let curr-bet money-to-bet money
    let utility-func (p-value * (betting-odds ) * curr-bet + curr-bet) * (1 + agent-shame) - sentiment
    let p-winning (1 / (betting-odds + 1))
    let expected-payoff ((betting-odds * curr-bet) - (1 - p-winning) * curr-bet)
    ifelse (expected-payoff > utility-func)
    [
      set number-of-bets-made number-of-bets-made + 1
      ; see if agent wins
      ifelse winning-outcome = 1
      [ set money money + betting-odds * curr-bet
        set total-profit total-profit + betting-odds * curr-bet
        set success success + 1
        set company-wins (company-wins - betting-odds * curr-bet)
        decay-shame
      ]
      [ set money money - curr-bet
        set company-wins company-wins + curr-bet
        set total-profit total-profit - curr-bet
        set success success - 1
      ]
    ]
    [
      ;; M2: expected payout is not greater than the utility function. But agent has a chance of being
      ;; reckless and still betting anyways, thus gaining shame.

      ;; Depending on how principled you are, you are less likely to fall into irrational behavior and
      ;; recklessly bet.

     if (random 100 > (agent-principle * 100))
     [
       ;; recklessly bet despite utility function
       set agent-shame agent-shame + 0.1
       ;; go through with bet
       set number-of-bets-made number-of-bets-made + 1
       ; see if agent wins
       ifelse winning-outcome = 1
       [ set money money + betting-odds * curr-bet
         set total-profit total-profit + betting-odds * curr-bet
         set success success + 1
         set company-wins (company-wins - betting-odds * curr-bet)
         decay-shame
       ]
       [ set money money - curr-bet
         set company-wins company-wins + curr-bet
         set total-profit total-profit - curr-bet
         set success success - 1
       ]
     ]
    ]


    if money <= 0
    [ set bankrupt True]
  ]
end

;; the function that problem-bettors use to bet
to bet-problem
  if (heard-of-bet)
  [
    let curr-bet money-to-bet money
    let utility-func (p-value * (betting-odds ) * curr-bet + curr-bet) * (1 + agent-shame) - sentiment
    let p-winning (1 / (betting-odds + 1))
    let expected-payoff ((betting-odds * curr-bet) - (1 - p-winning) * curr-bet)
    ifelse (expected-payoff > utility-func)
    [
      set number-of-bets-made number-of-bets-made + 1
      ; see if he wins
      ifelse winning-outcome = 1
      [ set money money + betting-odds * curr-bet
        set total-profit total-profit + betting-odds * curr-bet
        set success success + 1
        set company-wins (company-wins - betting-odds * curr-bet)
        decay-shame
      ]
      [ set money money - curr-bet
        set company-wins company-wins + curr-bet
        set total-profit total-profit - curr-bet
        set success success - 1
      ]
    ]
    [
      ;; M2: expected payout is not greater than the utility function. But agent has a chance of being
      ;; reckless and still betting anyways, thus gaining shame.

      ;; Depending on how principled you are, you are less likely to fall into irrational behavior and
      ;; recklessly bet.

     if (random 100 > (agent-principle * 100))
     [
       ;; recklessly bet despite utility function
       set agent-shame agent-shame + 0.1
       ;; go through with bet
       set number-of-bets-made number-of-bets-made + 1
       ; see if agent wins
       ifelse winning-outcome = 1
       [ set money money + betting-odds * curr-bet
         set total-profit total-profit + betting-odds * curr-bet
         set success success + 1
         set company-wins (company-wins - betting-odds * curr-bet)
         decay-shame
       ]
       [ set money money - curr-bet
         set company-wins company-wins + curr-bet
         set total-profit total-profit - curr-bet
         set success success - 1
       ]
     ]
    ]
    if money <= 0
    [ set bankrupt True]
  ]

end

;; MOVE TURTLES
to move-turtles
  ;; picked direction

  let pick-dir random 4
  ifelse (pick-dir = 0)
  [ set heading 0 ]
  [ ifelse (pick-dir = 1)
    [ set heading 90 ]
    [ ifelse (pick-dir = 2)
      [ set heading 180 ]
      [ set heading 270 ]
    ]
  ]
  ;; move
  fd 1
end

;; reporting success of neighbors,
to-report check-neighbor-success
  ; checking influence of neighboring success
  ifelse sum [success] of turtles-on neighbors > 0
  [ report True ]
  [ report False ]
end

;; checking to see if everyone is bankrupt and can't bet anymore so terminate model
to-report all-bankrupt?
  let reportValue False
  ask turtles[
    set numberBankrupt count turtles with [money <= 0]
    if numberBankrupt = num-bettors
    [ set reportValue True ]
  ]
  report reportValue
end

;; reports the money that a person will currently be willing to bet
to-report money-to-bet [curr-money]
  let toReport random-normal ((((random(13) + 12) / 100) * curr-money) * (1 / 30)) abs((((((random(13) + 12) / 100) * curr-money) * (1 / 30)) * 0.5))
  ifelse toReport != 0
  [report toReport];; basically 12-25% of current money.
  [report curr-money]
end

;;let the agents earn the average income after 30 ticks, aka a month
to earn-income
  if not bankrupt ;; going bankrupt made them lose their job
  [ set money money + (salary * (1 / 12)) ] ;; monthly salary
end

