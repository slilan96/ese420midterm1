;;Notes
;; average bet price is $50
;; average proportion of monthly salary gambled 12%
;; do we update salary after certain ticks or no?
;; generate betting draws each time
;; population has fixed distribution of people who bet
;; randomly scatter these people in the patches, might end up with patches with no gamblers
;; possibly include way using interaction to choose where to start betting firm( use mouse to click on grid or randomly place one)

;;Other Variables that can be used are on the DOC (Maybe first code something then implement probability)


;;
;; TURTLE VARIABLES
;;

turtles-own[
  money ;; money that turtle has at one point
  success ;; how many neighbors are successful
  risk-tolerance ;; how likely to risk

]

;; Doing research trying to figure out what to do for agents. (can be found on Google Doc)
;; Need some categories of agents, some amount of money expenditure they have, some amount of
;; times they bet maybe, likelihood to bet. These types of numbers.

;; Problem Gamblers, Moderate-Risk Gamblers, Pathological Gamblers, and Gambler Averse
;; https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4500885/ (for first two profiles)
;; will need another source for last two (looking)
;;;;STATS
;; (Median Problem Gambler = 850 vs. Median Moderate-Risk Gambler = 57.5; p = 0.0003)
;; other possible model
breed [problem-bettors problem-one]
breed [moderate-bettors moderate-one]
breed [risk-averse-bettors risk-averse-one]
breed [pathological-bettors pathological-one]

;Segmenting casino gamblers by motivation: A cluster analysis of Korean gamblers
;http://www.academia.edu/33074366/Segmenting_casino_gamblers_by_motivation_A_cluster_analysis_of_Korean_gamblers
;; challenge/winning seekers,
;; only winning seekers,
;; light gambling seekers
;; multi-purpose seekers

;;A Model of Casino Gambling
;;https://marketing.wharton.upenn.edu/wp-content/uploads/2016/10/gb15b.pdf
;; naive: gambles as long as possible and only leaves after making some gains
;;        average losses is twice as large as sophisticated agent on average
;; sophisticated but unable to commit: doesn't gamble
;; sophisticated but able to commit: gambles as long as possible when winning, but leaves after accumulating loss

problem-bettors-own [
  likelihood
]

moderate-bettors-own [
  likelihood
]

risk-averse-bettors-own [
  likelihood
]

pathological-bettors-own [
  likelihood
]


;;
;; PATCH VARIABLES
;;

patches-own[
  times-bet-advertised ;; the person heard of the bet, and how many times they've heard it
  neighborhood ;; vision radius of the patch
]

;;
;; GLOBAL VARIABLES
;;

globals[
  betting-odds ; the global betting odds offered at that tick
  percent-pathological ; percent of pathological bettors in a population
  percent-moderate
  percent-problem
  percent-risk-averse
]

;;;
;;; SETUP
;;;

to setup
  clear-all
  setup-turtles
  setup-patches
  reset-ticks
end


to setup-patches
  ask patches [
    let rand random(2)
    ifelse rand = 1
      [ set pcolor yellow ]
      [ set pcolor yellow + 1]
  ]
end


to setup-turtles
  set-default-shape turtles "person"

  ; TODO: update these with values from literature

  ;; set the global vars for percent of population
  set percent-pathological 0.02
  set percent-moderate 0.40
  set percent-problem 0.20
  set percent-risk-averse 0.38

  ; 2% of population is pathological bettors
  let number-pathological floor(percent-pathological * num-people)

  ; 40% of population is moderate
  let number-moderate floor(percent-moderate * num-people)

  ; 20% of population is problem
  let number-problem floor(percent-problem * num-people)

  ; rest is risk averse
  let number-risk-averse num-people - number-problem - number-moderate - number-pathological

  ;; temp values, (problem = 0.7, moderate = 0.4, risk-averse = 0.2, pathological=0.9) likelihood for taking the odds
  create-problem-bettors number-problem
  [ set likelihood 0.7 ]

  create-moderate-bettors number-problem
  [ set likelihood 0.4 ]

  create-risk-averse-bettors number-problem
  [ set likelihood 0.2 ]

  create-pathological-bettors number-problem
  [ set likelihood 0.9 ]

  ;; general turtle setup
  ask turtles
  [ move-to one-of patches
      set size 1.5 ;; easier to see
      set-initial-turtle-vars
  ]
