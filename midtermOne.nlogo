;;Information:
;;when presented with a bet, the 3 types of gamblers will have different utility functions
;;For risk averse, we will assign a likelihood that will give resemble the utility curve of a risk averse gambler
;;For moderate, gamblers we can randomly distribute utility curves(some a bit risk averse, some problem)
;;For problem, assign utility curve that is risk seeking

;;
;; TURTLE VARIABLES
;;
extensions [r]


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
  update-smoothing-graph
  update-smoothing-graph-shame
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
  update-smoothing-graph
  update-smoothing-graph-shame
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


;;helper function for the smoothing function
to-report help-smooth [arr window-sz curr-breed] ;; smooths the arrays in place according to window size
  ifelse length arr < window-sz
  [ set arr lput (mean [money] of curr-breed) arr]
  [ set arr (sublist arr 1 (length arr)) ;; get last 4 values of list
    set arr lput (mean [money] of curr-breed) arr] ;; add latest value to array
  report arr
end

;; smooth the output of average money based on last "window-size" average money of bettors
to update-smoothing-graph
  set average-problem (help-smooth average-problem smoothing-amount problem-bettors)
  set average-risk-averse (help-smooth average-risk-averse smoothing-amount risk-averse-bettors)

end

;;helper function for the smoothing function
to-report help-smooth-shame [arr window-sz curr-breed] ;; smooths the arrays in place according to window size
  ifelse length arr < window-sz
  [ set arr lput (mean [agent-shame] of curr-breed) arr]
  [ set arr (sublist arr 1 (length arr)) ;; get last 4 values of list
    set arr lput (mean [agent-shame] of curr-breed) arr] ;; add latest value to array
  report arr
end

;; smooth the output of average money based on last "window-size" average money of bettors
to update-smoothing-graph-shame
  set average-problem-shame (help-smooth-shame average-problem-shame 1 problem-bettors)
  set average-risk-averse-shame (help-smooth-shame average-risk-averse-shame 1 risk-averse-bettors)

end
@#$#@#$#@
GRAPHICS-WINDOW
690
29
1153
493
-1
-1
13.8
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
91
129
164
162
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
16
129
81
162
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
13
219
185
252
num-people
num-people
0
100
43.0
1
1
NIL
HORIZONTAL

SLIDER
15
77
192
110
init-advertisements
init-advertisements
0
10
5.6
0.1
1
NIL
HORIZONTAL

MONITOR
503
370
592
415
Problem
count problem-bettors
17
1
11

MONITOR
503
314
592
359
Risk Averse
count risk-averse-bettors
17
1
11

SWITCH
23
35
193
68
seed-randomly?
seed-randomly?
1
1
-1000

PLOT
9
502
510
770
Money of Bettors on Average
time
money
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"problem" 1.0 0 -817084 true "" "plot mean average-problem"
"risk-averse" 1.0 0 -13840069 true "" "plot mean average-risk-averse"

MONITOR
523
450
659
495
Company Winnings
company-wins
17
1
11

MONITOR
335
307
466
352
Number of People
num-people
17
1
11

MONITOR
333
365
479
410
Number of Bankrupt
count turtles with [bankrupt = True]
17
1
11

SLIDER
12
256
184
289
average-salary
average-salary
5000
30000
24631.0
1
1
NIL
HORIZONTAL

SLIDER
13
298
185
331
tax-deterrent-perc
tax-deterrent-perc
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
389
114
561
147
gamblers-perc
gamblers-perc
0
100
60.0
1
1
NIL
HORIZONTAL

MONITOR
601
314
682
359
# of bettors
num-bettors
17
1
11

SLIDER
17
381
189
414
advertisement-perc
advertisement-perc
0
100
52.0
1
1
NIL
HORIZONTAL

MONITOR
220
317
303
362
# bets made
number-of-bets-made
17
1
11

MONITOR
221
371
316
416
# heard of bet
count turtles with [heard-of-bet = True]
17
1
11

TEXTBOX
393
30
681
78
Reports and Graph Area
20
0.0
0

PLOT
521
505
861
769
Company winnings over time
time
Winnings
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot company-wins"

