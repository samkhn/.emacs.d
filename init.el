;; Samiur's Emacs Config

;; Increase startup time
;; Increase garbage collection limits and reduce unnecesary regex lookups for
;; elc filehandlers. Bottom of the startup script undoes this.
(defvar last-file-name-handler-alist file-name-handler-alist)
(setq gc-cons-threshold 402653184
      gc-cons-percentage 0.6
      file-name-handler-alist nil)

(setq ring-bell-function 'ignore)
(setq custom-file (concat user-emacs-directory "custom.el"))

(set-language-environment "UTF-8")
(setq-default buffer-file-coding-system 'utf-8-unix)

;; TODO: Font for symbols?
(cond
 ((find-font (font-spec :name "DejaVu Sans Mono"))
  (setq sk/font "DejaVu Sans Mono-9"))
 ((find-font (font-spec :name "Lucida Console"))
  (setq sk/font "Lucida Console-9")))
  
(set-frame-font sk/font nil t)
(set-face-attribute 'default t :font sk/font)

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
;; NOTE: Themes set at the bottom of config
(mapcar #'disable-theme custom-enabled-themes)

(setq resize-mini-windows t)
(setq inhibit-splash-screen t)
(setq inhibit-startup-screen t)

;; Add bookmark with C-x r m
;; List bookmark with C-x r l
;; Jump to bookmark C-x r b

;; Navigation and search
(if (version< emacs-version "28.1")
    (defalias 'yes-or-no-p 'y-or-n-p)
  (setq use-short-answers t))  ; replace yes/no prompt with y/n everywhere

(global-set-key (kbd "M-n") 'forward-paragraph)
(global-set-key (kbd "M-p") 'backward-paragraph)

;; TODO: Learn more about configuring hippie-expand
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

;; Acme style run a selection with middle mouse
(defun sk/run-region ()
  (interactive)
  (let ((region (buffer-substring-no-properties (region-beginning) (region-end))))
    (async-shell-command region)))
(global-set-key (kbd "C-c r") 'sk/run-region)
(global-set-key [mouse-2] 'sk/run-region)

(defun sk/click-to-search (*click)
  (interactive "e")
  (let ((p1 (posn-point (event-start *click))))
    (goto-char p1)
    (isearch-forward-symbol-at-point)))
(global-set-key (kbd "<mouse-3>") 'sk/click-to-search)

(setq initial-scratch-message "")

; TODO: toggle shell instead of just open
(defun sk/switch-to-shell ()
  (interactive)
  (select-window
   (display-buffer-in-side-window
    (save-window-excursion
      (call-interactively #'shell)
      (current-buffer))
    '((side . bottom)))))
(global-set-key (kbd "C-`") 'sk/switch-to-shell)

;; Language modes and styling
(set-default 'truncate-lines t)
(global-set-key (kbd "RET") 'newline-and-indent)
(setq-default tab-always-indent 'complete
			  tab-width 4
			  intend-tabs-mode t)

(add-to-list 'auto-mode-alist '("\\.tpp\\'" . c++-mode))

(load "~/.emacs.d/pkgs/google-c-style")
(require 'google-c-style)
(add-hook 'c-mode-common-hook 'google-set-c-style)
(add-hook 'c++-mode-hook
		  '(lambda ()(highlight-lines-matching-regexp ".\\{81\\}" 'hi-green)))
;; (add-hook 'c-mode-common-hook
;; 	  (function
;; 	   (lambda nil 
;; 	     (progn
;; 	       (setq-default display-fill-column-indicator-column 80)
;; 	       (global-display-fill-column-indicator-mode)))))

;; TODO: run clang-format on save

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

(add-hook 'c-mode-common-hook
	  (function
	   (lambda nil 
	     (if (string-match "llvm" buffer-file-name)
		 (progn
		   (c-set-style "llvm.org"))))))

(require 'llvm-mode)
(require 'tablegen-mode)

(add-to-list 'load-path "~/.emacs.d/pkgs/rust-mode/")
(autoload 'rust-mode "rust-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
(add-hook 'rust-mode-hook
	  (lambda () (local-set-key (kbd "C-c g") 'rust-compile))
	  (lambda () (local-set-key (kbd "C-c c") 'rust-check))
      (lambda () (setq indent-tabs-mode nil)))
(setq rust-format-on-save t)

(add-to-list 'load-path "~/.emacs.d/pkgs/go-mode")
(autoload 'go-mode "go-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))
(add-hook 'go-mode-hook
         (lambda () (add-hook 'before-save-hook 'gofmt-before-save)))

(defun sk/go-to-column (column)
  "By default M-g M-g goes to line. Here is goto column"
  (interactive "nColumn: ")
  (move-to-column column t))
(global-set-key (kbd "M-g M-c") #'sk/go-to-column)
;; M-g -> go to line, M-g c is go to character

;; TODO: Move lines up/down with M-up M-down
;; TODO: consider a replacement for query-and-replace (M-%)?

(defun sk/kill-back-to-indentation ()
  "Kill from point back to the first non-whitespace character on the line."
  (interactive)
  (let ((prev-pos (point)))
    (back-to-indentation)
    (kill-region (point) prev-pos)))
(global-set-key (kbd "C-M-<backspace>") 'sk/kill-back-to-indentation)

;; Compilation
;; NOTE: C-x ` or M-g n/p go to next or previous error
(global-set-key (kbd "C-c C-g") 'compile)
(global-set-key (kbd "C-c g") 'recompile)

(add-to-list 'load-path "~/.emacs.d/pkgs/cmake-mode/")
(require 'cmake-mode)
(defun sk/set-compile-from-cmake ()
  (interactive)
  (let ((cmakefile nil) (dirname default-directory))
    (while (and (not (string= dirname "/")) (not cmakefile))
      (setq cmakefile (concat (file-name-as-directory dirname) "CMakeLists.txt"))
      (if (not (file-exists-p cmakefile))
         (progn
           (setq cmakefile nil)
           (setq dirname (expand-file-name
                          (concat (file-name-as-directory dirname) ".."))))))
    (if cmakefile
       (let ((builddir (concat (file-name-directory cmakefile) "build")))
         (if (file-exists-p builddir)
             (let ((ninja (concat (file-name-as-directory builddir) "build.ninja")))
               (if (file-exists-p ninja)
                   (set (make-local-variable 'compile-command) (concat "ninja -C " (shell-quote-argument builddir))))))))))
(add-hook 'c-mode-common-hook 'sk/set-compile-from-cmake)

(defun sk/compilation-hook ()
  (setq compilation-scroll-output nil)
  (make-local-variable 'truncate-lines)
  (setq truncate-lines nil)
  (setq compilation-error-screen-columns nil))
(add-hook 'compilation-mode-hook 'sk/compilation-hook)

;; Visual

(add-to-list 'default-frame-alist '(height . 60))
(add-to-list 'default-frame-alist '(width . 160))
;; (toggle-frame-maximized)

(setq column-number-mode t)
(scroll-bar-mode -1)  ;; scroll bar left w/ (set-scroll-bar-mode 'left)
(tool-bar-mode -1)
(menu-bar-mode -1)
(set-fringe-mode '(1 . 1))
(setq-default header-line-format mode-line-format)
(setq-default mode-line-format nil)
(setq-default cursor-type 'bar)

(global-font-lock-mode 0)  ;; no syntax highlighting

(add-to-list 'default-frame-alist '(cursor-color . "black"))
(add-to-list 'default-frame-alist '(foreground-color . "black"))
(add-to-list 'default-frame-alist '(background-color . "#ffffea"))
(set-face-attribute 'highlight nil :background "#gray50" :foreground "nil")

;; Reset gc after loading config
(setq gc-cons-threshold 16777216
      gc-cons-percentage 0.1
      file-name-handler-alist last-file-name-handler-alist)