end


to set-initial-turtle-vars
  set money random 1000 ;;
  set risk-tolerance random 100 ;;randomly assign risk tolerance
  set success random 10 ;; TODO: change this, temporarily as such
  set times-bet-advertised 0
  set money random 100 ;; TODO: Do we want to do this?
  ;; We can make the model fall in a Pareto Law type distribution and work off that I guess
  ;; Might be better to initialize the model on top of a Pareto type structure already.
  ;; Or we just do a random distrubtion and ignore the these things. (I will do this for now)

end

;; let one patch know of bet
to seed-one
  ;; tell center patch about betting
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
    ifelse pcolor = yellow ; TODO: Change these to something relevant
      [ set pcolor yellow + 1 ] ; TODO: Change these to something relevant
      [ set pcolor yellow ] ; TODO: Change these to something relevant
  ]

  ask turtles [
    ;; IDEA: Can add breeds for different agents as such (from Rebellion Model):
    ;; Use this to model the different types of agents we will have.
    ; Rule M: Move to a random site within your vision
    ;if (breed = agents and jail-term = 0) or breed = cops [ move ]
    ;   Rule A: Determine if each agent should be active or quiet
    ;if breed = agents and jail-term = 0 [ determine-behavior ]
    ;  Rule C: Cops arrest a random active agent within their radius
    ;if breed = cops [ enforce ]

    move-turtles

    if ticks mod 5 = 0
    [ ; see if agents bet
      bet-problem
      bet-moderate
      bet-risk-averse
      bet-pathological
    ]

  ]
  tick
end

;;
;; PATCH METHODS
;;

to hear-bet
  if not heard-bet? [
    set times-bet-advertised times-bet-advertised + 1 ;;TODO: Make this not deterministic. Add social probabilities.
  ]

end

to-report heard-bet?
  report times-bet-advertised >= 0
end

to spread-bet
  let neighbor nobody
  set neighbor one-of neighbors ;;TODO: Make this not deterministic. Add social probabilities.
  ;; spread betting info by person
  ask neighbor [
    hear-bet ;;TODO: Make this not deterministic. Add social probabilities.
  ]
end


;;
;; TURTLE METHODS
;;

;; create an array the size of the odds+1, so 7:1 means 8 slots. Randomly fall on one to determine if won or loss.
to-report seeIfWon [odds]
  let boolArray n-values odds [True]
  set boolArray lput False boolArray
  report one-of boolArray
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
  if likelihood * 100 <  likelihood
  [
   let money-to-bet random (100) ; TODO: (can make these agent owned too) base random amount of money to bet upon literature as well

   ; see if he wins
   ifelse seeIfWon betting-odds
   [ set money money + betting-odds * money-to-bet ]
   [ set money money - money-to-bet ]
  ]
end

;; moderate-bettors
to bet-moderate
  if likelihood * 100 <  likelihood
  [
   let money-to-bet random (50) ; TODO: base random amount of money to bet upon literature as well

   ; see if he wins
   ifelse seeIfWon betting-odds
   [ set money money + betting-odds * money-to-bet ]
   [ set money money - money-to-bet ]
  ]
end

;; risk-averse-bettors
to bet-risk-averse
  if likelihood * 100 <  likelihood
  [
   let money-to-bet random (20) ; TODO: base random amount of money to bet upon literature as well

   ; see if he wins
   ifelse seeIfWon betting-odds
   [ set money money + betting-odds * money-to-bet ]
   [ set money money - money-to-bet ]
  ]
end

;; pathological-bettors
to bet-pathological
  if likelihood * 100 <  likelihood
  [
   let money-to-bet random (150) ; TODO: base random amount of money to bet upon literature as well

   ; see if he wins
   ifelse seeIfWon betting-odds
   [ set money money + betting-odds * money-to-bet ]
   [ set money money - money-to-bet ]
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

;; reporting success of neighbors, TODO: Find numbers for this and actually use the function. Currently isn't being used.
to-report check-neighbor-success
  ; checking influence of neighboring success
  ifelse sum [success] of turtles-on neighbors > 4
  [ report True ]
  [ report False ]
end


@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
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
11
74
84
107
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
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
269
210
302
init-advertisements
init-advertisements
0
10
7.0
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

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
