__includes [
  "code/utils.nls" "code/nn_positionNodes.nls" "code/backpropagation.nls" "code/activation-functions.nls" "code/learningutils.nls" "code/cross_validation.nls"
  "code/n-bit-parity.nls"
  "code/data-util.nls"
  "code/simulated-annealing.nls"
  "code/ffnn-common.nls"
  "testing/test-backpropagation.nls"
  "modular/modular.nls"
  "modular/homogenous.nls"
  "modular/heterogenous.nls"
  "modular/core.nls"
  "modular/train.nls"
  "modular/plotting-modular.nls"
  ]

extensions [ table ]

;; link-type -> remove if only create-links-to remains
links-own [
  weight
  link-type
  velocity
]

breed [ bias-nodes bias-node ]
breed [ input-nodes input-node ]
breed [ output-nodes output-node ]
breed [ hidden-nodes hidden-node ]

bias-nodes-own [
  activation
  input-bias?
  layer
  added-to-layer?
]

input-nodes-own [ activation ]

output-nodes-own [ activation local-field err local-gradient ]

hidden-nodes-own [

  local-field
  activation
  layer
  local-gradient
  err
]

globals [

  num-in-nodes
  num-out-nodes
  nodes-per-hidden-layer

  connection-link-type

  ;;;;;;;;
  ff-connections-color

  learning-connections-color
]

to startup

  setup

end

to setup

  clear-all

  reset-ticks

  ask patches [ set pcolor 9.5 ]

  set connection-link-type "connection-link"

  set-default-shape bias-nodes "bias-node"
  set-default-shape input-nodes "circle"
  set-default-shape output-nodes "output-node"
  set-default-shape hidden-nodes "output-node"
  set-default-shape links "small-arrow-shape"

  set ff-connections-color cyan
  set learning-connections-color red

  set num-in-nodes num-input-nodes
  set num-out-nodes num-output-nodes

  set hidden-layer-seq -1
  set hidden-layer-num-nodes -1

  set nodes-per-hidden-layer table:make

  ifelse auto-hidden-number-of-nodes?
  [
    let num-hid-nodes ceiling ( ( num-in-nodes + num-out-nodes ) / 2 )
  ]
  [
    ifelse uniform-hidden-layers?
    [
      init-nodes-per-hidden-layer num-nodes-per-hidden-layer
    ]
    [
      init-nodes-per-hidden-layer 0

      ask-user-input-num-nodes-per-layer
    ]
  ]

  create-nodes
  position-nodes

  full-connect-all-layers

  if not any-above 10
  [
    ask turtles
    [
      set size 2
    ]
  ]

  recolor

end

to full-connect-layers [ from _to ]

  ask from
  [
    create-links-to _to
    [
      set link-type connection-link-type
      set velocity 0
      set weight ( runresult ( word w-random " " wrandom-mean " - " (wrandom-mean / 2) " " ifelse-value ( w-random = "random-normal" ) [ ( word std-deviation ) ] [ "" ] ) )
      set label-color black
      set color ff-connections-color
    ]
    ;create-links-from _to [ set hidden? true set color learning-connections-color set link-type "learning-link" ]
  ]

end

to full-connect-all-layers

  ifelse num-hidden-layers <= 0
  [
    full-connect-layers ( turtle-set input-nodes ( bias-nodes with [ input-bias? ] ) ) output-nodes
  ]
  [
    full-connect-layers ( turtle-set input-nodes ( bias-nodes with [ input-bias? ] ) ) ( hidden-nodes with [ layer = 0 ] )

    foreach ( n-values ( num-hidden-layers - 1 ) [ ? ] )
    [
      full-connect-layers ( turtle-set ( hidden-nodes with [ layer = ? ] ) ( bias-nodes with [ layer = ? ] ) ) ( hidden-nodes with [ layer = ? + 1 ] )
    ]

    full-connect-layers ( turtle-set ( hidden-nodes with [ layer = num-hidden-layers - 1 ] ) ( bias-nodes with [ layer = num-hidden-layers - 1 ] ) ) ( output-nodes )
  ]
  ;; Missing create links from output nodes to last hidden layer nodes

end

to-report any-above [input]

  foreach table:keys nodes-per-hidden-layer
  [
    if table:get nodes-per-hidden-layer ? > 10
    [ report true ]
  ]

  report false

end

to create-nodes

  if ( bias-on? )
  [
    create-bias-nodes num-hidden-layers + 1
    [
      set color yellow
      set activation 1
      set layer -1
      set added-to-layer? false
      set input-bias? false
    ]
  ]

  create-input-nodes num-in-nodes [ set color green ]
  create-output-nodes num-out-nodes [ set color red]

  foreach table:keys nodes-per-hidden-layer
  [
    create-hidden-nodes table:get nodes-per-hidden-layer ?
    [
      set layer ?
      set color blue
    ]
  ]

