;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; UI & Aesthetics ---
(setq doom-font                (font-spec :family "IosevkaTerm Nerd Font Mono" :size 22)
      doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 22)
      doom-serif-font          (font-spec :family "IosevkaTerm Nerd Font Mono" :size 22))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(setq default-frame-alist '((width . 120) (height . 40) (vertical-scroll-bars . nil)))

(modify-all-frames-parameters
 '((right-divider-width . 40)
   (internal-border-width . 40)))
(dolist (face '(window-divider
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))
(set-face-background 'fringe (face-attribute 'default :background))

(global-org-modern-mode)

;; Theme & Modeline
(setq doom-theme 'doom-nano-light)

(use-package! doom-nano-modeline
  :config
  (doom-nano-modeline-mode 1)
  ;; Force the global bottom window modelines to drop down to 0 pixels high
  (setq-default mode-line-format nil)
  (add-hook 'after-change-major-mode-hook (lambda () (setq mode-line-format nil))))

;; --- Dashboard ---
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)

;;; Random Quote Dashboard Widget
(defun shaolin/dashboard-quote ()
  "Return a random quote from quotes.json."
  (let* ((json-file (expand-file-name "quotes.json" doom-user-dir))
         (json-object-type 'alist)
         (json-array-type 'list))
    (when (file-exists-p json-file)
      (with-temp-buffer
        (insert-file-contents json-file)
        (let* ((quotes (json-read))
               (random-quote (nth (random (length quotes)) quotes)))
          (format "\"%s\"\n— %s (p. %s)"
                  (cdr (assoc 'quote random-quote))
                  (cdr (assoc 'source random-quote))
                  (cdr (assoc 'page random-quote))))))))

(add-hook! '+doom-dashboard-functions :append
  (insert "\n" (+doom-dashboard--center +doom-dashboard--width "Hello, there!")))

;; (defun shaolin/render-quote-widget ()
;;   "Render the quote widget on the dashboard."
;;   (when-let ((quote-text (shaolin/dashboard-quote)))
;;     (insert "\n\n" (+doom-dashboard--center +doom-dashboard--width quote-text) "\n")))

;; (add-hook! '+doom-dashboard-functions :append #'shaolin/render-quote-widget)




(setq fancy-splash-image "~/.config/doom/images/metamorfose-I.jpg"
      +doom-dashboard-banner-padding '(0 . 0)
      +doom-dashboard-banner-footer nil)

;; Line Numbers
(setq display-line-numbers-type 'relative)
(add-hook 'org-mode-hook      (lambda () (display-line-numbers-mode -1)))
(add-hook 'markdown-mode-hook (lambda () (display-line-numbers-mode -1)))

;; Org Changes
(custom-set-faces!
  ;; Setting :background to nil forces it to use your theme's native background
  '(org-block            :inherit (fixed-pitch default) :background nil)
  '(org-block-begin-line :inherit (fixed-pitch default) :foreground "#999999" :background nil)
  '(org-block-end-line   :inherit (fixed-pitch default) :foreground "#999999" :background nil)

  ;; Tables
  '(org-table           :inherit fixed-pitch)
  '(org-formula         :inherit fixed-pitch :foreground "#999999"))

;; Markdown Changes
(custom-set-faces!
  ;; Code blocks
  '(markdown-code-face :inherit (fixed-pitch default) :background nil)
  '(markdown-pre-face  :inherit (fixed-pitch default) :background nil)

  ;; Inline code
  '(markdown-inline-code-face :inherit (fixed-pitch default) :background nil)

  ;; Tables
  '(markdown-table-face :inherit fixed-pitch :foreground "#999999"))

;; Typst
(use-package! typst-ts-mode
  :mode ("\\.typ\\'" . typst-ts-mode))

;; Vterm Color & UI Fixes
(after! vterm
  ;; 1. Force the layout buffer to inherit the exact font and text size definitions
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local buffer-face-mode-face `(:family ,(face-attribute 'default :font) :height 22))
              (buffer-face-mode 1)))

  ;; 2. The Missing Link: Override ANSI terminal sequences with your theme palette
  (setq vterm-eval-cmds nil) ; Security setting

  ;; Dynamically bind vterm colors to active Doom theme attributes
  (custom-set-faces!
    `(vterm-color-black   :foreground ,(doom-color 'bg)      :background ,(doom-color 'bg))
    `(vterm-color-red     :foreground ,(doom-color 'red)     :background ,(doom-color 'red))
    `(vterm-color-green   :foreground ,(doom-color 'green)   :background ,(doom-color 'green))
    `(vterm-color-yellow  :foreground ,(doom-color 'yellow)  :background ,(doom-color 'yellow))
    `(vterm-color-blue    :foreground ,(doom-color 'blue)    :background ,(doom-color 'blue))
    `(vterm-color-magenta :foreground ,(doom-color 'magenta) :background ,(doom-color 'magenta))
    `(vterm-color-cyan    :foreground ,(doom-color 'cyan)    :background ,(doom-color 'cyan))
    `(vterm-color-white   :foreground ,(doom-color 'fg)      :background ,(doom-color 'fg))))

;; --- Code ---
;; (use-package indent-bars
;;   :hook ((haskell-mode) . indent-bars-mode))

;; Haskell
(after! haskell-mode
  (setq haskell-indentation-layout-offset 4
        haskell-indentation-starter-offset 4
        haskell-indentation-left-offset 4
        haskell-indentation-where-pre-offset 4
        haskell-indentation-where-post-offset 4))

;; Set default global indentation to 4 spaces
(setq-default tab-width 4
              standard-indent 4
              indent-tabs-mode nil) ; Use spaces, not actual tab characters

;; Force Lisps to keep their standard 2-space structural layout
(defun lisp-indentation ()
  (setq-local tab-width 2
              standard-indent 2))

(add-hook 'emacs-lisp-mode-hook #'lisp-indentation)
(add-hook 'clojure-mode-hook    #'lisp-indentation)
(add-hook 'scheme-mode-hook     #'lisp-indentation)
(add-hook 'lisp-mode-hook       #'lisp-indentation)

;;; --- Note Taking ---
(setq org-directory "~/org/")

;; Force these variables to apply AFTER Org-mode is safely initialized
(after! org
  (setq org-agenda-files '("/home/shiloh/org")))

(use-package! org-modern-indent
  :after org-modern
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

;; Denote
(use-package! denote
  :config
  (setq denote-directory (expand-file-name "~/org/"))
  (denote-rename-buffer-mode 1));
;
;; --- LaTeX/Math Rendering ---
(after! org
  ;; Use dvisvgm for razor-sharp, scalable inline math previews instead of dvipng
  (setq org-preview-latex-default-process 'dvisvgm)
  ;; Scale rendered fragment equations to be clear and readable
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.5)))

;; Recommended: Add a shortcut for Denote
(map! :leader
      (:prefix ("n" . "notes")
       :desc "Create new note" "n" #'denote
       :desc "Find note"       "f" #'denote-open-or-create))

;; Spelling
(after! flyspell
  (setq ispell-program-name "hunspell")

  ;; Force the environment path variable inside Emacs's execution context
  (setenv "DICPATH" (expand-file-name "~/.config/hunspell"))

  ;; 1. Bypass the dictionary detection logic by pre-populating the internal cache
  (setq ispell-hunspell-dictionary-alist
        '(("en_GB" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_GB") nil utf-8)))

  ;; 2. Explicitly force the active session definitions
  (setq ispell-local-dictionary "en_GB")
  (setq ispell-local-dictionary-alist
        '(("en_GB" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_GB") nil utf-8)))

  ;; 3. Trick the fallback checker into seeing your local .aff symlink
  (setq ispell-hunspell-dict-paths-alist
        '(("en_GB" "~/.config/hunspell/en_GB.aff"))))

(setq ispell-dictionary "en_GB")

;; Enable for Org and Markdown
(add-hook 'org-mode-hook #'flyspell-mode)
(add-hook 'markdown-mode-hook #'flyspell-mode)

;; --- Centring ---
(setq-default olivetti-body-width 120)
(setq olivetti-style 'minimal)

;; 2. Direct configuration function
(defun setup-olivetti-layout ()
  "Apply centered layout, font, and spacing."
  (olivetti-mode 1)
  (visual-line-mode 1)
  (setq-local line-spacing 0.3)
  (face-remap-add-relative 'default :family "Iosevka Aile"))

;; 3. Hook into modes
(add-hook 'org-mode-hook #'setup-olivetti-layout)
(add-hook 'markdown-mode-hook #'setup-olivetti-layout)


;; --- Functionality ---
(after! server
  (unless (server-running-p)
    (server-start)))

(setq vterm-shell "zsh")

;; Vterm Color & UI Fixes
(after! vterm
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local face-remapping-alist
                          `((default (:background ,(face-attribute 'default :background))
                                     (:foreground ,(face-attribute 'default :foreground)))))))

  (setq vterm-term-environment-variable "xterm-256color")

  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local buffer-face-mode-face `(:family ,(face-attribute 'default :font) :height 22))
              (buffer-face-mode 1))))

(setq vterm-kill-buffer-on-exit t  ; (Optional but good) Clean up buffer on exit
      window-adjust-process-window-size-function nil) ; Disables the rigid grid enforcement

;; PDFs
(after! pdf-tools
  (setq pdf-info-epdfinfo-program (executable-find "epdfinfo")))


;; --- WSL ---
(setq default-directory "/home/shiloh/")

;; Clipboard Bridge (WSL to Windows)
(defun wsl-copy-region (start end)
  "Copy region to Windows clipboard."
  (interactive "r")
  (shell-command-on-region start end "clip.exe")
  (deactivate-mark))

(defun wsl-paste-clipboard ()
  "Paste from Windows clipboard into Emacs."
  (interactive)
  (let ((clipboard-content (shell-command-to-string "powershell.exe -command 'Get-Clipboard'")))
    (insert (replace-regexp-in-string "\r" "" clipboard-content))))

;; (map! :leader
;;       (:prefix ("w" . "wsl")
;;        :desc "WSL Copy" "y" #'wsl-copy-region
;;        :desc "WSL Paste" "p" #'wsl-paste-clipboard))
