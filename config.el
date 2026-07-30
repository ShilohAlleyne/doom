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

;; A Scholar's Reading List Configuration
(after! org
  (setq org-agenda-custom-commands
        '(("d" "Daily Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-agenda-start-day nil)))  ; Pulls scheduled items/meetings automatically

            ;; 1. Standard Tasks (Explicitly excluding 'reading' AND 'MEETING')
            (tags-todo "CATEGORY!=\"reading\"+TODO<>\"MEETING\""
                       ((org-agenda-overriding-header "Tasks")
                        (org-agenda-sorting-strategy '(todo-state-up category-up priority-down))
                        (org-agenda-prefix-format '((tags-todo . "  %-12c %?-12t% s")))))

            ;; 2. Unified Reading List
            (tags-todo "CATEGORY=\"reading\""
                       ((org-agenda-overriding-header "Reading List")
                        (org-agenda-sorting-strategy '(todo-state-down priority-down))
                        (org-agenda-prefix-format '((tags-todo . "  %-12c %?-12t% s"))))))))))

(after! org
  (defun shaolin/auto-display-reading-clock ()
    "Automatically turn on org-clock-display for the reading list."
    (when (and (buffer-file-name)
               (string-suffix-p "reading-list.org" (buffer-file-name)))
      ;; Wrap in save-excursion so your cursor doesn't jump around
      (save-excursion
        (org-clock-display))))

  ;; 1. Run automatically when you open the file
  (add-hook 'org-mode-hook #'shaolin/auto-display-reading-clock)

  ;; 2. Refresh the totals automatically every time you stop the timer (clock out)
  (add-hook 'org-clock-out-hook #'shaolin/auto-display-reading-clock))

(after! org
  (defun shaolin/org-focus-current-reading ()
    "Collapse the file and reveal only items marked READING."
    (when (and (buffer-file-name)
               (string-suffix-p "reading-list.org" (buffer-file-name)))

      ;; 1. Fold everything down to just the top-level headers
      (org-overview)

      ;; 2. Currently READING
      (org-map-entries
       (lambda ()
         (org-show-context)   ;; Expand parent folders so this heading is visible
         (org-show-entry)     ;; Expand the properties/logbook directly underneath it
         (org-show-children)) ;; Expand its immediate child headings (e.g., chapters)
       "TODO=\"READING\"" 'file)))

  ;; Run this automatically when opening an Org mode file
  (add-hook 'org-mode-hook #'shaolin/org-focus-current-reading))

;; Inline Latex
(add-hook 'org-mode-hook 'org-fragtog-mode)

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

;; Dired improvements with Dirvish
(use-package dired
  :config
  (setq dired-listing-switches
        "-l --almost-all --human-readable --group-directories-first --no-group")
  ;; this command is useful when you want to close the window of `dirvish-side'
  ;; automatically when opening a file
  (put 'dired-find-alternate-file 'disabled nil))

(use-package dirvish
  :ensure t
  :init
  (dirvish-override-dired-mode)
  :config
  ;; (dirvish-peek-mode)             ; Preview files in minibuffer
  ;; (dirvish-side-follow-mode)      ; similar to `treemacs-follow-mode'
  (setq dirvish-mode-line-format
        '(:left (sort symlink) :right (omit yank index)))
  (setq dirvish-attributes           ; The order *MATTERS* for some attributes
        '(vc-state subtree-state nerd-icons collapse git-msg file-time file-size)
        dirvish-side-attributes
        '(vc-state nerd-icons collapse file-size))
  ;; open large directory (over 20000 files) asynchronously with `fd' command
  (setq dirvish-large-directory-threshold 20000)
  :bind ; Bind `dirvish-fd|dirvish-side|dirvish-dwim' as you see fit
  (:map doom-leader-map
   ("-" . dirvish)
   :map dirvish-mode-map               ; Dirvish inherits `dired-mode-map'
   (";"   . dired-up-directory)        ; So you can adjust `dired' bindings here
   ("?"   . dirvish-dispatch)          ; [?] a helpful cheatsheet
   ("a"   . dirvish-setup-menu)        ; [a]ttributes settings:`t' toggles mtime, `f' toggles fullframe, etc.
   ("f"   . dirvish-file-info-menu)    ; [f]ile info
   ("o"   . dirvish-quick-access)      ; [o]pen `dirvish-quick-access-entries'
   ("s"   . dirvish-quicksort)         ; [s]ort flie list
   ("r"   . dirvish-history-jump)      ; [r]ecent visited
   ("l"   . dirvish-ls-switches-menu)  ; [l]s command flags
   ("v"   . dirvish-vc-menu)           ; [v]ersion control commands
   ("*"   . dirvish-mark-menu)
   ("y"   . dirvish-yank-menu)
   ("N"   . dirvish-narrow)
   ("^"   . dirvish-history-last)
   ("TAB" . dirvish-subtree-toggle)
   ("M-f" . dirvish-history-go-forward)
   ("M-b" . dirvish-history-go-backward)
   ("M-e" . dirvish-emerge-menu)))

;; Allow Dired/Dirvish buffers to auto-refresh when files change
(setq global-auto-revert-non-file-buffers t)

;; Disable OS file notifications so Emacs falls back to active polling
;; (Crucial for WSL mounts, network shares, and cross-boundary symlinks)
(setq auto-revert-use-notify nil)

;; Set poll interval in seconds (default is 5)
(setq auto-revert-interval 2)

(setq find-file-visit-truename t)

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

(use-package outline-indent
  :commands outline-indent-minor-mode
  :custom
  (outline-indent-ellipsis " ▼"))

(after! with-editor
  (setq with-editor-emacsclient-executable "emacsclient")
  (setq with-editor-launcher 'with-editor-create-frame))

;;; --- Note Taking ---
(setq org-directory "~/org/")
(setq org-archive-location "~/org/archive.org::datree/")
(setq org-agenda-hide-tags-regexp "ATTACH")

;; Force these variables to apply AFTER Org-mode is safely initialized
(after! org
  (setq org-agenda-files '("~/org/")))

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
(remove-hook! 'text-mode-hook #'flyspell-mode)
;; Enable flyspell specifically for these modes
(add-hook! '(org-mode-hook markdown-mode-hook mu4e-compose-mode-hook)
  #'flyspell-mode)


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

(use-package ghostel
  :ensure t)

(use-package! evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

;; --- Keybindings (SPC o t / SPC o T) ---
(defun +shaolin/ghostel-at-project-root ()
  "Launch ghostel at the project root."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (ghostel)))

(map! :leader
      :desc "Ghostel terminal" "o T" #'+shaolin/ghostel-at-project-root
      :desc "Ghostel popup"    "o t" (lambda ()
                                             (interactive)
                                             (+popup/buffer (save-window-excursion
                                                              (+shaolin/ghostel-at-project-root)))))


(add-hook 'ghostel-mode-hook
          (lambda ()
            ;; Keep your margins, but clear their specific background/fringe overrides
            (setq-local scroll-conservatively 101)

            ;; Fetch current background
            (let ((my-bg (face-background 'default)))

              ;; 1. Remap the default background
              (face-remap-add-relative 'default :background my-bg)

              ;; 2. Force the Fringes to match the background
              (face-remap-add-relative 'fringe :background my-bg)

              ;; 3. Force the Margins to match the background
              ;; This ensures they exist but appear "invisible"
              (face-remap-add-relative 'left-margin :background my-bg)
              (face-remap-add-relative 'right-margin :background my-bg)

              ;; 4. Override terminal-specific faces that might fight the theme
              (face-remap-add-relative 'term-default-bg-color :background my-bg))))




;; PDFs
(after! pdf-tools
  (setq pdf-info-epdfinfo-program (executable-find "epdfinfo")))

;; Email
(set-email-account! "gmail"
  '((mu4e-sent-folder       . "/[Gmail]/Sent Mail")
    (mu4e-drafts-folder     . "/[Gmail]/Drafts")
    (mu4e-trash-folder      . "/[Gmail]/Bin")
    (mu4e-refile-folder     . "/[Gmail]/All Mail")
    (smtpmail-smtp-user     . "shiloh.t.alleyne@gmail.com"))
  t) ;; The 't' makes this your default account

(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587
      smtpmail-stream-type 'starttls)

(after! doom-modeline
  ;; Shows unread mail count in your Doom nano modeline
  (setq doom-modeline-mu4e t))

(after! mu4e
  ;; Sleek Unicode thread tree indicators
  (setq mu4e-use-fancy-chars t
        mu4e-headers-has-child-prefix '("+" . "❯ ")
        mu4e-headers-empty-parent-prefix '("-" . "  ")
        mu4e-headers-first-child-prefix '("\\" . "↳ ")
        mu4e-headers-duplicate-prefix '("=" . "≡ ")))

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

;; Force Emacs to open links in the default Windows browser
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "explorer.exe")

;; (map! :leader
;;       (:prefix ("w" . "wsl")
;;        :desc "WSL Copy" "y" #'wsl-copy-region
;;        :desc "WSL Paste" "p" #'wsl-paste-clipboard))