end

to ask-user-input-num-nodes-per-layer

  let i 0

  while [ i < num-hidden-layers ]
  [
    let s-num user-input ( word "Enter number of nodes for layer " i )

    let optionNum ( tryRunResult ( task [ read-from-string s-num ] ) )

    if is-number? optionNum
    [
      table:put nodes-per-hidden-layer i optionNum
      set i i + 1
    ]
  ]

end

to init-nodes-per-hidden-layer [value]

  let i 0

  while [ i < num-hidden-layers ]
  [
    table:put nodes-per-hidden-layer i value

    set i i + 1
  ]

end

to update-layer [ layer-num num-nodes ]

  table:put nodes-per-hidden-layer layer-num num-nodes

end

to begin-train

  ifelse training-algorithm = "back-propagate" or training-algorithm  = "back-propagate (update weights layer-by-layer)"
  [
    backpropagation-train load-data num-hidden-layers
  ]
  [
    if training-algorithm = "simulated annealing"
    [
      simulated-annealing-train load-data num-hidden-layers
    ]
  ]

end

to-report load-data

  let num-examples-predefined 1000

  report ifelse-value ( data-source = "test" ) [ choose-test num-examples-predefined ] [ report-dataset ]

end

to-report choose-test [ num-examples-predefined ]

  report ifelse-value ( target-function = "n-bit-parity" ) [ generate-n-bit-parity-dataset num-examples-predefined ] [ generate-test-dataset num-examples-predefined ]

end
@#$#@#$#@
GRAPHICS-WINDOW
604
8
1408
636
-1
-1
6.562
1
10
1
1
1
0
0
0
1
0
120
-90
0
0
0
1
ticks
30.0

SLIDER
23
60
201
93
num-input-nodes
num-input-nodes
2
20
4
1
1
NIL
HORIZONTAL

SLIDER
25
104
186
137
num-output-nodes
num-output-nodes
1
20
1
1
1
NIL
HORIZONTAL

BUTTON
21
14
140
47
Setup network
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
215
11
405
44
num-hidden-layers
num-hidden-layers
0
30
1
1
1
NIL
HORIZONTAL

SLIDER
214
54
405
87
num-nodes-per-hidden-layer
num-nodes-per-hidden-layer
1
30
4
1
1
NIL
HORIZONTAL

SWITCH
213
97
445
130
auto-hidden-number-of-nodes?
auto-hidden-number-of-nodes?
1
1
-1000

MONITOR
26
147
494
192
Nodes per hidden layer
nodes-per-hidden-layer
17
1
11

INPUTBOX
150
202
289
262
hidden-layer-num-nodes
-1
1
0
Number

