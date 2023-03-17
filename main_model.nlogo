extensions [Rnd]

; ADD ANY GLOBAL VARIABLE HERE
globals [
  total-carbon-emissions
  count-good
  count-poor
  count-average
  carbon-tax
  net-trees-cut-per-tick
  economy-indicator
  init-rev-per-company
]

; ADD BREEDS HERE
breed [humans human]
breed [trees tree]
breed [companies company]

; Human definition
humans-own [
  behavior
  carbon-emissions
]

; Tree definition
trees-own [
  age
  absorption-rate
  growth-rate
]

; Company definition
companies-own [
  scale
  emissionQty
  emissionQtyPerTick
  revenueAmt
  penPerTick
  netPenalty
  age
  numTreesCut
]

to setup
  clear-all
  reset-ticks

  ;Carbon emissions
  set total-carbon-emissions 0

  ; the carbon tax to individuals
  set carbon-tax 0.1

  ;Revenue Per Company
  set init-rev-per-company 100

  set plant-policy false

  ; tree set up
  create-trees num-trees [
    set age random 30
    set absorption-rate random-float 20
    set growth-rate random-float 0.01 ; set a random growth rate for each tree
    setxy (random-float 16) (random-float 16)
    set shape "tree"
    set color green
    set size 0.4
  ]
  ;set-default-shape trees "circle"

  ; human set up
  create-humans num-good-turtles [
    setxy one-of (range -15 15 0.01) one-of (range -15 1 0.01)
    set color green
    set behavior "good"
    set shape "person"
    set carbon-emissions 0.1
  ]
    create-humans num-average-turtles [
    setxy one-of (range -15 15 0.01) one-of (range -15 1 0.01)
    set color yellow
    set behavior "average"
    set shape "person"
    set carbon-emissions 0.5
  ]
    create-humans num-bad-turtles [
    setxy one-of (range -15 15 0.01) one-of (range -15 1 0.01)
    set color red
    set behavior "poor"
    set shape "person"
    set carbon-emissions 1
  ]

  ; company set up
  create-companies num-companies [

    set shape "factory"
    set heading 0
    setxy (-16 + random-float 16) (random-float 16)
    set age 1

    set revenueAmt 100
    set netPenalty 0

    set scale revenueAmt - netPenalty     ; Companies start off with some size

    set emissionQty scale * 0.10
    set numTreesCut 0
  ]

  ; patch set up
  set-patch-size 15
  resize-world min-pxcor max-pxcor min-pycor max-pycor
  ask patches [
    set pcolor white ; set the color of each patch to black
  ]

end

