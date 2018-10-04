;;Notes
;; average bet price is $50
;; average proportion of monthly salary gambled 12%
;; do we update salary after certain ticks or no?
;; generate betting draws each time
;; population has fixed distribution of people who bet
;; randomly scatter these people in the patches, might end up with patches with no gamblers
;; possibly include way using interaction to choose where to start betting firm( use mouse to click on grid or randomly place one)


;;
;; TURTLE VARIABLES
;;

turtles-own[
  money ;; money that turtle has at one point
  success ;; how many neighbors are successful
  risk-tolerance ;; how likely to risk
]

;;
;; GLOBAL VARIABLES
;;

globals[

]

;;;
;;; SETUP AND HELPERS
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
  create-turtles num-people
    [ move-to one-of patches
      set size 1.5 ;; easier to see
      set-initial-turtle-vars

    ]
end

;; TURTLE METHODS
to set-initial-turtle-vars
  set money random 1000 ;;
  set risk-tolerance random 100 ;;randomly assign risk tolerance
  set success random 10 ;; TEMPORARY
end

;; MOVE TURTLES
to move-turtles
  ;; picked direction
  ask turtles [
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
  ]
end

;; CHECKING PATCH NEIGHBORS
to check-neighbor-success
  ask turtles [
    ifelse sum [success] of turtles-on patch-here > 4
    [ set color blue ] ; TODO: Change these to something relevant
    [ set color black ] ; TODO: Change these to something relevant
  ]
  
end
    

;; method to generate random draws after a specified interval(each tick maybe?)
to generate-draws

end

;;
;; GO
;;

to go
  ask patches [
    ifelse pcolor = yellow
      [ set pcolor yellow + 1 ]
      [ set pcolor yellow ]
  ]
  move-turtles
  check-neighbor-success
  
end