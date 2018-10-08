;;Notes
;; average bet price is $50
;; average proportion of monthly salary gambled 12%
;; do we update salary after certain ticks or no?(I think we should ~Shadrack)
;; generate betting draws each time
;; population has fixed distribution of people who bet
;; randomly scatter these people in the patches, might end up with patches with no gamblers
;; possibly include way using interaction to choose where to start betting firm( use mouse to click on grid or randomly place one)

;;Other Variables that can be used are on the DOC (Maybe first code something then implement probability)

;;additional information:
;;when presented with a bet, the 3 types of gamblers will have different utility functions
;;For risk averse, we will assign a likelihood that will give resemble the utility curve of a risk averse gambler
;;For moderate, gamblers we can randomly distribute utility curves(some a bit risk averse, some problem)
;;For problem, assign utility curve that is risk seeking






;;
;; TURTLE VARIABLES
;;

turtles-own[
  money ;; money that turtle has at one point
  sentiment ;; TODO: use this variable, what is the agents sentiment towards betting (influenced by social factors)
  success ;; TODO: use this variable, how successful the agent currently is in bets
  agentcolor ;; give agents a color variable
  heard-of-bet ;; did the agent hear that betting exists
]

;; Problem Gamblers, Moderate-Risk Gamblers, Pathological Gamblers, and Gambler Averse
;; https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4500885/
;;1) non-problem gamblers (score of 0);
;;2) risk-averse gamblers
;;3) moderate-risk gamblers
;;4) problem gamblers
;;5) pathological

breed [non-bettors non-bettor-one]
breed [problem-bettors problem-one]
breed [moderate-bettors moderate-one]
breed [risk-averse-bettors risk-averse-one]
breed [pathological-bettors pathological-one]


problem-bettors-own [ likelihood ]
moderate-bettors-own [ likelihood ]
risk-averse-bettors-own [ likelihood ]
pathological-bettors-own [ likelihood ]

;;
;; PATCH VARIABLES
;;