to go
  ; TREE PROCEDURE
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ask trees [
    set age age + 1
    set size size + growth-rate * age * 0.1
    ; increase size based on growth rate
    set absorption-rate absorption-rate + 0.25
    if age >= 30 [
      die
    ]
    set total-carbon-emissions total-carbon-emissions - absorption-rate
    tree-reproduce
    ; the tree is 30 years old and generate a new tree in a random nearby patch
  ]
  ;Plant Policy function
  if plant-policy [
    plant-policy-on
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; HUMAN PROCEDURE
  set count-poor 0
  set count-average 0
  set count-good 0
  ask humans [
    (ifelse
    behavior = "good" [
          set count-good count-good + 1
          set color green
          set total-carbon-emissions total-carbon-emissions - 0.25
    ]
    behavior = "average" [
          set count-average count-average + 1
          set color yellow
          set total-carbon-emissions total-carbon-emissions + 0.5
    ]
    [
          set count-poor count-poor + 1
          set color red
          set total-carbon-emissions total-carbon-emissions + 1
  ])
    ; Rate of human deaths :(
    if random-float 1 < 0.10 [die]
    ; Basic functionalities
    move
    reproduce
    ; Modelling Herd Behavior
    change-behavior
    ; Humans like incentives
    let reward reward-function self
    if reward-driven [act-on-reward reward]
    ;if total-carbon-emissions > 20000 [save-planet]
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; COMPANY PROCEDURE
  set net-trees-cut-per-tick 0
  ;economy-indicator stores mean of revenue of companies. Used for human hatching
  set economy-indicator (mean [revenueAmt] of companies) / init-rev-per-company

  ask companies [

    ;Age as ticks pass by
    set age age + 0.1

    ;Check penalty
    checkPenPerTick
    set netPenalty netPenalty + penPerTick
    ;Penalty affects revenue
    set revenueAmt (revenueAmt - penPerTick)

    ;Revenue grows as a Brownian Motion
    let tickRevenueGrowth exp(0.01 * (random-normal 0 1) + 0.01)
    set revenueAmt (revenueAmt * tickRevenueGrowth)

    ;Scale might be a function of revenue amt. Setting equal to it for now
    set scale revenueAmt

    ;Trees Cut and Emissions
    let tickTreesCut (scale * 0.0001)
    set net-trees-cut-per-tick (net-trees-cut-per-tick + tickTreesCut)
    ;let tickTreesCut (0)

    ;;;;;;;;;;;;
    ;let tickEmissionQty (scale * 0.02 + revenueAmt * 0.01)
    let tickEmissionQty (scale * 0.2)
    set emissionQtyPerTick tickEmissionQty

    ;;;;;;;;;;;;

    ;Change globals
    ;set num-trees num-trees - tickTreesCut
    set total-carbon-emissions total-carbon-emissions + tickEmissionQty

    ;Revenue
    ;let tickNetRevenueChange revenueAmt - penPerTick
    ;let tickNetRevenueChange scale * 0.10 - penPerTick


    set emissionQty (emissionQty + tickEmissionQty)
    set numTreesCut (numTreesCut + tickTreesCut)
    ;set revenueAmt (revenueAmt + tickNetRevenueChange)

  ]

  ;kill trees cut by companies
  let agents-to-delete rnd:weighted-n-of net-trees-cut-per-tick trees [1 / count trees]
  ; delete the selected agents
  ask agents-to-delete [ die ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;INSERT OTHER PROCEDURES HERE


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  tick
end

; TREE FUNCTIONS - DO NOT MODIFY
to tree-reproduce
   if age >= 5[
   if random-float 100 < tree-growth-rate[

    hatch  1 [
        set age 0
        set absorption-rate random-float 20
        set growth-rate random-float 0.01 ; set a random growth rate for each tree
        setxy (random-float 16) (random-float 16)
        set shape "circle"
        set color green
        set size 0.4 ]
  ]
  ]
end

to plant-policy-on
   create-trees 30 [
    set age 0
    set absorption-rate random-float 5
    set growth-rate random-float 0.01 ; set a random growth rate for each tree
    setxy (random-float 16) (random-float 16)
    set shape "tree"
    set color green
    set size 0.4
  ]
end


; HUMAN FUNCTIONS - DO NOT MODIFY

; human herd behavior modeling
to change-behavior
  let threshold 0.5
  let num-good count humans in-radius 5 with [behavior = "good"]
  let num-average count humans in-radius 5 with [behavior = "average"]
  let num-poor count humans in-radius 5  with [behavior = "poor"]

  let total count humans in-radius 5
  let prop-good num-good / total
  let prop-average num-average / total
  let prop-poor num-poor / total
  let majority ""
   (ifelse
    prop-good >= prop-average and prop-good >= prop-poor [
      set majority "good"
      ;set pcolor green
    ]
    prop-average >= prop-poor [
      set majority "average"
      ;set pcolor yellow
    ]
    [
      set majority "poor"
      ;set pcolor red
  ])

  ask humans-here [
    if (behavior != majority) and (random-float 1 < prob-influence) and prob-influence != 0 [
      set behavior majority
    ]
  ]
end

; Human moving function
to move
    let xcor-bound 16 ; set x-coordinate bound
    let ycor-bound 0 ; set y-coordinate bound

    ; move turtles randomly within the bounds
    let new-xcor xcor + random-float 2 - 1 ; random-float generates a number between -1 and 1
    let new-ycor ycor + random-float 2 - 1

    ; bound turtle movements to bottom half of world
    if new-xcor <= xcor-bound and new-ycor <= ycor-bound [
      set xcor new-xcor
      set ycor new-ycor
    ]
end

; human reproducing function
to reproduce

  let potential-partner one-of humans-on neighbors
  if potential-partner != nobody and random-float 1 < 0.15 [
    hatch-humans 1 [
    setxy one-of (range -15 15 0.01) one-of (range -15 1 0.01)
      (ifelse
        inheritance [set behavior one-of (list ([behavior] of myself) ([behavior] of potential-partner))]
        [set behavior one-of ["good" "average" "poor"]]
       )
    set shape "person"

      (if (economy-indicator > 1)[

        let randNum random (1)
        if randNum = 1[
          set behavior "bad"
        ]
        ]
        )

      ;(if random (economy-indicator > 1) [set behavior "bad"]
      ;)
    (ifelse
        behavior = "good" [set carbon-emissions 1]
        behavior = "average" [set carbon-emissions 5]
        [set carbon-emissions 10]
      )
    ]
  ]
end

 ; human optimizing function - work in progress
to-report reward-function [agent]
  let n humans-on neighbors
  let carbon-mean carbon-emissions
  if any? n [set carbon-mean mean [carbon-emissions] of n]
  let penalty (carbon-emissions - carbon-mean) ^ 2
  let carbon-cost carbon-emissions * carbon-tax ; Calculate the cost of emitting carbon
  let reward (1 / carbon-emissions) - penalty - carbon-cost ; Update the reward function to include the cost of emitting carbon
  report reward
end

to act-on-reward [amount]
  let delta-carbon-emission 0 ; Initialize the change in carbon emission
    if amount > 0 [
      set delta-carbon-emission 0.1 ; Increase carbon emission if the reward is positive
    ]
    if amount < 0 [
      set delta-carbon-emission -0.1 ; Decrease carbon emission if the reward is negative
    ]
    set carbon-emissions carbon-emissions + delta-carbon-emission - random-float 1; Update the agent's carbon emission variable
  (ifelse
    carbon-emissions <= 5 [
      set behavior "average"
    ]
    carbon-emissions <= 1 [
      set behavior "poor"
    ]
    [set behavior "good"]
  )
end

to save-planet
  (ifelse
    behavior = "poor"
    [set behavior "average"
      set carbon-emissions 5]
    behavior = "average"
    [set behavior  "good"
      set carbon-emissions 1]
  )
end

; Penalty for companies
to checkPenPerTick  ; checking for penalties

  set penPerTick 0

  (ifelse
    total-carbon-emissions >= pen-lvl-3 [ set penPerTick revenueAmt * 0.05 ]
    total-carbon-emissions >= pen-lvl-2 [ set penPerTick revenueAmt * 0.02 ]
    total-carbon-emissions >= pen-lvl-1 [ set penPerTick revenueAmt * 0.01 ]
    )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INSERT OTHER FUNCTIONS HERE







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
1293
15
1796
519
-1
-1
15.0
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
1
1
1
ticks
30.0

SLIDER
16
420
188
453
num-good-turtles
num-good-turtles
100
150
150.0
1
1
NIL
HORIZONTAL

SLIDER
16
461
188
494
num-average-turtles
num-average-turtles
100
150
150.0
1
1
NIL
HORIZONTAL

SLIDER
15
501
187
534
num-bad-turtles
num-bad-turtles
100
150
150.0
1
1
NIL
HORIZONTAL

SLIDER
20
342
212
375
tree-growth-rate
tree-growth-rate
0
10
2.0
0.2
1
NIL
HORIZONTAL

BUTTON
203
423
266
456
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
199
468
262
501
NIL
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

SLIDER
13
169
185
202
prob-influence
prob-influence
0
0.15
0.04
0.02
1
NIL
HORIZONTAL

SWITCH
16
244
144
277
reward-driven
reward-driven
0
1
-1000

PLOT
491
15
1031
188
co2 Level
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Co2" 1.0 0 -16777216 true "" "plot total-carbon-emissions"

SWITCH
16
86
127
119
inheritance
inheritance
1
1
-1000

PLOT
489
231
838
439
# Behaviors
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"good" 1.0 0 -11085214 true "" "plot count-good"
"average" 1.0 0 -1184463 true "" "plot count-average"
"poor" 1.0 0 -5298144 true "" "plot count-poor"

PLOT
843
231
1043
437
# trees
NIL
NIL
0.0
20.0
0.0
3000.0
true
false
"" ""
PENS
"trees" 1.0 0 -13840069 true "" "plot count trees"

TEXTBOX
16
123
453
161
Herd Behavior Modelling\nIf not 0, prob-influence is the probability of being influenced by surrounding humans\nElse, no humans will be influences
10
117.0
1

TEXTBOX
20
57
453
81
The Inheritance switch, models wether newborns take one of the parent's behavior or if they randomly are given a behavior
10
117.0
1

TEXTBOX
16
210
420
237
If the reward-driven switch is on, humans will take into account carbon-tax and will alter their emissions to maximize a reward
10
117.0
1

TEXTBOX
19
33
169
51
Humans
14
114.0
1

TEXTBOX
19
299
169
317
Trees
14
114.0
1

TEXTBOX
20
321
297
339
Sliders to select rate of tree growth and cutting speed
10
117.0
1

TEXTBOX
20
389
170
407
Companies
14
114.0
1

MONITOR
489
185
706
230
NIL
total-carbon-emissions
17
1
11

PLOT
1042
15
1268
191
plot mean [emissionQtyPerTick] of companies
NIL
NIL
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [emissionQtyPerTick] of companies"

MONITOR
1059
219
1264
264
NIL
mean [emissionQty] of companies
3
1
11

MONITOR
1082
275
1250
320
NIL
mean [scale] of companies
3
1
11

MONITOR
1068
335
1267
380
NIL
mean [netPenalty] of companies
3
1
11

INPUTBOX
16
538
115
599
num-trees
2400.0
1
0
Number

INPUTBOX
18
600
117
661
num-companies
1200.0
1
0
Number

MONITOR
1088
390
1248
435
NIL
mean [age] of companies
1
1
11

INPUTBOX
496
486
652
547
pen-lvl-1
20000.0
1
0
Number

INPUTBOX
496
545
652
606
pen-lvl-2
40000.0
1
0
Number

INPUTBOX
496
603
652
664
pen-lvl-3
60000.0
1
0
Number

SWITCH
190
246
322
279
plant-policy
plant-policy
1
1
-1000

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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
NetLogo 6.3.0
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
