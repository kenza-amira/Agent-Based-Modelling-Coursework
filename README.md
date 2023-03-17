# Agent-Based-Modelling-Coursework
to setup addition:
 ;Plant policy
  set plant-policy false
then add a switch-on button whose name is plant-policy

to go TREE PROCEDURE adjustment(add palnt-policy function):
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
  
add plant-policy-on function below tree-reproduce function (at TREE FUNCTIONS - DO NOT MODIFY):

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

  
