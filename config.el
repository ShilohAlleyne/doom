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

(setq doom-font                 (font-spec :family "IosevkaTerm Nerd Font Mono" :size 22)
      doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 22)
      doom-serif-font          (font-spec :family "IosevkaTerm Nerd Font Mono" :size 22))

(setq doom-theme 'doom-nano-light)

(use-package! doom-nano-modeline
  :config
  (doom-nano-modeline-mode 1)
  (setq-default mode-line-format nil)
  (add-hook 'after-change-major-mode-hook (lambda () (setq mode-line-format nil))))

(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)

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

(setq fancy-splash-image "~/.config/doom/images/metamorfose-I.jpg"
      +doom-dashboard-banner-padding '(0 . 0)
      +doom-dashboard-banner-footer nil)

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

(after! org
  (setq org-preview-latex-default-process 'dvisvgm)
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.5))
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
  "Launch ghostel at the project root."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (ghostel)))

(defun +shaolin/ghostel-popup ()
  "Launch ghostel in a popup window."
  (interactive)
  (+shaolin/ghostel-at-project-root)
  (+popup/buffer))

(map! :leader
      :desc "Ghostel terminal" "o T" #'+shaolin/ghostel-at-project-root
      :desc "Ghostel popup"    "o t" #'+shaolin/ghostel-popup)

(add-hook 'ghostel-mode-hook
          (lambda ()
            (setq-local scroll-conservatively 101)
            (let ((my-bg (face-background 'default)))
              (face-remap-add-relative 'default :background my-bg)
              (face-remap-add-relative 'fringe :background my-bg)
              (face-remap-add-relative 'left-margin :background my-bg)
              (face-remap-add-relative 'right-margin :background my-bg)
              (face-remap-add-relative 'term-default-bg-color :background my-bg))))

(set-email-account! "gmail"
  '((mu4e-sent-folder   . "/[Gmail]/Sent Mail")
    (mu4e-drafts-folder . "/[Gmail]/Drafts")
    (mu4e-trash-folder  . "/[Gmail]/Bin")
    (mu4e-refile-folder . "/[Gmail]/All Mail")
    (smtpmail-smtp-user . "shiloh.t.alleyne@gmail.com"))
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

(after! server
  (unless (server-running-p)
    (server-start)))

(setq default-directory "/home/shiloh/")

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

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "explorer.exe")
