# Agent-Based-Modelling-Coursework
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
  ]
  ; the tree is 30 years old and generate a new tree in a random nearby patch