patches-own[
  times-bet-advertised  ;; TODO: we're tracking this, but not using it atm.
  neighborhood ;; TODO: use this variable, vision radius of the patch
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

  average-pathological
  average-problem
  average-moderate
  average-risk-averse

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
end

;;This procedure checks if the user specified percentages sum to 100 to get valid results
to check-percentages
  if sum-percentages != 100[
    user-message (word "The sum of percentages is not 100. Adjust accordingly")
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
  set sum-percentages sum (list percent-moderate percent-problem percent-pathological percent-risk-averse)
  set average-pathological []
  set average-problem []
  set average-moderate []
  set average-risk-averse []
end


to setup-turtles
  set-default-shape turtles "person"
  set num-bettors round(num-people * (gamblers-perc * 0.01))
  let new-tax-deterrent-perc tax-deterrent-perc * 0.01 ;; setting tax-deterrent-perc changes ui

  ; number of people that don't bet is number of gamblers minus number of people that bet
  let number-non-bet num-people - num-bettors
  ; 2% of population is pathological bettors
  let number-pathological ceiling(percent-pathological * 0.01 * num-bettors) ; ceil this because want at least 1
  ; 40% of population is moderate
  let number-moderate floor(percent-moderate * 0.01 * num-bettors)
  ; 20% of population is problem
  let number-problem floor(percent-problem * 0.01 * num-bettors)
  ; rest is risk averse
  let number-risk-averse num-bettors - number-problem - number-moderate - number-pathological

  ;; temp values, (problem = 0.7, moderate = 0.4, risk-averse = 0.2, pathological=0.9) likelihood for taking the odds
  create-non-bettors number-non-bet
  [ set color magenta
    set shape "turtle" ;; indestructible turtle? ~ love it!
  ]

  create-problem-bettors number-problem
  [ set likelihood 0.7
    set likelihood likelihood * (1 - new-tax-deterrent-perc)
    set color orange
  ]
  create-moderate-bettors number-moderate
  [ set likelihood 0.4
    set likelihood likelihood * (1 - new-tax-deterrent-perc)
    set color yellow
  ]
  create-risk-averse-bettors number-risk-averse
  [ set likelihood 0.2
    set likelihood likelihood * (1 - new-tax-deterrent-perc)
    set color green
  ]
  create-pathological-bettors number-pathological
  [ set likelihood 0.9
    set likelihood likelihood * (1 - new-tax-deterrent-perc)
    set color red
  ]

  ;; general turtle setup
  ask turtles
  [ move-to one-of patches
      set size 1.5 ;; easier to see
      set-initial-turtle-vars
  ]
end


to set-initial-turtle-vars
  set success 0 ;; begin with a success rate of 0
  set sentiment 0.5 ;; neutral sentiment to start from
  set times-bet-advertised 0 ;; they haven't been advertised to yet
  set money random-normal average-salary (average-salary / 0.3) ;;number based on average salary in kenya. Mean at average-salary and std dev 0.3
  set heard-of-bet False
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
    ;; TODO: Do something when a turtle hears a bet. Make it check to see if patch was advertised to...
    spread-bet ;; will spread the bet AND INFLUENCE of the person that says it to neighbors
    show-faces-for-money
  ]

  ;;generate odds and get the winning outcome
  generate-odds
  set winning-outcome betting-odds



  ;; turtles should bet each week(i.e that's when the bets occur)
  ask problem-bettors[
    bet-problem
  ]
  ask moderate-bettors [
    bet-moderate
  ]
  ask risk-averse-bettors [
    bet-risk-averse
  ]
  ask pathological-bettors[
    bet-pathological
  ]


  ask turtles [
    if ticks mod 15 = 0
    [earn-income]
  ]

  ;; stop model if all users are bankrupt
  if all-bankrupt?
  [
    user-message (word "There are " numberBankrupt " Bankrupt People! That's all of the bettors!")
    stop
  ]

  update-smoothing-graph
  tick
end

;;
;; PATCH METHODS
;;

to hear-bet

  ;; randomly advertise to advertisement-perc of patches
  if random(100) < advertisement-perc * 0.01
  [
    set times-bet-advertised times-bet-advertised + 1 ;; TODO: not using this atm

    ;; want to implement some sort of ui that shows that a bet was advertised
    if (pcolor != blue) and (pcolor != pink)
    [ set delay-ticks ticks
      set pcolor blue
    ]

    ask turtles-here[
      ifelse not heard-of-bet
      [ set heard-of-bet True] ; now the agent knows betting exists
      [ set sentiment sentiment + 0.1] ; heard of advertisment again. people are likely to only remember 10% of ads they hear about
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
    ifelse money > 1500
    [ set shape "face happy"]
    [
      ifelse (money < 500) and (money > 0)
      [ set shape "face sad"]
      [
        ifelse (money <= 0)
        [ set shape "x"
          set color red ;; (leave color according to groups for now. Can change to make more obvious)]
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
  set neighbor one-of turtles-on neighbors ;;TODO: is it right to just randomly pick one neighbor?

  if random(100) < 33 ;; 33% influence by peers on spreading of problem
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
        ;;TODO: Make this not deterministic. Add social probabilities.
        ;; want to implement some sort of ui that shows that a bet was advertised

        ;;will implement study done on rate of cocnversion
        set heard-of-bet True ; now the agent knows betting exists
        set sentiment sentiment + success * 1.64; the success of the one who advertises affect sentiment( need supporting literature)
      ]
    ]
  ]

end

;; create an array the size of the odds+1, so 7:1 means 8 slots. Randomly fall on one to determine if won or loss.
to-report seeIfWon [odds]
  let winArray n-values odds [0]
  set winArray lput 1 winArray
  let randompick one-of winArray
  ifelse randompick = 1
  [ report True ]
  [ report False]
end

;; generate a betting option every tick and broadcast. Those that want to participate can.
;; Thought about multiple options, but then you'd need to make some values that'd make agents pick one over other...
to generate-odds
  let max-extreme 16
  let min-extreme 1

  ;; Don't want to deal with arrays at the moment...might need to use extensions for that
  set betting-odds random(max-extreme - min-extreme) + min-extreme ; a random between [min_extreme, max_extreme-1]
end

;; problem-bettors
to bet-problem
  if heard-of-bet = False
  [ stop ]

  if (likelihood * 100 >  random(100)) and (money > 0) ;; so if likelihood * 100 gives me a number larger than the random chance in 1-100 then bet.
  [
   let curr-bet money-to-bet money
   set number-of-bets-made number-of-bets-made + 1
   ; see if agent wins
    ifelse winning-outcome = 1
   [ set money money + betting-odds * curr-bet
     set success success + 1
     set company-wins (company-wins - betting-odds * curr-bet)
   ]
   [ set money money - curr-bet
     set company-wins company-wins + curr-bet
     set success success - 1
   ]

  ]
end

;; moderate-bettors
to bet-moderate
  if heard-of-bet = False
  [ stop ]

  if (likelihood * 100 >  random(100)) and (money > 0)
  [
   let curr-bet money-to-bet money
   set number-of-bets-made number-of-bets-made + 1
   ; see if agent wins and remove money from company winnings
   ifelse winning-outcome = 1
   [ set money (money + betting-odds * curr-bet)
     set success success + 1
     set company-wins (company-wins - betting-odds * curr-bet)
   ]
   [ set money money - curr-bet
     set company-wins company-wins + curr-bet
     set success success - 1
   ]
  ]
end

;; risk-averse-bettors
to bet-risk-averse
  if heard-of-bet = False
  [ stop ]

  if (likelihood * 100 >  random(100)) and (money > 0)
  [
   let curr-bet money-to-bet money
   set number-of-bets-made number-of-bets-made + 1
   ; see if agent wins
   ifelse winning-outcome = 1
   [ set money money + betting-odds * curr-bet
     set success success + 1
     set company-wins (company-wins - betting-odds * curr-bet)
   ]
   [ set money money - curr-bet
     set company-wins company-wins + curr-bet
     set success success - 1
   ]
    set number-of-bets-made number-of-bets-made + 1
  ]
end

;; pathological-bettors
to bet-pathological
  if heard-of-bet = False
  [ stop ]

  if (likelihood * 100 >  random(100)) and (money > 0)
  [
   let curr-bet money-to-bet money
   set number-of-bets-made number-of-bets-made + 1
   ; see if he wins
   ifelse winning-outcome = 1
   [ set money money + betting-odds * curr-bet
     set success success + 1
     set company-wins (company-wins - betting-odds * curr-bet)
   ]
   [ set money money - curr-bet
     set company-wins company-wins + curr-bet
     set success success - 1
   ]
  ]
end

;;function to set utility function with each odds
to set-utility[odds]
  ask risk-averse-bettors [
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
;; TODO: Find numbers for this and actually use the function. Currently isn't being used.
to-report check-neighbor-success
  ; checking influence of neighboring success
  ifelse sum [success] of turtles-on neighbors > 4
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

to-report money-to-bet [curr-money]
  let toReport ceiling((((random(13) + 12) / 100) * curr-money) * 0.25)
  ifelse toReport != 0
  [report toReport];; basically 12-25% of current money.
  [report curr-money]
end

;;let the agents earn the average income after every 4 ticks i.e. for a month
to earn-income
    set money 10000
end

to-report help-smooth [arr window-size curr-breed] ;; smooths the arrays in place according to window size

  ifelse length arr < window-size
  [ set arr lput (mean [money] of curr-breed) arr]
  [ set arr (sublist arr 1 (length arr)) ;; get last 4 values of list
    set arr lput (mean [money] of curr-breed) arr] ;; add latest value to array
  report arr

end


;; smooth the output of average money based on last 5 average money of bettors
to update-smoothing-graph
  let window-size 100

  set average-pathological (help-smooth average-pathological window-size pathological-bettors)
  set average-problem (help-smooth average-problem window-size problem-bettors)
  set average-moderate (help-smooth average-moderate window-size moderate-bettors)
  set average-risk-averse (help-smooth average-risk-averse window-size risk-averse-bettors)

end
@#$#@#$#@
GRAPHICS-WINDOW
1208
10
1599
402
-1
-1
11.61
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
92
142
165
175
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
140
79
173
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
80.0
1
1
NIL
HORIZONTAL

SLIDER
9
79
209
112
init-advertisements
init-advertisements
0
10
4.5
0.1
1
NIL
HORIZONTAL

MONITOR
333
204
425
249
Pathological
count pathological-bettors
17
1
11

MONITOR
334
264
408
309
Moderate
count moderate-bettors
17
1
11

MONITOR
333
315
453
360
Problem
count problem-bettors
17
1
11

MONITOR
335
375
424
420
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
7
461
508
729
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
"pathological" 1.0 0 -8053223 true "" "plot mean average-pathological"
"moderate" 1.0 0 -1184463 true "" "plot mean average-moderate"
"problem" 1.0 0 -817084 true "" "plot mean average-problem"
"risk-averse" 1.0 0 -13840069 true "" "plot mean average-risk-averse"

MONITOR
559
270
695
315
Company Winnings
company-wins
17
1
11

MONITOR
333
87
464
132
Number of People
num-people
17
1
11

MONITOR
331
145
477
190
Number of Bankrupt
numberBankrupt
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
5000.0
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
12
337
184
370
gamblers-perc
gamblers-perc
0
100
100.0
1
1
NIL
HORIZONTAL

MONITOR
562
88
643
133
# of bettors
num-bettors
17
1
11

SLIDER
12
378
184
411
advertisement-perc
advertisement-perc
0
100
30.0
1
1
NIL
HORIZONTAL

MONITOR
560
212
643
257
# bets made
number-of-bets-made
17
1
11

MONITOR
562
153
657
198
# heard of bet
count turtles with [heard-of-bet = True]
17
1
11

TEXTBOX
353
23
641
71
Reports and Graph Area
20
0.0
0

PLOT
548
463
888
727
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
733
65
939
98
percent-pathological
percent-pathological
0
100
17.0
1
1
NIL
HORIZONTAL

SLIDER
732
109
909
142
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
730
156
923
189
percent-moderate
percent-moderate
0
100
36.0
1
1
NIL
HORIZONTAL

SLIDER
723
203
919
236
percent-risk-averse
percent-risk-averse
0
100
37.0
1
1
NIL
HORIZONTAL

MONITOR
994
79
1140
124
sum of percentages
sum (list percent-pathological percent-problem percent-moderate percent-risk-averse)
17
1
11

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
