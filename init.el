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
  (setq native-comp-async-report-warnings-errors 'silent)

  (add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

  (require 'pomodoro)

  (use-package no-littering
    :straight t
    :config
    (require 'no-littering)
    (setq auto-save-file-name-transforms
          `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

  (use-package minions
    :ensure t
    :config
    (setq minions-prominent-modes
          '(olivetti-mode))
    (minions-mode 1))

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
   ("M-="           . text-scale-increase)
   ("M--"           . text-scale-decrease)
   ("M-0"           . (lambda () (interactive) (text-scale-set 0)))
   ("C-}"           . forward-paragraph)
   ("C-{"           . backward-paragraph)

   ;; C-c prefix
   :map global-map
   ("C-c f" . find-file-at-point)
   ("C-c h" . previous-buffer)
   ("C-c l" . next-buffer)
   ("C-c o c" . my/open-config))

  (bind-keys :prefix-map my-leader-map
             :prefix "C-z"
             ("h"     . help-command)
             ("c"     . org-capture)
             ("t"     . org-babel-tangle)
             ("p p s" . my/pomodoro-start)
             ("p p q" . my/pomodoro-stop)
             ("m l"   . magit-list-repositories))

  (use-package emacs
    :init
    (setq duplicate-line-final-position 1
          isearch-allow-scroll t
          global-auto-revert-non-file-buffers t
          switch-to-buffer-obey-display-actions t
          scroll-preserve-screen-position t
          scroll-margin 5
          whitespace-style '(face tabs tab-mark trailing)
          use-package-compute-statistics t
          shr-use-fonts t
          shr-width nil
          isearch-wrap-pause 'no-ding
          ;; interactions
          use-short-answers t
          confirm-kill-emacs 'yes-or-no-p
          ;;scratch buffer
          initial-scratch-message "* Scratch Buffer"
          initial-major-mode 'org-mode
          initial-buffer-choice t
          ;; input method
          default-input-method "arabic")

    (set-fringe-mode 12)
    (setq-default display-line-numbers-width 2)
    (global-set-key [remap dabbrev-expand] #'hippie-expand)

    (setq custom-file
          (expand-file-name "custom.el" user-emacs-directory))
    (when (file-exists-p custom-file)
      (load custom-file t))

    (global-whitespace-mode t)
    (column-number-mode t)
    (recentf-mode t)
    (savehist-mode t)
    (delete-selection-mode t)
    (global-auto-revert-mode t)
    (xterm-mouse-mode t)
    (auto-save-visited-mode t)
    (global-visual-line-mode t)
    (electric-pair-mode t)
    (electric-indent-mode nil)

    :custom
    ;; Vertico
    (context-menu-mode t)
    (enable-recursive-minibuffers t)
    (read-extended-command-predicate #'command-completion-default-include-p)
    (minibuffer-prompt-properties
     '(read-only t cursor-intangible t face minibuffer-prompt))

    ;; Corfu
    (tab-always-indent 'complete)
    (text-mode-ispell-word-completion nil)
    (read-extended-command-predicate #'command-completion-default-include-p)

    :hook
    (before-save . delete-trailing-whitespace)
    (isearch-mode-end-hook .
                           (lambda ()
                             (when (and isearch-forward (not isearch-mode-end-hook-quit))
                               (goto-char isearch-other-end)))))

  (use-package recentf
    :ensure nil
    :config
    (setq ;;recentf-auto-cleanup 'never
     ;; recentf-max-menu-items 0
     recentf-max-saved-items 200)
    (setq recentf-filename-handlers ;; Show home folder path as a ~
          (append '(abbreviate-file-name) recentf-filename-handlers))
    (recentf-mode))

  (set-face-attribute 'default nil
                      :family "JetBrains Mono Nerd Font"
                      :height 110
                      :weight 'regular)

  (set-face-attribute 'fixed-pitch nil
                      :family "JetBrains Mono Nerd Font"
                      :height 110)

  (set-face-attribute 'variable-pitch nil
                      :family "PlaywriteGBJ"
                      :height 120)

  (set-fontset-font t 'arabic
                    (font-spec :family "Cairo"
                               :size 15))

  (setq-default line-spacing 0.12)
  (add-to-list 'default-frame-alist '(font . "JetBrains Mono Nerd Font-11"))

  (use-package ligature
    :ensure t
    :config
    (ligature-set-ligatures 'prog-mode
                            '("|||" ">>>" "=>" ">=" "->>" "->" "-->"
                              "<-" "<-->" "<<-" "<->" "<=" "<==" "<=>" "<~"
                              "++" "+++" ":::" "::" "!="
                              "/*" "*/" "%%" "&&"))
    (global-ligature-mode t))

  (use-package ace-window
    :ensure t
    :bind ("M-o" . ace-window)
    :config
    (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))


  (use-package buffer-move
    :bind (:map my-leader-map
                ("w k" . buf-move-up)
                ("w j" . buf-move-down)
                ("w h" . buf-move-left)
                ("w l" . buf-move-right)))

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

  (use-package multiple-cursors
    :ensure t
    :bind (("C->"           . mc/mark-next-like-this)
           ("C-<"           . mc/mark-previous-like-this)
           ("C-M-<"         . mc/skip-to-previous-like-this)
           ("C-M->"         . mc/skip-to-next-like-this)
           ("C-c m d"       . mc/mark-all-dwim)
           ("C-c m a"       . mc/mark-all-like-this)
           ("C-c m n"       . electric-newline-and-maybe-indent)
           ("C-c m e"       . mc/edit-lines))
    :config
    (setq mc/always-run-for-all t))

  (use-package expand-region
    :bind
    ("C-=" . er/expand-region)
    ("C--" . er/contract-region))

  (require 'dired-x)
  (setq dired-omit-files
        (concat dired-omit-files "\\|^\\..+$"))
  (setq-default dired-dwim-target t)
  (setq dired-listing-switches "-alh")
  (setq dired-mouse-drag-files t)

  (setq-default fill-column 80)
  (setq display-line-numbers-type 'relative)
  (add-hook 'prog-mode-hook 'display-line-numbers-mode)
  (add-hook 'prog-mode-hook 'display-fill-column-indicator-mode)

  (use-package gruvbox-material-emacs
    :straight (gruvbox-material-emacs
               :local-repo "~/Projects/personal/gruvbox-material-emacs/"
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
          gm-syntax-keywords          'regular
          gm-light-contrast           'hard)
    :config
    (gruvbox-material-load))

  (use-package ef-themes
    :defer t
    :init
    (ef-themes-take-over-modus-themes-mode 1)
    :bind
    (("<f6>" . modus-themes-rotate)
     ("C-<f6>" . modus-themes-select)
     ("M-<f6>" . modus-themes-load-random))
    :config
    (setq modus-themes-mixed-fonts t)
    (setq modus-themes-italic-constructs t))
  ;;(modus-themes-load-theme 'ef-dream))

  (use-package solarized-theme)

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

  ;; Company mode
  (use-package company
    :disabled t
    :ensure t
    :hook (after-init . global-company-mode)
    :bind (:map company-active-map
                ("C-j" . company-select-next)
                ("C-k" . company-select-previous)
                ("TAB" . company-complete-selection)))

  (use-package corfu
    :ensure t
    :custom
    (corfu-cycle t)
    (corfu-auto t)
    (corfu-auto-delay 0.2)
    (corfu-auto-prefix 2)
    (corfu-quit-at-boundary 'separator)
    (corfu-quit-no-match 'separator)
    (corfu-preview-current t)
    (corfu-echo-documentation t)
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)

    :init
    (global-corfu-mode)

    :config
    (add-hook 'eshell-mode-hook (lambda () (corfu-mode -1)))
    (setq corfu-highlight-matches nil)

    :bind
    (:map corfu-map
          ("C-j" . corfu-next)
          ("C-k" . corfu-previous)
          ("M-SPC" . corfu-insert-separator)
          ("<escape>" . corfu-quit)
          ("RET" . nil)))

  (defun my/corfu-enable-in-minibuffer ()
    (unless (or (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input)
                (eq (current-local-map) read-expression-map))
      (setq-local corfu-auto t)
      (corfu-mode 1)))

  (add-hook 'minibuffer-setup-hook #'my/corfu-enable-in-minibuffer)

  (use-package cape
    :init
    (add-to-list 'completion-at-point-functions #'cape-file)
    (add-to-list 'completion-at-point-functions #'cape-keyword))

  (use-package kind-icon
    :config
    (setq kind-icon-default-face 'corfu-default)
    (setq kind-icon-default-style '(:padding 0 :stroke 0 :margin 0 :radius 0 :height 0.9 :scale 1))
    (setq kind-icon-blend-frac 0.08)
    (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)
    (add-hook 'counsel-load-theme #'(lambda () (interactive) (kind-icon-reset-cache)))
    (add-hook 'load-theme         #'(lambda () (interactive) (kind-icon-reset-cache))))

  (use-package yasnippet
    :config
    (setq yas-snippet-dirs '("~/.config/emacs/snippets"))
    (yas-global-mode 1))

  (use-package markdown-mode
    :ensure t
    :mode ("README\\.md\\'" . gfm-mode)
    :init (setq markdown-command "multimarkdown")
    :bind (:map markdown-mode-map
                ("C-c C-m C-d" . markdown-do)))

  ;; (add-hook 'markdown-mode-hook 'variable-pitch-mode)

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
    (add-to-list 'aggressive-indent-excluded-modes 'conf-mode)
    (add-to-list 'aggressive-indent-excluded-modes 'html-mode))

  (use-package editorconfig
    :ensure t
    :config
    (editorconfig-mode 1))

(setq treesit-language-source-alist
      '((bash       "https://github.com/tree-sitter/tree-sitter-bash")
        (c           "https://github.com/tree-sitter/tree-sitter-c"          "v0.21.4")
        (cpp        "https://github.com/tree-sitter/tree-sitter-cpp")
        (html       "https://github.com/tree-sitter/tree-sitter-html")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
        (json       "https://github.com/tree-sitter/tree-sitter-json")
        (python     "https://github.com/tree-sitter/tree-sitter-python")
        (java       "https://github.com/tree-sitter/tree-sitter-java")))

(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (python-mode . python-ts-mode)
        (java-mode . java-ts-mode)
        (js-mode . js-ts-mode)
        (json-mode . json-ts-mode)))

  (setq org-hide-leading-stars t
        org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-src-tab-acts-natively t
        org-src-fontify-natively t
        jit-lock-defer-time 0
        jit-lock-stealth-time 1
        org-src-preserve-indentation t
        org-pretty-entities t
        org-preview-latex-default-process 'dvisvgm
        org-startup-with-latex-preview t
        org-log-done 'note)

  (setq org-format-latex-options
        (plist-put org-format-latex-options :scale 1.4))

  (with-eval-after-load 'org
    (require 'org-tempo))

  (add-hook 'org-mode-hook
            (lambda ()
              (visual-line-mode 1)
              (electric-pair-local-mode -1)))

  ;; (add-hook 'org-mode-hook 'variable-pitch-mode)
  (add-hook 'org-mode-hook #'org-indent-mode)

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (C . t)
     (shell . t)
     (java . t)))

  (setq org-confirm-babel-evaluate nil
        python-shell-completion-native-enable nil
        org-src-window-setup 'current-window)

  (use-package olivetti
    :defer t
    :init
    (setq olivetti-body-width 90)
    (setq olivetti-recall-visual-line-mode-entry-state t)
    :hook
    (eww-mode . olivetti-mode))

  (use-package anki-editor
    :straight (anki-editor
               :type git
               :host github
               :repo "louietan/anki-editor"))

  ;; Upload to  via org-capture
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

  (use-package magit
    :ensure t
    :after transient
    :commands (magit-status)
    :hook
    (magit-mode    . (lambda () (variable-pitch-mode -1)))
    (git-commit-mode . (lambda () (variable-pitch-mode -1)))
    :bind (("C-x g" . magit-status)
           ("C-x v" . magit-diff-visit-file-other-window)))

  (setq magit-repository-directories
        '(("~/Dotfiles/" . 0)
          ("~/Projects" . 2)))

  (use-package diff-hl
    :config
    (global-diff-hl-mode 1)
    (setq diff-hl-fringe-bmp-function #'diff-hl-fringe-bmp-from-type)
    (diff-hl-show-hunk-mouse-mode)
    (diff-hl-flydiff-mode 1)
    (add-hook 'magit-pre-refresh-hook  'diff-hl-magit-pre-refresh)
    (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
    (add-hook 'dired-mode-hook 'diff-hl-dired-mode))

  (use-package anzu
    :config
    (global-anzu-mode 1))

  (define-minor-mode my/focus-mode
    "Toggle Focus Mode for distraction-free writing."
    :lighter " Focus"
    (if my/focus-mode
        (progn
          ;; turn ON
          (olivetti-mode 1)
          (display-line-numbers-mode 0)
          (setq-local display-fill-column-indicator-mode nil)
          (setq-local cursor-type 'bar))

      ;; turn OFF
      (progn
        (olivetti-mode -1)
        (display-line-numbers-mode 1)
        (display-fill-column-indicator-mode 1))))

  (defun my/focus-mode-on-input-change ()
    (when (derived-mode-p 'org-mode 'text-mode 'markdown-mode)
      (if current-input-method
          (my/focus-mode 1)
        (my/focus-mode -1))))

  (add-hook 'input-method-activate-hook #'my/focus-mode-on-input-change)
  (add-hook 'input-method-inactivate-hook #'my/focus-mode-on-input-change)
