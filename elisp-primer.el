;; Emacs lisp manual: C-h i m elisp RET
;;
;; Learn about any variable or function
;; C-h v a-variable RET
;; C-h f a-function RET
;; 
;; Before you start, here are some ways to evaluate
;; 1. Enter lisp-interaction-mode, place cursor at EOL (last token) and eval-print-last-sexp (C-j) to evaluate the line. Result will be placed in line after sexp
;; 2. Use eval-exp (M-:) or (if cursor is at last token) eval-last-sexp (C-x C-e). Result will be printed in minibuffer

;; Elisp programs are made of `symbolic expressions` (sexps).

;; In this example, 2 is considered an `atom`.
(+ 2 2)

;;;; You can nest expressions
(+ 2 (+ 1 1))

;; `setq` stores values into variables
(setq name "Bob")

;; `insert` inserts string where the cursor is
(insert "Hey Bob")
(insert "Hey" "Bob")

(insert "Hey, my name is " name)

;; Define functions
;;;; no params means it accepts no arguments
(defun hello ()
  (insert "Hello my name is " name))
;;;; ex with arguments
(defun helloa (name)
  (insert "Hello my name is " name))

;; Evaluate functions
(hello)
(helloa "sam")
;; If it is printing nil, nil is the hello funcs return type and is a side-effect of eval-print-last-sexp

;; Evaluate a sexp in another window
;;;; progn causes each of its arguments to be evaluated in sequence and then returns the value of the last one.
(progn
  (switch-to-buffer-other-window "*test*")
  (erase-buffer)
  (helloa "withprogn")
  (other-window 1))

;;;; Let also lets you group sexps
(let ((local-name "withlet"))
  (switch-to-buffer-other-window "*test*")
  (erase-buffer)
  (helloa local-name)
  (other-window 1))

;; str format
;;;; Note: this is wrong because of the comma(I inserted the comma out of habit): (format "Hello %s!\n", "visitor")
(format "Hello %s!\n" "visitor")

(defun hello (name)
  (insert (format "Hello %s\n" name )))
(hello "sam")

;; Some functions are interactive
(read-from-minibuffer "Enter your name: ")

(defun greeting (from-name)
  (let ((your-name (read-from-minibuffer "Enter your name: ")))
    (switch-to-buffer-other-window "*test*")
    (erase-buffer)
    (insert (format "Hello, your name is %s. My name is %s\n"
                    your-name
                    from-name)
            )
    (other-window 1)
    )
  )

(greeting "Bob")

;; List
(setq list-of-names '("Sarah" "Cloe"))

;;;; Access 1st element with `car`, 2nd with `cdr`
(car list-of-names)
(cdr list-of-names)

;;;; Add elements with push
(push "Steph" list-of-names)

;; Let's map the `hello` function to each element of the list
(mapcar 'hello list-of-names)

(defun greeting ()
  (switch-to-buffer-other-window "*test*")
  (erase-buffer)
  (mapcar 'hello list-of-names)
  (other-window 1))
(greeting)

(defun replace-hello-with-hola ()
  (switch-to-buffer-other-window "*test*")
  (goto-char (point-min))
  ;;;; (while x y) evaluates the y sexp(s) while x returns something.
  ;;;; when x returns nil, we exit the loop
  ;;;; last param `t` matches to hide error (without it, it prints that the search for hello failed
  ;;;; 2nd to last param nil says that the search is not bound to a position
  (while (search-forward "hello" nil t)
    (replace-match "hola"))
  (other-window 1))

(defun boldify-names ()
  (switch-to-buffer-other-window "*test*")
  (goto-char (point-min))
  (while (re-search-forward "Hola \\(.+\\)!")
    (add-text-properties (match-beginning 1)
                         (match-end 1)
                         (list 'face 'bold)))
  (other-window 1))

(greeting)
(replace-hello-with-hola)
(boldify-names)