BUTTON
308
201
475
234
Update hidden layer table
if is-number? hidden-layer-seq and is-number? hidden-layer-num-nodes\nand hidden-layer-seq >= 1 and hidden-layer-seq <= 10\nand hidden-layer-num-nodes >= 1 and hidden-layer-num-nodes <= 30 \n[ \n update-layer hidden-layer-seq hidden-layer-num-nodes\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
412
11
601
44
uniform-hidden-layers?
uniform-hidden-layers?
0
1
-1000

INPUTBOX
28
200
140
260
hidden-layer-seq
-1
1
0
Number

SLIDER
425
454
597
487
logistic-param-a
logistic-param-a
1
25
1
1
1
NIL
HORIZONTAL

SLIDER
448
315
597
348
wrandom-mean
wrandom-mean
0.1
1
0.2
0.1
1
NIL
HORIZONTAL

CHOOSER
316
316
440
361
w-random
w-random
"random-float" "random-normal" "random-poisson" "random-exponential"
0

SLIDER
446
351
598
384
std-deviation
std-deviation
0.1
0.5
0.2
0.1
1
NIL
HORIZONTAL

CHOOSER
431
405
600
450
activation-function
activation-function
"step" "logistic" "hyperbolic-tangent" "softsign"
1

SLIDER
462
494
596
527
ahyper-const
ahyper-const
0.1
4
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
461
535
597
568
bhyper-const
bhyper-const
0.1
4
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
154
322
303
355
learning-rate
learning-rate
0
1.0
0.5
0.001
1
NIL
HORIZONTAL

SLIDER
156
364
300
397
momentum
momentum
-0.9
0.9
0.2
0.01
1
NIL
HORIZONTAL

PLOT
10
409
418
592
Error vs Epochs
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"epoch-error" 1.0 0 -11221820 true "" "plot epoch-error"
"validation-error" 1.0 0 -13840069 true "" "plot validation-error"
"test-error" 1.0 0 -2674135 true "" "plot test-error"
"f-error" 1.0 0 -7500403 true "" "plot f-error"

BUTTON
612
651
749
684
Test backprop with
test-backpropagation
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
756
643
894
688
target-function
target-function
"or" "and" "xor" "nand" "nor" "n-bit-parity"
5

CHOOSER
8
359
146
404
data-source
data-source
"file" "procedure" "test"
2

BUTTON
8
318
145
351
Load data
set-dataset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
335
617
463
650
show-weights?
show-weights?
0
1
-1000

CHOOSER
900
643
1038
688
input-1
input-1
0 1
0

CHOOSER
1048
642
1186
687
input-2
input-2
0 1
0

BUTTON
1197
649
1260
682
Test
user-entered-test input-1 input-2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
16
614
313
659
training-algorithm
training-algorithm
"back-propagate" "back-propagate (update weights layer-by-layer)" "simulated annealing"
1

SLIDER
11
722
419
755
T
T
0
10
10
0.05
1
NIL
HORIZONTAL

CHOOSER
12
812
150
857
SA-termination
SA-termination
"temperature" "MSE" "iterations"
0

SLIDER
11
763
419
796
iterations
iterations
0
20000
1500
100
1
NIL
HORIZONTAL

SLIDER
10
863
423
896
T-min
T-min
0
1
0.015
0.005
1
NIL
HORIZONTAL

SLIDER
7
906
420
939
MSE-threshold
MSE-threshold
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
432
763
684
796
cooling-factor
cooling-factor
0
1
0.85
0.05
1
NIL
HORIZONTAL

BUTTON
17
673
119
706
NIL
begin-train
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
429
720
790
753
preturb-limit
preturb-limit
0
2
0.2
0.01
1
NIL
HORIZONTAL

SWITCH
459
54
570
87
bias-on?
bias-on?
1
1
-1000

SLIDER
1489
19
1661
52
partition-size
partition-size
2
10
2
1
1
NIL
HORIZONTAL

SLIDER
1477
62
1664
95
num-modular-networks
num-modular-networks
1
4
1
1
1
NIL
HORIZONTAL

BUTTON
1683
16
1872
49
Make n modular networks
make-n-modular-networks
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
1700
68
1861
101
Begin train modular
begin-train-modular
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
429
809
684
842
weight-bound
weight-bound
0
5
2
1
1
NIL
HORIZONTAL

SLIDER
426
575
598
608
step-threshold
step-threshold
0
1
0.5
0.1
1
NIL
HORIZONTAL

MONITOR
181
804
250
849
NIL
T-usable
17
1
11

MONITOR
1474
120
1822
165
Activation of input-nodes
input-activations
17
1
11

MONITOR
1474
178
1820
223
Activation of output-nodes
output-activations
17
1
11

SWITCH
1420
236
1559
269
clip-weights?
clip-weights?
1
1
-1000

BUTTON
1576
236
1708
269
Train by module
train-by-module
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
1724
239
1856
272
Train by module
train-by-module
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1418
281
1841
568
Error vs Epochs per module
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"epoch-error" 1.0 0 -2674135 true "" "plot epoch-error"
"module-0" 1.0 0 -5207188 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 0 [ plot item 0 epoch-errors-per-module ]"
"module-1" 1.0 0 -1184463 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 1 [ plot item 1 epoch-errors-per-module ]"
"module-2" 1.0 0 -7500403 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 2 [ plot item 2 epoch-errors-per-module ]"
"module-3" 1.0 0 -13840069 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 3 [ plot item 3 epoch-errors-per-module ]"
"module-4" 1.0 0 -11221820 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 4 [ plot item 4 epoch-errors-per-module ]"
"module-5" 1.0 0 -13345367 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 5 [ plot item 5 epoch-errors-per-module ]"
"module-6" 1.0 0 -8630108 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 6 [ plot item 6 epoch-errors-per-module ]"
"module-7" 1.0 0 -5825686 true "" "if is-list? epoch-errors-per-module and length epoch-errors-per-module > 7 [ plot item 7 epoch-errors-per-module ]"

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

bias-node
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 120 60 150 60 165 60 165 225 180 225 180 240 135 240 135 225 150 225 150 75 135 75 150 60

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

output-node
false
1
Circle -7500403 true false 0 0 300
Circle -2674135 true true 30 30 240
Polygon -7500403 true false 195 75 90 75 150 150 90 225 195 225 195 210 195 195 180 210 120 210 165 150 120 90 180 90 195 105 195 75

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
NetLogo 5.3
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

small-arrow-shape
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 135 180
Line -7500403 true 150 150 165 180

@#$#@#$#@
0
@#$#@#$#@
