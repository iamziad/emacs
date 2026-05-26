(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-vc-git-default-protocol 'https)
(setq straight-use-package-by-default t)

(use-package no-littering
  :straight t
  :config
  (require 'no-littering)
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

(defvar my-nav-map (make-sparse-keymap))
(define-key my-nav-map (kbd "C-h") #'backward-char)
(define-key my-nav-map (kbd "C-j") #'next-line)
(define-key my-nav-map (kbd "C-k") #'previous-line)
(define-key my-nav-map (kbd "C-l") #'forward-char)
(define-key my-nav-map (kbd "C-f") #'forward-word)
(define-key my-nav-map (kbd "C-b") #'backward-word)

(define-minor-mode my-nav-mode
  "Custom navigation mode."
  :lighter ""
  :keymap my-nav-map)

(defvar my-nav-excluded-modes
  '(term-mode
    vterm-mode
    eshell-mode
    shell-mode
    comint-mode))

(defun my-nav-mode--maybe-enable ()
  (unless (or (minibufferp)
              (apply #'derived-mode-p my-nav-excluded-modes))
    (my-nav-mode 1)))

(define-globalized-minor-mode global-my-nav-mode
  my-nav-mode
  my-nav-mode--maybe-enable)

(global-my-nav-mode 1)

(defun my-setup-minibuffer-navigation ()
  (local-set-key (kbd "C-p") #'previous-history-element)
  (local-set-key (kbd "C-n") #'next-history-element)
  (local-set-key (kbd "C-h") #'backward-char)
  (local-set-key (kbd "C-l") #'forward-char))

(add-hook 'minibuffer-setup-hook #'my-setup-minibuffer-navigation)

(with-eval-after-load 'magit
  (define-key magit-hunk-section-map (kbd "C-j") nil)
  (define-key magit-diff-section-base-map (kbd "C-j") nil)
  (define-key magit-file-section-map (kbd "C-j") nil)
  (define-key magit-diff-mode-map (kbd "C-j") nil))

  (bind-keys
   ("C-,"           . duplicate-line)
   ("C-<tab>"       . mode-line-other-buffer)
   ("C-n"           . (lambda () (interactive) (forward-line  5)))
   ("C-p"           . (lambda () (interactive) (forward-line -5)))
   ("M-n"           . recenter-top-bottom)
   ("C-x C-="       . (lambda () (interactive) (enlarge-window-horizontally 10)))
   ("C-x C--"       . (lambda () (interactive) (shrink-window-horizontally 10)))

   ;; C-c prefix
   :map global-map
   ("C-c f" . find-file-at-point)
   ("C-c h" . previous-buffer)
   ("C-c l" . next-buffer)
   ("C-c o c" . my/open-config))

(bind-keys :prefix-map my-leader-map
           :prefix "C-z"
           ("h"   . help-command)
           ("c"   . org-capture)
           ("t"   . org-babel-tangle))

(defun my/setup-fonts ()
  (set-face-attribute 'default nil
                      :font "JetBrainsMono Nerd Font Mono"
                      :height 110
                      :weight 'medium)
  (set-face-attribute 'variable-pitch nil
                      :family "JetBrainsMono Nerd Font Mono"
                      :height 115
                      :weight 'normal)
  (set-face-attribute 'fixed-pitch nil
                      :font "JetBrainsMono Nerd Font Mono"
                      :height 110
                      :weight 'medium)

  (set-fontset-font (frame-parameter nil 'font)
                    'arabic
                    (font-spec :family "Cairo" :weight 'regular)))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (my/setup-fonts))))

  (my/setup-fonts))

(add-to-list 'default-frame-alist '(font . "JetBrains Mono-11"))
(setq-default line-spacing 0.12)
(add-hook 'org-mode-hook 'variable-pitch-mode)

(use-package emacs
  :init
  (setq inhibit-startup-screen t
        duplicate-line-final-position t
        isearch-allow-scroll t
        global-auto-revert-non-file-buffers t
        switch-to-buffer-obey-display-actions t
        scroll-preserve-screen-position t
        scroll-margin 5
        whitespace-style '(face tabs tab-mark trailing)
        use-package-compute-statistics t)

  (global-whitespace-mode 1)
  (tool-bar-mode   0)
  (scroll-bar-mode 0)
  (column-number-mode)
  (recentf-mode 1)
  (savehist-mode 1)
  (delete-selection-mode 1)
  (column-number-mode)
  (global-auto-revert-mode 1)
  (xterm-mouse-mode 1)
  (auto-save-visited-mode 1)
  (global-visual-line-mode 1)
  (electric-pair-mode 1)
  (electric-indent-mode -1)

  (set-fringe-mode 10)

  (global-set-key [remap dabbrev-expand] #'hippie-expand)

  (add-hook 'before-save-hook #'delete-trailing-whitespace)

  (add-hook 'org-mode-hook
            (lambda ()
              (setq-local electric-pair-inhibit-predicate
                          `(lambda (c)
                             (if (char-equal c ?<)
                                 t
                               (,electric-pair-inhibit-predicate c))))))

  (setq custom-file
        (expand-file-name "custom.el" user-emacs-directory))

  (when (file-exists-p custom-file)
    (load custom-file t))

  :custom
  ;; vertico
  (context-menu-mode t)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

(require 'subword)

(defun my/delete-selected ()
  "Delete selected region without adding to kill ring."
  (interactive)
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (delete-char -1)))

(defun my/delete-smart-to-end ()
  "Delete to end of line, or delete newline if already at end of line."
  (interactive)
  (if (= (point) (line-end-position))
      (unless (eobp)        (delete-char 1))
    (delete-region (point) (line-end-position))))

(defun my/backward-delete-word ()
  "Delete word but stay within the current line, respecting camelCase boundaries."
  (interactive)
  (let ((limit (line-beginning-position)))
    (if (> (point) limit)
        (let ((end (point)))
          (subword-backward 1)
          (when (< (point) limit)
            (goto-char limit))
          (delete-region (point) end))
      (delete-char -1))))

(defun my/forward-delete-word ()
  "Delete word forward without adding to kill-ring."
  (interactive)
  (delete-region (point)
                 (progn (forward-word 1) (point))))

(bind-keys
 ("M-k"           . my/delete-smart-to-end)
 ("DEL"           . my/delete-selected)
 ("M-DEL"         . my/backward-delete-word)
 ("M-d"           . my/forward-delete-word)
 ("<C-backspace>" . my/backward-delete-word))

;; Column Indicator
(global-display-fill-column-indicator-mode 1)
(setq-default fill-column 80)

;; Line Numbers
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)

(dolist (hook '(term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                Man-mode-hook
  	            olivetti-mode-hook
                vterm-mode-hook))
  (add-hook hook (lambda ()
                   (display-line-numbers-mode 0)
                   (display-fill-column-indicator-mode 0))))

(setq-default indent-tabs-mode nil
              tab-width 4
              standard-indent 4
              c-basic-offset 4
              js-indent-level 2
              css-indent-offset 2)

(use-package make-mode
  :ensure nil
  :hook (makefile-mode . (lambda ()
                           (setq indent-tabs-mode t)
                           (setq tab-width 4))))

(use-package aggressive-indent
  :ensure t
  :config
  (global-aggressive-indent-mode 1)
  (add-to-list 'aggressive-indent-excluded-modes 'python-mode)
  (add-to-list 'aggressive-indent-excluded-modes 'yaml-mode)
  (add-to-list 'aggressive-indent-excluded-modes 'html-mode))

;; Company mode
(use-package company
  :ensure t
  :hook (after-init . global-company-mode)
  :bind (:map company-active-map
              ("C-j" . company-select-next)
              ("C-k" . company-select-previous)
              ("TAB" . company-complete-selection)))

(use-package gruvbox-material-emacs
  :straight (gruvbox-material-emacs
             :local-repo "~/gruvbox-material-emacs"
             :branch "perf"
             :type git
             :files ("*.el"))
  :init
  (setq gm-background               'dark
        gm-dark-variant             'classic
        gm-dark-modeline            'material
        gm-org                      'material
        gm-diff-hl-style            'signs
        gm-org-scale-headings       'conservative
        gm-syntax-keywords          'semi-bold
        gm-light-contrast  'hard)
  :config
  (gruvbox-material-load))

(use-package ef-themes
  :ensure t
  :init
  (ef-themes-take-over-modus-themes-mode 1)
  :bind
  (("<f6>" . modus-themes-rotate)
   ("C-<f6>" . modus-themes-select)
   ("M-<f6>" . modus-themes-load-random))
  :config
  (setq modus-themes-mixed-fonts t)
  (setq modus-themes-italic-constructs t))

(use-package diff-hl
  :config
  (global-diff-hl-mode 1)
  (setq diff-hl-fringe-bmp-function #'diff-hl-fringe-bmp-from-type)
  (diff-hl-show-hunk-mouse-mode)
  (diff-hl-flydiff-mode 1)
  (add-hook 'magit-pre-refresh-hook  'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode))

(use-package hl-todo
  :hook ((org-mode . hl-todo-mode)
         (prog-mode . hl-todo-mode))
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        `(("TODO"       warning bold)
          ("FIXME"      error bold)
          ("HACK"       font-lock-constant-face bold)
          ("REVIEW"     font-lock-keyword-face bold)
          ("NOTE"       success bold)
          ("DEPRECATED" font-lock-doc-face bold))))

(with-eval-after-load 'magit
  (add-hook 'magit-log-wash-summary-hook
            #'hl-todo-search-and-highlight t)
  (add-hook 'magit-revision-wash-message-hook
            #'hl-todo-search-and-highlight t))

(use-package rainbow-delimiters
  :ensure t
  :hook ((emacs-lisp-mode lisp-mode common-lisp-mode) . rainbow-delimiters-mode))

(use-package vertico
  :init (vertico-mode)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous))
  :custom
  (vertico-resize t)
  (vertico-cycle  t)
  (vertico-scroll-margin 0))

(use-package marginalia
  :init (marginalia-mode))

(use-package orderless
  :custom
  (completion-styles              '(orderless basic))
  (completion-category-defaults  nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(require 'dired-x)
(setq dired-omit-files
      (concat dired-omit-files "\\|^\\..+$"))
(setq-default dired-dwim-target t)
(setq dired-listing-switches "-alh")
(setq dired-mouse-drag-files t)

(require 'org-tempo)

(add-to-list 'display-buffer-alist
             '("\\*Org Select\\*\\|CAPTURE"
               (display-buffer-below-selected)
               (window-height . 0.6)))

(setq org-directory "~/Documents/org")

(setq org-capture-templates
      `(("a" "Anki Card" entry
         (file+headline "/tmp/anki.org" "Anki flashcards for today")
         "* \n:PROPERTIES:\n:ANKI_DECK:\n:ANKI_NOTE_TYPE: Basic\n:END:\n\n** Front\n\n** Back\n")

        ("d" "Deadline Task" entry
         (file+headline "~/Documents/org/tasks.org" "Deadlines")
         "* TODO %?\n DEADLINE: %^{Deadline}t\n %a\n")

        ("i" "Idea" entry
         (file "~/Documents/org/ideas.org")
         "* TODO %?\n %a %U\n\n")

        ("s" "Scheduled Task" entry
         (file+headline "~/Documents/org/tasks.org" "Schedules")
         "* TODO %?\n SCHEDULED: %^{Date}t\n %a\n")

        ("t" "Todo Inbox" entry
         (file "~/Documents/org/inbox.org")
         "* TODO %?\n %a %U\n\n")

        ("w" "Watch/Read Later" entry
         (file+headline "~/Documents/org/later.org" "Watch/Read Later")
         "* TODO %^{Title}\n [[%x][Link]]\n :PROPERTIES:\n :TYPE: %^{Type|Video|Article|Tutorial|Lecture/Conference}\n :END:\n\n %?\n %U\n")))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (C . t)
   (shell . t)
   (java . t)))

(setq        org-src-tab-acts-natively t)
(setq        org-src-fontify-natively t)
(setq        org-confirm-babel-evaluate nil)
(setq        org-src-preserve-indentation t)
(setq        org-src-window-setup 'current-window)

(use-package toc-org
  :straight (:host github
   		           :repo "iamziad/toc-org"
   		           :branch "toc-side-window"
   		           :files ("*.el"))
  :commands toc-org-enable
  :bind (:map my-leader-map
  	          ("o" . toc-org-navigation-pane))
  :config
  (setq toc-org-side-window-side 'left)
  (setq toc-org-side-window-size '40)
  :init
  (add-hook 'markdown-mode-hook #'toc-org-enable)
  (add-hook 'org-mode-hook #'toc-org-enable))

(use-package org-download
  :defer t
  :bind (:map org-mode-map
              ("C-c s" . org-download-clipboard))
  :config
  (setq-default org-download-heading-lvl nil)
  (setq-default org-download-image-dir "./images"))

(use-package olivetti
  :defer t
  :init
  (setq olivetti-body-width 90)
  (setq olivetti-recall-visual-line-mode-entry-state t)
  :hook
  ((olivetti-mode . (lambda ()
                      (visual-line-mode 1)
                      (setq-local word-wrap t)
                      (setq-local bidi-paragraph-direction nil)))
   (org-mode . (lambda ()
                 (setq org-modern-block-fringe t)))))

(use-package magit
  :after (transient)
  :init
  :commands (magit-status)
  :bind (("C-x g" . magit-status)))

(use-package anki-editor
  :ensure t)

(defun my/anki-push-after-capture ()
  (let ((file (expand-file-name "/tmp/anki.org")))
    (when (file-exists-p file)
      (with-current-buffer (find-file-noselect file)
        (condition-case err
            (progn
              (anki-editor-push-notes)
              (message "Anki: flashcard pushed successfully!"))
          (error
           (message "Anki: failed to push — %s" (error-message-string err))))))))

(add-hook 'org-capture-after-finalize-hook #'my/anki-push-after-capture)

(use-package anzu
  :config
  (global-anzu-mode 1))

(use-package expand-region
  :bind ("C-=" . er/expand-region)
  ("C--" . er/contract-region))

(use-package ace-window
  :ensure t
  :bind ("M-o" . ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

(use-package buffer-move
  :bind (:map my-leader-map
  	          ("w k" . buf-move-up)
  	          ("w j" . buf-move-down)
  	          ("w h" . buf-move-left)
  	          ("w l" . buf-move-right)))
