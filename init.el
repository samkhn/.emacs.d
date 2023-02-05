;; Samiur's Emacs Config

;; Increase startup time
;; Increase garbage collection limits and reduce unnecesary regex lookups for
;; elc filehandlers. Bottom of the startup script undoes this.
(defvar last-file-name-handler-alist file-name-handler-alist)
(setq gc-cons-threshold 402653184
      gc-cons-percentage 0.6
      file-name-handler-alist nil)

(set-language-environment "UTF-8")
(setq ring-bell-function 'ignore)
(setq custom-file (concat user-emacs-directory "custom.el"))

(cond
 ((eq system-type 'windows-nt)
  (setq sk/build "build.bat"))
 ((eq system-type 'gnu/linux)
  (setq sk/build "build.sh")))

;; Change font based on what you want
;; TODO: Font for symbols?
(cond
 ((find-font (font-spec :name "Liberation Mono"))
  (setq sk/font "Liberation Mono-10"))
 ((find-font (font-spec :name "Consolas"))
  (setq sk/font "Consolas-12"))
 ((find-font (font-spec :name "Lucida Console"))
  (setq sk/font "Lucida Console-12"))
 ((find-font (font-spec :name "DejaVu Sans Mono"))
  (setq sk/font "DejaVu Sans Mono-15")))

;; Backup dirs
;; Optional disabling of autosave with these:
;; (setq auto-save-default nil)
;; (setq create-lockfiles nil)
;; (setq make-backup-files nil)
(if (not (file-directory-p "~/.emacs-saves"))
 (make-directory "~/.emacs-saves"))
(setq backup-by-copying t
      backup-directory-alist '(("." . "~/.emacs-saves/"))
      delete-old-versions t
      kept-new-versions 5
      kept-old-versions 2
      version-control t)
(setq auto-save-file-name-transforms
      `((".*" "~/.emacs-saves/" t)))

;; Fonts and Windowing
;; Themes set at the bottom of config
(mapcar #'disable-theme custom-enabled-themes)

(set-frame-font sk/font nil t)
(set-face-attribute 'default t :font sk/font)

(setq resize-mini-windows t)
(setq inhibit-splash-screen t)
(setq inhibit-startup-screen t)
;; Add bookmark with C-x r m
;; List bookmark with C-x r l
;; Jump to bookmark C-x r b
;; TODO: Might want to setq-default bookmark-default-file

(setq column-number-mode t)  
(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(set-fringe-mode 0)
(toggle-frame-maximized)

;; Navigation and search
(if (version< emacs-version "28.1")
    (defalias 'yes-or-no-p 'y-or-n-p)
  (setq use-short-answers t))  ; replace yes/no prompt with y/n everywhere

(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)
(setq ido-use-filename-at-point 'guess)
(setq ido-create-new-buffer 'always)

;; TODO: Learn more about configuring hippie-expand
;; NOTE: C-x d is dired by default
(global-set-key (kbd "M-/") 'hippie-expand)
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)
(global-set-key (kbd "C-M-s") 'isearch-forward)
(global-set-key (kbd "C-M-r") 'isearch-backward)

(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))
;; In case you don't have arrow keys:
(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

;; Editing
(savehist-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)
(delete-selection-mode 1)
(show-paren-mode 1)
(setq show-paren-style 'parenthesis)

(setq fixme-modes '(c++-mode c-mode emacs-lisp-mode bat-mode))
(make-face 'font-lock-fixme-face)
(make-face 'font-lock-note-face)
(mapc (lambda (mode)
	(font-lock-add-keywords
	 mode
	 '(("\\<\\(TODO\\)" 1 'font-lock-fixme-face t)
           ("\\<\\(NOTE\\)" 1 'font-lock-note-face t))))
      fixme-modes)
(modify-face 'font-lock-fixme-face "Green" nil nil t nil t nil nil)
(modify-face 'font-lock-note-face "White" nil nil t nil t nil nil)

;; TODO: Custom style guide for C/C++
(setq c-default-style "linux"
      c-basic-offset 4
      tab-width 4
      intend-tab-mode t
      c-tab-always-indent t)

;; In case you encounter a file that doesn't fall under c mode
;;  (add-to-list 'auto-mode-alist '("\\.ext\\'" . c-mode))
;; TODO: find related files (*.cpp -> *.h -> *test.cpp)

;; NOTE: LLVM sub-config. Maintainer: LLVM Team, http://llvm.org/
;; NOTE: If you notice missing or incorrect syntax highlighting, please contact
;;   <llvm-bugs [at] lists.llvm.org>
(add-to-list 'load-path "~/.emacs.d/pkgs/llvm-mode/")
(defun llvm-lineup-statement (langelem)
  (let ((in-assign (c-lineup-assignments langelem)))
    (if (not in-assign)
        '++
      (aset in-assign 0
            (+ (aref in-assign 0)
               (* 2 c-basic-offset)))
      in-assign)))

(c-add-style "llvm.org"
             '("gnu"
	       (fill-column . 80)
	       (c++-indent-level . 2)
	       (c-basic-offset . 2)
	       (indent-tabs-mode . nil)
	       (c-offsets-alist . ((arglist-intro . ++)
				   (innamespace . 0)
				   (member-init-intro . ++)
				   (statement-cont . llvm-lineup-statement)))))

;; Files with "llvm" in their names will automatically be set to the
;; llvm.org coding style.
(add-hook 'c-mode-common-hook
	  (function
	   (lambda nil 
	     (if (string-match "llvm" buffer-file-name)
		 (progn
		   (c-set-style "llvm.org"))))))

(require 'llvm-mode)
(require 'tablgen-mode)

(add-to-list 'load-path "~/.emacs.d/pkgs/rust-mode/")
(autoload 'rust-mode "rust-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))

(global-set-key (kbd "RET") 'newline-and-indent)

(set-default 'truncate-lines t)

(defun sk/go-to-column (column)
  "By default M-g M-g goes to line. Here is goto column"
  (interactive "nColumn: ")
  (move-to-column column t))
(global-set-key (kbd "M-g M-c") #'sk/go-to-column)

;; TODO: Move lines up/down with M-up M-down
;; TODO: consider a replacement for query-and-replace (M-%)?

(defun sk/kill-back-to-indentation ()
  "Kill from point back to the first non-whitespace character on the line."
  (interactive)
  (let ((prev-pos (point)))
    (back-to-indentation)
    (kill-region (point) prev-pos)))
(global-set-key (kbd "C-M-<backspace>") 'sk/kill-back-to-indentation)

(setq-default tab-always-indent 'complete)

;; Compilation
(global-set-key (kbd "C-c C-g") 'compile)
(global-set-key (kbd "C-c g") 'recompile)
;; NOTE: C-x ` or M-g n/p go to next or previous error
(defun sk/compile ()
  (interactive)
  (compile sk/build))
(global-set-key (kbd "C-c m") 'sk/compile)

;; TODO: Make compilation lines turn dark-red (381e1e)  
;; NOTE: use flymake src as inspiration

(defun sk/compilation-hook ()
  (setq compilation-scroll-output nil)
  (make-local-variable 'truncate-lines)
  (setq truncate-lines nil)
  (setq compilation-error-screen-columns nil))
(add-hook 'compilation-mode-hook 'sk/compilation-hook)

;; Reset gc after loading config
(setq gc-cons-threshold 16777216
      gc-cons-percentage 0.1
      file-name-handler-alist last-file-name-handler-alist)

;; Theme: ocean green blue
;; (set-face-attribute 'font-lock-builtin-face nil :foreground "#ffffff")
;; (set-face-attribute 'font-lock-comment-face nil :foreground "#44b340")
;; (set-face-attribute 'font-lock-comment-delimiter-face nil :foreground "#8cde94")
;; (set-face-attribute 'font-lock-constant-face nil :foreground "#7ad0c6")
;; (set-face-attribute 'font-lock-doc-face nil :foreground "44b340")
;; (set-face-attribute 'font-lock-function-name-face nil :foreground "#ffffff")
;; (set-face-attribute 'font-lock-keyword-face nil :foreground "#ffffff")
;; (set-face-attribute 'font-lock-string-face nil :foreground "#2ec09c")
;; (set-face-attribute 'font-lock-type-face nil :foreground "#8cde94")
;; (set-face-attribute 'font-lock-variable-name-face nil :foreground "#c1d1e3")
;; (set-face-attribute 'font-lock-preprocessor-face nil :foreground "#8cde94")
;; (set-face-attribute 'font-lock-warning-face nil :foreground "#ffaa00")
;; (set-face-attribute 'region nil :background "#0000ff" :foreground "nil")
;; (set-face-attribute 'fringe nil :background "#062329" :foreground "white")
;; (set-face-attribute 'highlight nil :background "#0000ff" :foreground "nil")
;; (set-face-attribute 'mode-line nil :background "#d1b897" :foreground "#062329")
;; (add-to-list 'default-frame-alist '(cursor-color . "white"))
;; (add-to-list 'default-frame-alist '(foreground-color . "#d1b897"))
;; (add-to-list 'default-frame-alist '(background-color . "#062329")) ;; more..gray? #292929

;; Theme: linux kernel
;; (global-font-lock-mode 0)
;; (add-to-list 'default-frame-alist '(cursor-color . "black"))
;; (add-to-list 'default-frame-alist '(foreground-color . "black"))
;; (add-to-list 'default-frame-alist '(background-color . "#ffffea"))
;; (set-face-attribute 'highlight nil :background "#gray50" :foreground "nil")
;; (setq-default display-fill-column-indicator-column 80)
;; (global-display-fill-column-indicator-mode)

;; Theme: samiur
(add-to-list 'default-frame-alist '(cursor-color . "green"))
(add-to-list 'default-frame-alist '(foreground-color . "white smoke"))
(add-to-list 'default-frame-alist '(background-color . "black"))
(set-face-attribute 'font-lock-builtin-face nil :foreground "white smoke")
(set-face-attribute 'font-lock-comment-face nil :foreground "light salmon")  ;; content inside /**/ or after // or ;;
(set-face-attribute 'font-lock-comment-delimiter-face nil :foreground "#076678")  ;; e.g. // or /**/ in C or ;; in lisp
(set-face-attribute 'font-lock-constant-face nil :foreground "light salmon")  ;; e.g. in std::string, the std
(set-face-attribute 'font-lock-function-name-face nil :foreground "orange red")  ;; void Do(), the Do
(set-face-attribute 'font-lock-keyword-face nil :foreground "#076678")  ;; static, return keywords
(set-face-attribute 'font-lock-string-face nil :foreground "olive drab")  ;; content inside ""
(set-face-attribute 'font-lock-type-face nil :foreground "burlywood")  ;; std::string s; the string (std and s are covered elsewhere).
(set-face-attribute 'font-lock-variable-name-face nil :foreground "gainsboro")  ;; void Traverse(BST *tree); the tree
(set-face-attribute 'font-lock-preprocessor-face nil :foreground "gainsboro")  ;; e.g. #include
(set-face-attribute 'region nil :background "gray20" :foreground "white")  ;; what you select with marking
(set-face-attribute 'highlight nil :background "gray20" :foreground "white")
(setq-default display-fill-column-indicator-column 80)
(global-display-fill-column-indicator-mode)
(setq-default header-line-format mode-line-format)
(setq-default mode-line-format nil)