SLIDER
389
156
566
189
percent-problem
percent-problem
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
387
196
583
229
percent-risk-averse
percent-risk-averse
0
100
90.0
1
1
NIL
HORIZONTAL

MONITOR
389
64
535
109
sum of percentages
sum (list percent-problem percent-risk-averse)
17
1
11

SLIDER
82
780
275
813
smoothing-amount
smoothing-amount
1
50
1.0
1
1
NIL
HORIZONTAL

SWITCH
198
32
361
65
literature-values?
literature-values?
1
1
-1000

MONITOR
59
448
214
493
Total Sentiment of People
sum [sentiment] of turtles
17
1
11

MONITOR
224
448
368
493
Total Success of People
sum [success] of turtles
17
1
11

MONITOR
371
447
511
492
Total Profit
total-profit
17
1
11

SLIDER
12
180
237
213
affect-of-advertisement
affect-of-advertisement
1
100
45.0
1
1
NIL
HORIZONTAL

SLIDER
16
338
188
371
social-influence
social-influence
0
100
78.0
1
1
NIL
HORIZONTAL

SWITCH
1196
418
1357
451
survey-values?
survey-values?
1
1
-1000

PLOT
1166
30
1646
340
Averages of Agent Shame Graph
NIL
NIL
-10.0
10.0
-0.2
0.5
true
true
"" ""
PENS
"problem shame" 1.0 0 -5298144 true "" "plot mean [agent-shame] of problem-bettors"
"risk-averse shame" 1.0 0 -11085214 true "" "plot mean [agent-shame] of risk-averse-bettors"

SLIDER
1173
519
1377
552
ra-agent-friend-influence
ra-agent-friend-influence
0
100
79.0
1
1
NIL
HORIZONTAL

SLIDER
1172
555
1380
588
ra-agent-affect-of-advertisement
ra-agent-affect-of-advertisement
0
100
69.0
1
1
NIL
HORIZONTAL

SLIDER
1170
589
1382
622
ra-agent-winning-losing-influence
ra-agent-winning-losing-influence
0
100
8.5
1
1
NIL
HORIZONTAL

SLIDER
1173
625
1385
658
ra-agent-taxation-influence
ra-agent-taxation-influence
0
100
65.0
1
1
NIL
HORIZONTAL

SLIDER
1172
660
1384
693
ra-agent-principle
ra-agent-principle
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
1173
697
1381
730
ra-agent-shame-decay
ra-agent-shame-decay
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
1424
520
1610
553
p-agent-friend-influence
p-agent-friend-influence
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
1424
556
1657
589
p-agent-affect-of-advertisement
p-agent-affect-of-advertisement
0
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
1424
590
1654
623
p-agent-winning-losing-influence
p-agent-winning-losing-influence
0
100
8.4999
1
1
NIL
HORIZONTAL

SLIDER
1424
628
1623
661
p-agent-taxation-influence
p-agent-taxation-influence
0
100
63.5
1
1
NIL
HORIZONTAL

SLIDER
1424
664
1597
697
p-agent-principle
p-agent-principle
0
100
56.99
1
1
NIL
HORIZONTAL

SLIDER
1425
699
1598
732
p-agent-shame-decay
p-agent-shame-decay
0
100
34.0
1
1
NIL
HORIZONTAL

TEXTBOX
1428
460
1595
512
Problem Bettor Values:
20
0.0
1

TEXTBOX
1177
458
1344
510
Risk-Averse Bettor Values:
20
0.0
1

MONITOR
1197
363
1347
408
Risk-Averse Avg. Shame
mean [agent-shame] of risk-averse-bettors
17
1
11

MONITOR
1422
365
1589
410
Problem-Bettor Avg. Shame
mean [agent-shame] of problem-bettors
17
1
11

SWITCH
903
586
1023
619
end-at-13k?
end-at-13k?
1
1
-1000

TEXTBOX
904
543
1071
579
End at 13k Ticks for Equal Model Runs
14
0.0
1

TEXTBOX
1186
742
1645
796
Need to turn off survey-values above for these changes to be implemented.
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)
This is a model that tries to model the spread of betting and the effect on income to the betting population. This is based on the recent phenomena in some sub saharan coutries where the introduction of low income sports betting has catapulted the betting companies into corporate behemoths

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
