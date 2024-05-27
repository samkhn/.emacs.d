; Samiurs Emacs Config

(setq debug-on-error t)
(setq warning-minimum-level :emergency)

(setq ring-bell-function 'ignore)
(setq custom-file (concat user-emacs-directory "custom.el"))
(add-to-list 'load-path "~/.emacs.d/lisp/")
(setq use-short-answers t)

;; Navigation and search

(require 'ido)
(ido-mode 1)
(setq ido-everywhere t)
(setq ido-enable-flex-matching t)
;; When doing ido-find-file, press C-t to switch to regex search

(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))

;; Bookmarks
;; ‘C-x r m’ – set a bookmark at the current location (e.g. in a file)
;; ‘C-x r b’ – jump to a bookmark
;; ‘C-x r l’ – list your bookmarks
;; ‘M-x bookmark-delete’ – delete a bookmark by name

(require 'recentf)
(recentf-mode t)
(setq recentf-max-saved-items 50)

;; Editing

(set-language-environment "UTF-8")
(setq-default buffer-file-coding-system 'utf-8-unix)

;; `M-/` is dabbrev expand
(setq dabbrev-case-fold-search t)
(setq hippie-expand-try-functions-list
      '(
        try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        ;; try-expand-dabbrev-from-kill
        try-complete-lisp-symbol-partially
        try-complete-lisp-symbol
        try-complete-file-name-partially
        try-complete-file-name
        ;; try-expand-all-abbrevs
        try-expand-list
        try-expand-line
        ))

(setq auto-save-default nil)
(setq create-lockfiles nil)
(setq make-backup-files nil)

(setq history-length 25)
(savehist-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)

(delete-selection-mode t)
(show-paren-mode 1)
(setq show-paren-style 'parenthesis)

(global-set-key (kbd "RET") 'newline-and-indent)

(defun sk/kill-back-to-indentation ()
  "Kill from point back to the first non-whitespace character on the line."
  (interactive)
  (let ((prev-pos (point)))
    (back-to-indentation)
    (kill-region (point) prev-pos)))
(global-set-key (kbd "C-M-<backspace>") 'sk/kill-back-to-indentation)

;; sk/howiwork
;; in the project root, I create a single build script
;; script is build.sh on Unix/POSIX and build.bat on Windows
;; this script invokes other scripts to configure, compile, debug and format
;; emacs searches for these scripts and sets compile to run found script

(require 'project)

(setq sk/build-script-name "build.sh")
(if (string-equal system-type "windows-nt")
    (setq sk/build-script-name "build.bat"))

(setq sk/todo-file "TODO.txt")

(defun sk/set-build ()
  (interactive)
  (let ((sk/build-root (locate-dominating-file "." sk/build-script-name)))
    (when sk/build-root
      (cd sk/build-root)
      (setq sk/build (concat sk/build-root sk/build-script-name))))
  (if (not (boundp 'sk/build))
      (message "build script not found in path, ignoring...")
    (message "Found build script at at %s" sk/build)
    (setq compile-command sk/build)))
(add-hook 'prog-mode-hook 'sk/set-build)

(defun sk/set-todo ()
  (interactive)
  (let ((sk/todo-root (locate-dominating-file "." sk/todo-file)))
    (when sk/todo-root
      (setq sk/todo (concat sk/todo-root sk/todo-file))))
  (if (not (boundp 'sk/todo))
      (message "todo file not found, ignoring...")))
(add-hook 'prog-mode-hook 'sk/set-todo)
(global-set-key (kbd "C-c t") (lambda() (interactive) (find-file sk/todo)))

(defun sk/compilation-hook ()
  (setq compilation-scroll-output nil)
  (make-local-variable 'truncate-lines)
  (setq truncate-lines nil)
  (setq compilation-error-screen-columns nil))
(add-hook 'compilation-mode-hook 'sk/compilation-hook)

(global-set-key (kbd "C-c C-g") #'compile)
(global-set-key (kbd "C-c g") #'recompile)

(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq show-trailing-whitespace t)

(defun sk/format--call (formatter buf)
  "Format buf using formatter."
  (with-current-buffer (get-buffer-create "*Formatter*")
    (erase-buffer)
    (insert-buffer-substring buf)
    (if (zerop (call-process-region (point-min) (point-max) formatter t t nil))
        (progn (copy-to-buffer buf (point-min) (point-max))
               (kill-buffer))
      (display-buffer (current-buffer))
      (error "%s failed, see *Formatter* buffer for details" formatter))))

(defun sk/format-buffer (formatter)
  "Format the current buffer using formatter.
Expect single program that works with stdin as formatter e.g. rustfmt or clang-format"
  (interactive)
  (unless (executable-find formatter)
    (error "Could not locate executable \"%s\"" formatter))
  (let ((cur-point (point))
        (cur-win-start (window-start)))
    (sk/format--call formatter (current-buffer))
    (goto-char cur-point)
    (set-window-start (selected-window) cur-win-start))
  (message "Formatted buffer with %s." formatter))

(defun c-lineup-arglist-tabs-only (ignored)
  "Line up argument lists by tabs, not spaces"
  (let* ((anchor (c-langelem-pos c-syntactic-element))
         (column (c-langelem-2nd-pos c-syntactic-element))
         (offset (- (1+ column) anchor))
         (steps (floor offset c-basic-offset)))
    (* (max steps 1)
       c-basic-offset)))

;; LLVM coding style guidelines in emacs
;; Maintainer: LLVM Team, http://llvm.org/
(defun llvm-lineup-statement (langelem)
  (let ((in-assign (c-lineup-assignments langelem)))
    (if (not in-assign)
        '++
      (aset in-assign 0
            (+ (aref in-assign 0)
               (* 2 c-basic-offset)))
      in-assign)))

;; Add a cc-mode style for editing LLVM C and C++ code
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

(c-add-style "linux-tabs-only"
	     '("linux" (c-offsets-alist
			(arglist-cont-nonempty
			 c-lineup-gcc-asm-reg
			 c-lineup-arglist-tabs-only))))

(require 'google-c-style)
(add-hook 'c++-mode-hook 'google-make-newline-indent)
(add-hook 'c++-mode-hook 'google-set-c-style)
(add-hook 'c++-mode-hook
	  (lambda ()
	    (let ((filename (buffer-file-name)))
	      (when (and filename
			 (or (string-match "LLVM" filename)
			     (string-match "llvm" filename)))
		(c-set-style "llvm.org")))))

(add-hook 'c-mode-hook
	  (lambda ()
	    (c-set-style "linux-tabs-only")))
(add-hook 'c-mode-hook
          (lambda ()
            (let ((filename (buffer-file-name)))
              (when (and filename
			 (or (string-match "kernel" filename)
			     (string-match "linux" filename)))
                (setq indent-tabs-mode t)
                (c-set-style "linux-tabs-only")))))

(require 'cuda-mode)

(defun sk/clang-format ()
  (interactive)
  (sk/format-buffer "clang-format"))
(add-hook 'c-mode-common-hook
	  (lambda ()
	    (local-set-key (kbd "C-c f") 'sk/clang-format)))

(require 'rust-mode)
(defun sk/rust-format ()
  (interactive)
  (sk/format-buffer "rustfmt"))
(add-hook 'rust-mode-hook
	  (lambda ()
	    (local-set-key (kbd "C-c f") 'sk/rust-format)))
(defun rust-before-save-method ()
  (sk/rust-format))
(defun rust-after-save-method ())

(require 'go-mode)
(defun sk/golang-fmt ()
  (interactive)
  (sk/format-buffer "gofmt"))
(add-hook 'go-mode-hook
	  (lambda ()
	    (local-set-key (kbd "C-c f") 'sk/golang-format)))

(defun sk/python-fmt ()
  (interactive)
  (sk/format-buffer "yapf"))
(add-hook 'python-mode-hook
	  (lambda ()
	    (local-set-key (kbd "C-c f") 'sk/python-fmt)))

;; NOTE: verilog mode has its own set of keybinds.

(if (file-directory-p "~/install/otp-2024-05-26")
    (progn
      (setq load-path (cons "~/install/otp-2024-05-26/lib/erlang/lib/tools-4.0/emacs" load-path))
      (setq erlang-root-dir "~/install/otp-2024-05-26")
      (setq exec-path (cons "~/install/otp-2024-05-26/bin" exec-path))
      (require 'erlang-start)))

(require 'prolog)
(setq prolog-system 'swi
      prolog-program-switches '((swi ("-G128M" "-T128M" "-L128M" "-O"))
				(t nil))
      prolog-electric-if-then-else-flag t)
(add-to-list 'auto-mode-alist '("\\.\\(pl\\|pro\\|lgt\\)" . prolog-mode))

(require 'llvm-mode)
(require 'tablegen-mode)

(autoload 'markdown-mode "markdown-mode"
  "Major mode for editing Markdown files" t)
(add-to-list 'auto-mode-alist
             '("\\.\\(?:md\\|markdown\\|mkd\\|mdown\\|mkdn\\|mdwn\\)\\'" . markdown-mode))

(autoload 'gfm-mode "markdown-mode"
  "Major mode for editing GitHub Flavored Markdown files" t)
(add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))

(require 'cmake-mode)
(require 'bazel)

(require 'grep)
(when (executable-find "rg")
  (setq grep-command "rg -nS --no-heading "
        grep-use-null-device nil))

(global-set-key (kbd "C-c s") 'grep)
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)

;; Experiment
(defun sk/click-to-search (*click)
  (interactive "e")
  (let ((p1 (posn-point (event-start *click))))
    (goto-char p1)
    (isearch-forward-symbol-at-point)))

;; Graphical settings

(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(set-fringe-mode '(1 . 1))
(setq column-number-mode t)
(setq visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))

(if (display-graphic-p)
    (progn
      (cond
       ;; Custom font
       ((find-font (font-spec :name "Hack"))
	(setq sk/font "Hack-13"))
       ;; Windows font
       ((find-font (font-spec :name "Consolas"))
	(setq sk/font "Consolas-13"))
       ;; Linux font
       ((find-font (font-spec :name "Monospace"))
	(setq sk/font "Monospace-13"))
       )
      (add-to-list 'default-frame-alist `(font . ,sk/font))
      (set-face-attribute 'default t :font sk/font)

      ;; Theme. What setting controls what?
      ;; comment := content inside /**/ or after // or ;;
      ;; comment delimiter := // or /**/ in C or ;; in lisp
      ;; constant := in std::string, the std
      ;; function name := void Do(), the Do
      ;; keyword := static, return keywords
      ;; string := content inside ""
      ;; type := std::string s; the string (std and s are covered elsewhere).
      ;; variable name := void Traverse(BST *tree); the tree
      ;; preprocessor := #include

      ;; Acme
      ;; (setq-default cursor-type 'bar)
      ;; (add-to-list 'default-frame-alist '(cursor-color . "black"))
      ;; (add-to-list 'default-frame-alist '(foreground-color . "black"))
      ;; (add-to-list 'default-frame-alist '(background-color . "#FFFFE9"))
      ;; (set-face-attribute 'fringe nil :background "#FFFFE9" :foreground "black")
      ;; (global-font-lock-mode 0)

      ;; Black and white
      ;; (add-to-list 'default-frame-alist '(cursor-color . "red"))
      ;; (add-to-list 'default-frame-alist '(foreground-color . "white"))
      ;; (add-to-list 'default-frame-alist '(background-color . "black"))
      ;; (set-face-attribute 'fringe nil :background "black" :foreground "white")

      ;; Theme: salmon
      ;; (set-face-attribute 'font-lock-builtin-face nil :foreground "white")
      ;; (set-face-attribute 'font-lock-comment-face nil :foreground "salmon")
      ;; (set-face-attribute 'font-lock-comment-delimiter-face nil :foreground "dark salmon")
      ;; (set-face-attribute 'font-lock-constant-face nil :foreground "white")
      ;; (set-face-attribute 'font-lock-doc-face nil :foreground "dark salmon")
      ;; (set-face-attribute 'font-lock-function-name-face nil :foreground "white")
      ;; (set-face-attribute 'font-lock-keyword-face nil :foreground "white")
      ;; (set-face-attribute 'font-lock-string-face nil :foreground "dark salmon")
      ;; (set-face-attribute 'font-lock-type-face nil :foreground "white")
      ;; (set-face-attribute 'font-lock-variable-name-face nil :foreground "white")
      ;; (set-face-attribute 'font-lock-preprocessor-face nil :foreground "grey")
      ;; (set-face-attribute 'font-lock-warning-face nil :foreground "AntiqueWhite2")
      ;; (set-face-attribute 'region nil :background "#ff0000" :foreground "nil")
      ;; (set-face-attribute 'fringe nil :background "gray10" :foreground "grey")
      ;; (set-face-attribute 'highlight nil :background "#ff0000" :foreground "nil")
      ;; (set-face-attribute 'mode-line nil :background "grey" :foreground "gray20")
      ;; (add-to-list 'default-frame-alist '(cursor-color . "tomato"))
      ;; (add-to-list 'default-frame-alist '(foreground-color . "white"))
      ;; (add-to-list 'default-frame-alist '(background-color . "gray10"))
      ;; (global-hl-line-mode 1)
      ;; (set-face-attribute 'highlight nil :background "gray20" :foreground "nil")
      ;; (set-face-attribute 'hl-line nil :inherit nil :background "gray20")

      ;; Theme: solarized
      (set-face-attribute 'font-lock-builtin-face nil :foreground "#ffffff")
      (set-face-attribute 'font-lock-comment-face nil :foreground "#44b340")
      (set-face-attribute 'font-lock-comment-delimiter-face nil :foreground "#8cde94")
      (set-face-attribute 'font-lock-constant-face nil :foreground "#7ad0c6")
      (set-face-attribute 'font-lock-doc-face nil :foreground "44b340")
      (set-face-attribute 'font-lock-function-name-face nil :foreground "#ffffff")
      (set-face-attribute 'font-lock-keyword-face nil :foreground "#ffffff")
      (set-face-attribute 'font-lock-string-face nil :foreground "#2ec09c")
      (set-face-attribute 'font-lock-type-face nil :foreground "#8cde94")
      (set-face-attribute 'font-lock-variable-name-face nil :foreground "#c1d1e3")
      (set-face-attribute 'font-lock-preprocessor-face nil :foreground "#8cde94")
      (set-face-attribute 'font-lock-warning-face nil :foreground "#ffaa00")
      (set-face-attribute 'region nil :background "#0000ff" :foreground "nil")
      (set-face-attribute 'fringe nil :background "#062329" :foreground "white")
      (set-face-attribute 'highlight nil :background "#0000ff" :foreground "nil")
      (set-face-attribute 'mode-line nil :background "#d1b897" :foreground "#062329")
      (add-to-list 'default-frame-alist '(cursor-color . "white"))
      (add-to-list 'default-frame-alist '(foreground-color . "#d1b897"))
      (add-to-list 'default-frame-alist '(background-color . "#062329")) ;; graybg #292929 bluebg #062329

      ;; Theme: handmade hero
      ;; (set-face-attribute 'font-lock-builtin-face nil :foreground "#DAB98F")
      ;; (set-face-attribute 'font-lock-comment-face nil :foreground "gray50")
      ;; (set-face-attribute 'font-lock-constant-face nil :foreground "olive drab")
      ;; (set-face-attribute 'font-lock-doc-face nil :foreground "gray50")
      ;; (set-face-attribute 'font-lock-function-name-face nil :foreground "burlywood3")
      ;; (set-face-attribute 'font-lock-keyword-face nil :foreground "DarkGoldenrod3")
      ;; (set-face-attribute 'font-lock-string-face nil :foreground "olive drab")
      ;; (set-face-attribute 'font-lock-type-face nil :foreground "burlywood3")
      ;; (set-face-attribute 'font-lock-variable-name-face nil :foreground "burlywood3")
      ;; (add-to-list 'default-frame-alist '(cursor-color . "#40FF40"))
      ;; (add-to-list 'default-frame-alist '(foreground-color . "burlywood3"))
      ;; (add-to-list 'default-frame-alist '(background-color . "#161616"))
      ;; (global-hl-line-mode 1)
      ;; (set-face-attribute 'highlight nil :background "midnight blue" :foreground "nil")
      ;; (set-face-attribute 'hl-line nil :inherit nil :background "midnight blue")

      ;; Experiment: click to search
      (global-set-key (kbd "<mouse-3>") 'sk/click-to-search)

      (add-to-list 'default-frame-alist '(height . 60))
      (add-to-list 'default-frame-alist '(width . 100))
      (toggle-frame-maximized)

      (setq initial-frame-alist default-frame-alist)
      (setq special-display-frame-alist default-frame-alist))
  ;; Terminal graphical mode settings
  )
