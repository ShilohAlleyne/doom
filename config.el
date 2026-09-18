;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

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

(setq doom-font                (font-spec :family "IosevkaTerm Nerd Font Mono" :size 30)
      doom-variable-pitch-font (font-spec :family "Iosevka Aile"               :size 30)
      doom-serif-font          (font-spec :family "IosevkaTerm Nerd Font Mono" :size 30))

(setq doom-theme 'doom-nano-dorfic)

(use-package! doom-nano-modeline
  :config
  (doom-nano-modeline-mode 1)
  (setq-default mode-line-format nil)
  (add-hook 'after-change-major-mode-hook (lambda () (setq mode-line-format nil))))

(setq fancy-splash-image (expand-file-name "images/emacs-wildebeest-template.svg" doom-user-dir))
(setq +doom-dashboard-banner-padding  '(4 . 0))

(setq display-line-numbers-type 'relative)

(setq org-directory "~/org/")
(setq org-archive-location "~/org/archive.org::datree/")
(setq org-agenda-hide-tags-regexp "ATTACH")

(use-package! org-modern
  :hook (org-mode . global-org-modern-mode))

(add-hook 'org-mode-hook (lambda () (display-line-numbers-mode -1)))

(use-package! org-modern-indent
  :after org-modern
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

(custom-set-faces!
  '(org-block            :inherit (fixed-pitch default) :background nil)
  '(org-block-begin-line :inherit (fixed-pitch default) :foreground "#999999" :background nil)
  '(org-block-end-line   :inherit (fixed-pitch default) :foreground "#999999" :background nil)
  '(org-table            :inherit fixed-pitch)
  '(org-formula          :inherit fixed-pitch :foreground "#999999")
  '(org-property-value   :inherit fixed-pitch)
  '(org-special-keyword  :inherit fixed-pitch)
  '(org-meta-line        :inherit fixed-pitch))

(after! org
  (setq org-agenda-files '("~/org/")))

(after! org
  (setq org-agenda-custom-commands
        '(("d" "Daily Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-agenda-start-day nil)))
            (tags-todo "CATEGORY!=\"reading\"+TODO<>\"MEETING\""
                       ((org-agenda-overriding-header "Tasks")
                        (org-agenda-sorting-strategy '(todo-state-up category-up priority-down))
                        (org-agenda-prefix-format '((tags-todo . "  %-12c %?-12t% s")))))
            (tags-todo "CATEGORY=\"reading\""
                       ((org-agenda-overriding-header "Reading List")
                        (org-agenda-sorting-strategy '(todo-state-down priority-down))
                        (org-agenda-prefix-format '((tags-todo . "  %-12c %?-12t% s"))))))))))

(setq org-agenda-todo-list-sublevels nil)

(after! org
  (defun shaolin/auto-display-reading-clock ()
    "Automatically turn on org-clock-display for the reading list."
    (when (and (buffer-file-name)
               (string-suffix-p "reading-list.org" (buffer-file-name)))
      (save-excursion
        (org-clock-display))))

  (add-hook 'org-mode-hook #'shaolin/auto-display-reading-clock)
  (add-hook 'org-clock-out-hook #'shaolin/auto-display-reading-clock))

(after! org
  (defun shaolin/org-focus-current-reading ()
    "Collapse the file and reveal only items marked READING."
    (when (and (buffer-file-name)
               (string-suffix-p "reading-list.org" (buffer-file-name)))
      (org-overview)
      (org-map-entries
       (lambda ()
         (org-show-context)
         (org-show-entry)
         (org-show-children))
       "TODO=\"READING\"" 'file)))

  (add-hook 'org-mode-hook #'shaolin/org-focus-current-reading))

(defun org-cya-archive ()
  "Archive current item to done.org file."
  (interactive)
  (unless (member (org-get-todo-state) org-done-keywords)
    (user-error "Task is not in a completed state. Mark it completed first!"))

  (let* ((archive-file  (expand-file-name "done.org" org-directory))
         (date-header   (format-time-string "%Y-%m-%d %a"))
         (archive-time  (format-time-string "%H:%M"))
         (original-file (or (buffer-file-name) (buffer-name)))
         (raw-category  (org-get-category))
         (category      (if (and raw-category (not (string-empty-p raw-category)))
                            raw-category "N/A"))
         (olpath        (mapconcat #'identity (org-get-outline-path) "/"))
         (tree-text     (progn
                          (org-mark-subtree)
                          (let ((text (delete-and-extract-region (region-beginning) (region-end))))
                            (deactivate-mark)
                            text))))

    (unless (file-exists-p archive-file)
      (make-directory (file-name-directory archive-file) t)
      (append-to-file "" nil archive-file))

    (let ((archive-buf (find-file-noselect archive-file)))
      (with-current-buffer archive-buf
        (save-restriction
          (widen)
          (save-excursion
            (goto-char (point-min))
            (if (re-search-forward (format "^\\* %s$" (regexp-quote date-header)) nil t)
                (progn
                  (forward-line 1)
                  (org-paste-subtree 2 tree-text))
              (progn
                (goto-char (point-min))
                (let ((missing-lines (forward-line 6)))
                  (dotimes (_ missing-lines) (insert "\n")))
                (unless (bolp) (insert "\n"))
                (insert (format "* %s\n" date-header))
                (org-paste-subtree 2 tree-text)))

            (org-back-to-heading t)
            (org-entry-put (point) "ARCHIVE_TIME" archive-time)
            (org-entry-put (point) "ARCHIVE_FILE" original-file)
            (org-entry-put (point) "ARCHIVE_CATEGORY" category)
            (when (not (string-empty-p olpath))
              (org-entry-put (point) "ARCHIVE_OLPATH" olpath))))
        (save-buffer)
        (message "Successfully archived to %s under %s!"
                 (file-name-nondirectory archive-file) date-header)))))

(defun org-cya-archive-recurring ()
  "Archive a clone of the current recurring item to done.org."
  (interactive)
  (unless (org-at-heading-p)
    (org-back-to-heading t))

  (let* (;; Step 1: Detect the current state of the active item
         (initial-state  (org-get-todo-state))
         (_              (unless initial-state
                           (user-error "No TODO or MEETING keyword found on this headline!")))

         ;; Step 2: Dynamically tailor the allowed closed states based on item type
         (allowed-states (if (string= initial-state "MEETING")
                             '("HELD" "CANCELLED" "DNA" "DONE")
                           '("DONE" "KILL" "CANCELLED")))
         (chosen-state   (completing-read
                          (format "Archive %s instance as state (default %s): "
                                  initial-state (car allowed-states))
                          allowed-states nil t nil nil (car allowed-states)))

         (archive-file  (expand-file-name "done.org" org-directory))
         (date-header   (format-time-string "%Y-%m-%d %a"))
         (archive-time  (format-time-string "%H:%M"))
         (original-file (or (buffer-file-name) (buffer-name)))
         (raw-category  (org-get-category))
         (category      (if (and raw-category (not (string-empty-p raw-category))) raw-category "N/A"))
         (olpath        (mapconcat #'identity (org-get-outline-path) "/"))

         ;; Step 3: Clone the current entry into the kill ring safely
         (_             (save-excursion (org-copy-subtree)))

         ;; Step 4: Transform the clone inside an isolated sandbox buffer
         (processed-tree-text
          (with-temp-buffer
            (org-mode)
            (org-paste-subtree 1)
            (goto-char (point-min))

            ;; Force the cloned heading to become a Level 2 (**) entry to match your archive standard
            (let ((components (org-heading-components)))
              (when components
                (let ((level (car components)))
                  (cond ((< level 2) (dotimes (_ (- 2 level)) (org-demote-subtree)))
                        ((> level 2) (dotimes (_ (- level 2)) (org-promote-subtree)))))))

            (goto-char (point-min))
            ;; Swap out the active keyword for the user's chosen completed state
            (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
              (delete-region (line-beginning-position) (line-end-position))
              (if (string-match "^\\(\\*+\\)\\s-+\\([A-Z-]+\\)\\s-+" line)
                  (insert (replace-regexp-in-string "^\\(\\*+\\)\\s-+[A-Z-]+\\s-+" (format "\\1 %s " chosen-state) line))
                (insert (replace-regexp-in-string "^\\(\\*+\\)\\s-*" (format "\\1 %s " chosen-state) line))))

            ;; Strip active repeating time stamps so they don't break target agendas
            (goto-char (point-min))
            (while (re-search-forward org-scheduled-time-regexp nil t) (replace-match ""))
            (goto-char (point-min))
            (while (re-search-forward org-deadline-time-regexp nil t) (replace-match ""))

            ;; Inject metadata blocks identically to your core system
            (goto-char (point-min))
            (org-back-to-heading t)
            (org-entry-put (point) "ARCHIVE_TIME" archive-time)
            (org-entry-put (point) "ARCHIVE_FILE" original-file)
            (org-entry-put (point) "ARCHIVE_CATEGORY" category)
            (unless (string-empty-p olpath)
              (org-entry-put (point) "ARCHIVE_OLPATH" olpath))

            ;; Clean trailing padding newlines picked up by org-copy/paste
            (string-trim-right (buffer-substring-no-properties (point-min) (point-max))))))

    ;; Step 5: Ensure target archive file exists on disk
    (unless (file-exists-p archive-file)
      (make-directory (file-name-directory archive-file) t)
      (append-to-file "" nil archive-file))

    ;; Step 6: Inject the processed text block directly into your layout using literal insert
    (let ((archive-buf (find-file-noselect archive-file)))
      (with-current-buffer archive-buf
        (save-restriction
          (widen)
          (save-excursion
            (goto-char (point-min))
            (if (re-search-forward (format "^\\* %s$" (regexp-quote date-header)) nil t)
                (progn
                  (forward-line 1)
                  (unless (bolp) (insert "\n"))
                  ;; Insert item plus a strict single trailing line delimiter
                  (insert processed-tree-text "\n"))
              (progn
                (goto-char (point-min))
                (let ((missing-lines (forward-line 6)))
                  (dotimes (_ missing-lines) (insert "\n")))
                (unless (bolp) (insert "\n"))
                (insert (format "* %s\n" date-header))
                ;; Insert item plus a strict single trailing line delimiter
                (insert processed-tree-text "\n")))))
        (save-buffer)))

    ;; Step 7: Push the original item loop forward in your active workspace file
    (org-todo initial-state)
    (message "Successfully logged recurring %s instance as %s!" initial-state chosen-state)))

(after! org
  (setq org-preview-latex-default-process 'dvisvgm)
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.0))
  (setq org-format-latex-options (plist-put org-format-latex-options :justify 'center)))

(add-hook 'org-mode-hook 'org-fragtog-mode)

(use-package! denote
  :config
  (setq denote-directory (expand-file-name "~/org/"))
  (denote-rename-buffer-mode 1))

(map! :leader
      (:prefix ("n" . "notes")
       :desc "Create new note" "n" #'denote
       :desc "Find note"       "f" #'denote-open-or-create))

(use-package! typst-ts-mode
  :mode ("\\.typ\\'" . typst-ts-mode))

(after! pdf-tools
  (setq pdf-info-epdfinfo-program (executable-find "epdfinfo")))

(add-hook 'markdown-mode-hook (lambda () (display-line-numbers-mode -1)))

(custom-set-faces!
  '(markdown-code-face        :inherit (fixed-pitch default) :background nil)
  '(markdown-pre-face         :inherit (fixed-pitch default) :background nil)
  '(markdown-inline-code-face :inherit (fixed-pitch default) :background nil)
  '(markdown-table-face       :inherit fixed-pitch :foreground "#999999"))

(after! flyspell
  (setq ispell-program-name "hunspell")
  (setenv "DICPATH" (expand-file-name "~/.config/hunspell"))

  (setq ispell-hunspell-dictionary-alist
        '(("en_GB" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_GB") nil utf-8)))

  (setq ispell-local-dictionary "en_GB")
  (setq ispell-local-dictionary-alist
        '(("en_GB" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_GB") nil utf-8)))

  (setq ispell-hunspell-dict-paths-alist
        '(("en_GB" "~/.config/hunspell/en_GB.aff"))))

(setq ispell-dictionary "en_GB")

(remove-hook! 'text-mode-hook #'flyspell-mode)

(add-hook! '( org-mode-hook
              markdown-mode-hook
              typst-ts-mode-hook
              typst-mode-hook
              mu4e-compose-mode-hook )
  #'flyspell-mode)

(setq-default olivetti-body-width 120)
(setq         olivetti-style 'minimal)

(defun setup-olivetti-layout ()
  "Apply centered layout, font, and spacing."
  (olivetti-mode 1)
  (visual-line-mode 1)
  (setq-local line-spacing 0.3)
  (face-remap-add-relative 'default :family "Iosevka Aile"))

(add-hook 'org-mode-hook #'setup-olivetti-layout)
(add-hook 'markdown-mode-hook #'setup-olivetti-layout)

(with-eval-after-load 'org
  (add-to-list 'org-capture-templates
               '("r" "Reading List (At Point)" entry
                 (here)
                 "*** UNREAD %^{Title}\n:PROPERTIES:\n:AUTHOR:   %^{Author}\n:TYPE:     %^{Type|Paper|Book|Article|Blog}\n:YEAR:     %^{Year}\n:LINK:     %^{Link}\n:Effort:   %^{Effort}\n:END:\n%?"
                 :empty-lines 1)))

(use-package dired
  :config
  (setq dired-listing-switches
        "-l --almost-all --human-readable --group-directories-first --no-group")
  (put 'dired-find-alternate-file 'disabled nil))

(use-package dirvish
  :ensure t
  :init
  (dirvish-override-dired-mode)
  :config
  (setq dirvish-mode-line-format
        '(:left (sort symlink) :right (omit yank index)))
  (setq dirvish-attributes
        '(vc-state subtree-state nerd-icons collapse git-msg file-time file-size)
        dirvish-side-attributes
        '(vc-state nerd-icons collapse file-size))
  (setq dirvish-large-directory-threshold 20000)
  :bind
  (:map doom-leader-map
   ("-" . dirvish)
   :map dirvish-mode-map
   (";"   . dired-up-directory)
   ("?"   . dirvish-dispatch)
   ("a"   . dirvish-setup-menu)
   ("f"   . dirvish-file-info-menu)
   ("o"   . dirvish-quick-access)
   ("s"   . dirvish-quicksort)
   ("r"   . dirvish-history-jump)
   ("l"   . dirvish-ls-switches-menu)
   ("v"   . dirvish-vc-menu)
   ("*"   . dirvish-mark-menu)
   ("y"   . dirvish-yank-menu)
   ("N"   . dirvish-narrow)
   ("^"   . dirvish-history-last)
   ("TAB" . dirvish-subtree-toggle)
   ("M-f" . dirvish-history-go-forward)
   ("M-b" . dirvish-history-go-backward)
   ("M-e" . dirvish-emerge-menu)))

(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-use-notify nil)
(setq auto-revert-interval 2)
(setq find-file-visit-truename t)

(setq-default tab-width 4
              standard-indent 4
              indent-tabs-mode nil)

(defun lisp-indentation ()
  (setq-local tab-width 2
              standard-indent 2))

(add-hook 'emacs-lisp-mode-hook #'lisp-indentation)
(add-hook 'clojure-mode-hook    #'lisp-indentation)
(add-hook 'scheme-mode-hook     #'lisp-indentation)
(add-hook 'lisp-mode-hook       #'lisp-indentation)

(after! haskell-mode
  (setq haskell-indentation-layout-offset 4
        haskell-indentation-starter-offset 4
        haskell-indentation-left-offset 4
        haskell-indentation-where-pre-offset 4
        haskell-indentation-where-post-offset 4))

(use-package outline-indent
  :commands outline-indent-minor-mode
  :custom
  (outline-indent-ellipsis " ▼"))

(after! with-editor
  (setq with-editor-emacsclient-executable "emacsclient")
  (setq with-editor-launcher 'with-editor-create-frame))

(use-package ghostel
  :ensure t)

(use-package! evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

(defun +shaolin/ghostel-at-project-root ()
  "Launch Ghostel at the project root."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (ghostel)))

(defun +shaolin/ghostel-popup ()
  "Launch ghostel in a popup window."
  (interactive)
  (+shaolin/ghostel-at-project-root)
  (+popup/buffer))

(defun +shaolin/ghostel-frame ()
  "Launch a new Ghostel terminal in a dedicated GUI frame."
  (interactive)
  (select-frame (make-frame))
  (ghostel))

(defun +shaolin/ghostel-new-frame ()
  "Launch a brand new isolated Ghostel terminal in a dedicated GUI frame."
  (interactive)
  (select-frame (make-frame))
  (ghostel '(4)))

(defun +shaolin/ghostel-new ()
  "Launch a brand new isolated Ghostel terminal instance."
  (interactive)
  (ghostel '(4)))

(defun +shaolin/ghostel-new-at-project-root ()
  "Lanuch a isolated Ghostel terminal at project root"
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (ghostel '(4))))

(map! :leader
      (:prefix ("o t" . "terminal")
       :desc "At project root"              "t" #'+shaolin/ghostel-at-project-root
       :desc "Popup buffer"                 "p" #'+shaolin/ghostel-popup
       :desc "Open new Frame"               "f" #'+shaolin/ghostel-frame
       :desc "Open new Frame Isolated"      "F" #'+shaolin/ghostel-new-frame
       :desc "New isolated"                 "n" #'+shaolin/ghostel-new
       :desc "New isolated at project root" "N" #'+shaolin/ghostel-new-at-project-root))

(setq explicit-shell-file-name "/home/shiloh/.nix-profile/bin/zsh")
(setq shell-file-name "/home/shiloh/.nix-profile/bin/zsh")

(add-hook 'ghostel-mode-hook
          (lambda ()
            (setq-local scroll-conservatively 101)
            (let ((my-bg (face-background 'default)))
              (face-remap-add-relative 'default :background my-bg)
              (face-remap-add-relative 'fringe :background my-bg)
              (face-remap-add-relative 'left-margin :background my-bg)
              (face-remap-add-relative 'right-margin :background my-bg)
              (face-remap-add-relative 'term-default-bg-color :background my-bg))))

(define-derived-mode daml-mode haskell-mode "Daml"
  "Major mode for editing Daml smart contracts."

  (font-lock-add-keywords
   nil
   `((,(concat "\\_<" (regexp-opt '("choice" "template" "interface" "nonconsuming"
                                    "postconsuming" "preconsuming" "with") t) "\\_>")
      . font-lock-keyword-face)
     (,(concat "\\_<" (regexp-opt '("controller" "create" "exercise" "signatory"
                                    "observer" "maintainer" "ensure" "key") t) "\\_>")
      . font-lock-builtin-face))))

(add-to-list 'auto-mode-alist '("\\.daml\\'" . daml-mode))

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(daml-mode . "daml"))
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection '("dpm" "damlc" "ide"))
                    :major-modes '(daml-mode)
                    :server-id 'dpm-damlc)))

(defun shaolin/daml-lsp-hook ()
  "Inject local paths and run the server immediately."
  (add-to-list 'exec-path (expand-file-name "~/.daml/bin"))
  (setenv "PATH" (concat (expand-file-name "~/.daml/bin:") (getenv "PATH")))
  
  ;; Doom-specific LSP capability bypasses
  (setq-local lsp-enable-symbol-highlighting nil)
  
  (lsp))

(add-hook 'daml-mode-hook #'shaolin/daml-lsp-hook)

(add-to-list 'auto-mode-alist '("\\.sc\\'" . scala-mode))

(after! typescript-mode
  ;; Set intentation level globally for standard typescript-mode
  (setq typescript-indent-level 2))

(after! rjsx-mode
  ;; If Doom falls back to rjsx-mode/web-mode for JSX/TSX components
  (setq js2-basic-offset 2))

;; Automatically locate local node_modules bins for mono-repos
(use-package! add-node-modules-path
  :hook ((typescript-mode tsx-ts-mode typescript-ts-mode rjsx-mode) . add-node-modules-path))

(set-email-account! "gmail"
  '((mu4e-sent-folder   . "/[Gmail]/Sent Mail")
    (mu4e-drafts-folder . "/[Gmail]/Drafts")
    (mu4e-trash-folder  . "/[Gmail]/Bin")
    (mu4e-refile-folder . "/[Gmail]/All Mail")
    (smtpmail-smtp-user . "shiloh.alleyne@obsidian.systems"))
  t)

(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587
      smtpmail-stream-type 'starttls)

(after! doom-modeline
  (setq doom-modeline-mu4e t))

(after! mu4e
  (setq mu4e-use-fancy-chars t
        mu4e-headers-has-child-prefix '("+" . "❯ ")
        mu4e-headers-empty-parent-prefix '("-" . "  ")
        mu4e-headers-first-child-prefix '("\\" . "↳ ")
        mu4e-headers-duplicate-prefix '("=" . "≡ ")))

;; (after! server
;;   (unless (server-running-p)
;;     (server-start)))

(setq default-directory "/home/shiloh/")

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "firefox")
