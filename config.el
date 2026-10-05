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

(defvar shaolin/present-body-width 0.75
  "Olivetti body width while presenting, as a fraction of the window.")

(defvar shaolin/present-line-spacing 0.5
  "Line spacing while presenting.")

(defvar shaolin/present-top-position 0.08
  "Padding above content slides, as a fraction of the window height.
Title-only slides are always centred vertically.")

(defvar shaolin/present-face-remaps
  '((default              :height 1.4)
    (org-document-title   :height 1.6  :weight light)
    (org-level-1          :height 1.5  :weight light)
    (org-level-2          :height 1.15 :weight regular)
    (org-level-3          :height 1.05 :weight regular)
    (org-block            :height 1.4)
    (org-block-begin-line :height 1.0)
    (org-block-end-line   :height 1.0)
    (org-table            :height 1.4)
    (org-table-header     org-table)   ; match the body rows exactly
    (org-formula          :height 1.4))
  "Face remaps (FACE . SPECS) applied to the presentation buffer.
SPECS may be attributes or a face name to merge on top.")

(defvar-local shaolin/present--state nil
  "Plist of buffer state to restore when the presentation ends.")
(defvar-local shaolin/present--slide 0
  "Index of the current slide (0 is the title slide).")
(defvar-local shaolin/present--pad nil
  "Overlay holding the top padding of the current slide.")
(defvar-local shaolin/present--block-overlays nil
  "Overlays adjusting blocks and tables on the current slide.")

(defun shaolin/present--count-headings (&optional limit)
  "Count top-level headings in the widened buffer, stopping at LIMIT."
  (save-restriction
    (widen)
    (save-excursion
      (goto-char (point-min))
      (let ((n 0))
        (while (re-search-forward "^\\* " limit t)
          (setq n (1+ n)))
        n))))

(defun shaolin/present--header-line ()
  "Nano-style slide bar: title on the left, counter on the right."
  (let* ((title   (plist-get shaolin/present--state :title))
         (total   (plist-get shaolin/present--state :total))
         (counter (if (> shaolin/present--slide 0)
                      (format "%d / %d" shaolin/present--slide total)
                    "")))
    (concat (propertize " " 'display '(space :align-to left))
            (propertize title 'face 'shadow)
            (propertize " " 'display `(space :align-to (- right ,(string-width counter))))
            (propertize counter 'face 'shadow))))

(defun shaolin/present--unhide-block-lines ()
  "Undo org-present's hiding of #+begin_/#+end_ lines on this slide."
  (dolist (ov (overlays-in (point-min) (point-max)))
    (when (and (eq (overlay-get ov 'invisible) 'org-present)
               (save-excursion
                 (goto-char (overlay-start ov))
                 (let ((case-fold-search t))
                   (looking-at-p "[ \t]*#\\+\\(?:begin\\|end\\)_"))))
      (delete-overlay ov))))

(defun shaolin/present--tighten-blocks ()
  "Use normal line spacing inside src and example blocks on this slide."
  (mapc #'delete-overlay shaolin/present--block-overlays)
  (setq shaolin/present--block-overlays nil)
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search t))
      (while (re-search-forward "^[ \t]*#\\+begin_\\(src\\|example\\)\\b" nil t)
        (let ((beg (line-beginning-position)))
          (when (re-search-forward (format "^[ \t]*#\\+end_%s\\b" (match-string 1)) nil t)
            (let ((ov (make-overlay beg (min (point-max) (1+ (line-end-position))))))
              (overlay-put ov 'line-spacing 0)
              (push ov shaolin/present--block-overlays))))))))

(defun shaolin/present--show-table-markup ()
  "Keep emphasis markers visible inside tables so columns stay aligned."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^[ \t]*|" nil t)
      (let ((beg (line-beginning-position)))
        (forward-line 1)
        (while (looking-at-p "[ \t]*|") (forward-line 1))
        (let ((ov (make-overlay beg (point))))
          ;; A nil value would be ignored and org's hidden markers would win.
          ;; A symbol that isn't in `buffer-invisibility-spec' takes priority
          ;; over org's text property but still counts as visible.
          (overlay-put ov 'invisible 'shaolin-present-visible)
          (push ov shaolin/present--block-overlays))))))

(defun shaolin/present--has-latex-p ()
  "Non-nil if the current slide appears to contain a LaTeX fragment."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "\\$\\|\\\\(\\|\\\\\\[\\|\\\\begin{" nil t)))

(defun shaolin/present--render-latex ()
  "Render every LaTeX fragment on the current slide, scaled for presenting."
  (when (shaolin/present--has-latex-p)
    (let* ((scale (or (plist-get (alist-get 'default shaolin/present-face-remaps) :height) 1.0))
           (org-format-latex-options
            (plist-put (copy-sequence org-format-latex-options)
                       :scale (* scale (or (plist-get org-format-latex-options :scale) 1.0)))))
      (with-demoted-errors "Org present: LaTeX preview failed: %S"
        ;; The buffer is narrowed to the slide, so this only renders the slide
        (org-latex-preview '(16))))))

(defun shaolin/present--has-body-p ()
  "Non-nil if the current slide has content beyond its heading or keywords."
  (save-excursion
    (goto-char (point-min))
    (when (org-at-heading-p) (forward-line 1))
    (catch 'found
      (while (not (eobp))
        (unless (looking-at-p "^[ \t]*\\(?:#\\+[[:alnum:]_]+:.*\\)?$")
          (throw 'found t))
        (forward-line 1))
      nil)))

(defun shaolin/present--pin-top (buffer)
  "Show BUFFER from the top of the current slide in every window displaying it."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (dolist (win (get-buffer-window-list buffer nil t))
        (set-window-point   win (point-min))
        (set-window-start   win (point-min))
        (set-window-vscroll win 0 t)))))

(defun shaolin/org-present-prepare-slide (_buffer-name _heading)
  "Fold the slide, fix its blocks and tables, render its LaTeX, and position it."
  (org-overview)
  (org-show-entry)
  (org-show-children)

  (shaolin/present--unhide-block-lines)
  (shaolin/present--tighten-blocks)      ; clears the overlay list, so first
  (shaolin/present--show-table-markup)
  (shaolin/present--render-latex)

  (setq shaolin/present--slide
        (shaolin/present--count-headings (+ (point-min) 2)))

  (when shaolin/present--pad (delete-overlay shaolin/present--pad))
  (let* ((win    (get-buffer-window (current-buffer)))
         (height (if win (window-body-height win t) 800))
         (px     (if (shaolin/present--has-body-p)
                     ;; Content slide: small margin above the heading
                     (round (* height shaolin/present-top-position))
                   ;; Title-only slide: centre the visible content vertically
                   (let ((content (if win
                                      (cdr (window-text-pixel-size win (point-min) (point-max)))
                                    0)))
                     (max 0 (/ (- height content) 2))))))
    (setq shaolin/present--pad (make-overlay (point-min) (point-min)))
    ;; One blank line exactly PX pixels tall, ignoring font size and line spacing
    (overlay-put shaolin/present--pad 'before-string
                 (concat (propertize " " 'display `(space :width 0 :height (,px)))
                         (propertize "\n" 'line-spacing 0))))

  ;; Pin the slide to the top of the window, now and again once org-present
  ;; has finished navigating, so the heading never moves with the content.
  (goto-char (point-min))
  (shaolin/present--pin-top (current-buffer))
  (run-at-time 0 nil #'shaolin/present--pin-top (current-buffer))
  (force-mode-line-update))

(defun shaolin/org-present-start ()
  "Set up the current buffer for presenting."
  (setq shaolin/present--state
        (list :title        (or (cadar (org-collect-keywords '("TITLE")))
                                (file-name-base (or (buffer-file-name) (buffer-name))))
              :total        (shaolin/present--count-headings)
              :cookies      (cons (face-remap-add-relative
                                   'header-line
                                   :background (face-background 'default)
                                   :box nil :underline nil :overline nil)
                                  (mapcar (lambda (spec) (apply #'face-remap-add-relative spec))
                                          shaolin/present-face-remaps))
              :header-local (local-variable-p 'header-line-format)
              :header       header-line-format
              :spacing      line-spacing
              :images       (and (bound-and-true-p org-inline-image-overlays) t)
              :flyspell     (bound-and-true-p flyspell-mode)
              :fragtog      (bound-and-true-p org-fragtog-mode)
              :olivetti     (and (bound-and-true-p olivetti-mode) olivetti-body-width)))

  (setq-local header-line-format '((:eval (shaolin/present--header-line))))
  (setq-local line-spacing shaolin/present-line-spacing)

  ;; Hide *bold*, /italic/, =code= markers in this buffer only
  (setq-local org-hide-emphasis-markers t)
  (font-lock-flush)

  ;; No cursor, including evil's per-state cursor
  (setq-local cursor-type nil)
  (when (featurep 'evil)
    (setq-local evil-normal-state-cursor (list nil))
    (evil-refresh-cursor))

  ;; Keep LaTeX previews rendered even if point lands on a fragment
  (when (bound-and-true-p org-fragtog-mode) (org-fragtog-mode -1))

  (org-display-inline-images)
  (when (bound-and-true-p flyspell-mode) (flyspell-mode -1))
  (when (bound-and-true-p olivetti-mode)
    (olivetti-set-width shaolin/present-body-width))

  (org-present-read-only)
  (when (featurep 'evil) (evil-normalize-keymaps)))

(defun shaolin/org-present-end ()
  "Restore the buffer to how it was before presenting."
  (let ((s shaolin/present--state))
    (mapc #'face-remap-remove-relative (plist-get s :cookies))

    (if (plist-get s :header-local)
        (setq-local header-line-format (plist-get s :header))
      (kill-local-variable 'header-line-format))
    (setq-local line-spacing (plist-get s :spacing))

    (kill-local-variable 'org-hide-emphasis-markers)
    (font-lock-flush)

    (kill-local-variable 'cursor-type)
    (when (featurep 'evil)
      (kill-local-variable 'evil-normal-state-cursor)
      (evil-refresh-cursor))

    (when shaolin/present--pad
      (delete-overlay shaolin/present--pad)
      (setq shaolin/present--pad nil))

    (mapc #'delete-overlay shaolin/present--block-overlays)
    (setq shaolin/present--block-overlays nil)

    ;; Drop the presentation-sized previews, then hand LaTeX back to fragtog
    (save-restriction
      (widen)
      (org-clear-latex-preview (point-min) (point-max)))
    (when (plist-get s :fragtog) (org-fragtog-mode 1))

    (unless (plist-get s :images) (org-remove-inline-images))
    (when (plist-get s :flyspell) (flyspell-mode 1))
    (when-let ((width (plist-get s :olivetti)))
      (olivetti-set-width width))

    (org-present-read-write)
    (setq shaolin/present--state nil
          shaolin/present--slide 0)))

(use-package! org-present
  :commands org-present
  :config
  (add-hook 'org-present-mode-hook                #'shaolin/org-present-start)
  (add-hook 'org-present-mode-quit-hook           #'shaolin/org-present-end)
  (add-hook 'org-present-after-navigate-functions #'shaolin/org-present-prepare-slide)

  (map! :map org-present-mode-keymap
        :n "l"       #'org-present-next
        :n "h"       #'org-present-prev
        :n "<right>" #'org-present-next
        :n "<left>"  #'org-present-prev
        :n "g g"     #'org-present-beginning
        :n "G"       #'org-present-end
        :n "q"       #'org-present-quit))

(map! :leader
      :desc "Org presentation" "t P" #'org-present)

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

(defgroup daml nil
  "Daml smart contract language."
  :group 'languages)

(defcustom daml-lsp-command nil
  "Command used to launch the Daml language server.
When nil, use `dpm damlc multi-ide' if the project root contains
multi-package.yaml, and `dpm damlc ide' otherwise."
  :type '(choice (const :tag "Choose from project root" nil)
                 (repeat string))
  :group 'daml)

(defcustom daml-root-markers '("multi-package.yaml" "daml.yaml")
  "Files that mark a directory as a candidate Daml project root."
  :type '(repeat string)
  :group 'daml)

(defcustom daml-root-prompt 'ambiguous
  "When to ask for the project root of a Daml file not yet in a workspace.
`ambiguous' asks only when several candidate roots exist, `always' asks
every time, and `never' uses the nearest candidate."
  :type '(choice (const ambiguous) (const always) (const never))
  :group 'daml)

(defcustom daml-results-default-view 'transaction
  "Initial view for Daml Script results."
  :type '(choice (const table) (const transaction) (const both) (const html))
  :group 'daml)

(dolist (dir '("~/.dpm/bin" "~/.daml/bin"))
  (let ((dir (expand-file-name dir)))
    (when (and (file-directory-p dir)
               (not (member dir exec-path)))
      (add-to-list 'exec-path dir)
      (setenv "PATH" (concat dir path-separator (getenv "PATH"))))))

(defconst daml-font-lock-keywords
  `((,(regexp-opt '("template" "interface" "choice" "with"
                    "nonconsuming" "preconsuming" "postconsuming"
                    "implements" "requires" "viewtype")
                  'symbols)
     . font-lock-keyword-face)
    (,(regexp-opt '("controller" "signatory" "observer" "maintainer"
                    "ensure" "key" "create" "exercise" "exerciseByKey"
                    "fetch" "fetchByKey" "lookupByKey" "archive" "this" "self")
                  'symbols)
     . font-lock-builtin-face))
  "Extra Daml keywords layered on top of Haskell highlighting.")

(define-derived-mode daml-mode haskell-mode "Daml"
  "Major mode for editing Daml smart contracts."
  (font-lock-add-keywords nil daml-font-lock-keywords)
  ;; 2-space indentation, spaces only
  (setq-local indent-tabs-mode nil
              tab-width 2
              evil-shift-width 2
              haskell-indentation-layout-offset 2
              haskell-indentation-left-offset 2
              haskell-indentation-starter-offset 2
              haskell-indentation-where-pre-offset 2
              haskell-indentation-where-post-offset 2))

;; Doom's indentation guessing (dtrt-indent) varies between versions, so
;; only touch its exclusion list if this Doom actually defines it.
(when (boundp 'doom-detect-indentation-excluded-modes)
  (add-to-list 'doom-detect-indentation-excluded-modes 'daml-mode))

(add-to-list 'auto-mode-alist '("\\.daml\\'" . daml-mode))

(after! projectile
  (add-to-list 'projectile-project-root-files-bottom-up "daml.yaml"))

(defun daml--root-candidates (file)
  "Return ancestor directories of FILE containing a root marker, nearest first."
  (let ((dir (file-name-directory (expand-file-name file)))
        found)
    (while dir
      (when (seq-some (lambda (m) (file-exists-p (expand-file-name m dir)))
                      daml-root-markers)
        (push (directory-file-name dir) found))
      (let ((parent (file-name-directory (directory-file-name dir))))
        (setq dir (unless (equal parent dir) parent))))
    (nreverse found)))

(defun daml--root-label (dir)
  (format "%s  (%s)"
          (abbreviate-file-name dir)
          (or (seq-find (lambda (m) (file-exists-p (expand-file-name m dir)))
                        daml-root-markers)
              "manual")))

(defun daml--read-root (candidates)
  "Ask the user to choose among CANDIDATES or any other directory."
  (let* ((other "Other directory…")
         (table (mapcar (lambda (d) (cons (daml--root-label d) d)) candidates))
         (choice (completing-read "Daml project root: "
                                  (append (mapcar #'car table) (list other))
                                  nil t nil nil (caar table))))
    (if (equal choice other)
        (directory-file-name
         (expand-file-name (read-directory-name "Daml project root: ")))
      (cdr (assoc choice table)))))

(defun daml--current-root ()
  "Session folder that currently owns this buffer's file, if any."
  (and buffer-file-name
       (lsp-find-session-folder (lsp-session) buffer-file-name)))

(defun daml--ensure-root ()
  "Register a project root for this file, prompting if configured to."
  (when (and buffer-file-name (not (daml--current-root)))
    (let* ((cands (daml--root-candidates buffer-file-name))
           (root (pcase daml-root-prompt
                   ('never (car cands))
                   ('always (daml--read-root cands))
                   (_ (if (cdr cands) (daml--read-root cands) (car cands))))))
      ;; With no candidates at all, fall through to lsp-mode's own prompt.
      (when root
        (lsp-workspace-folders-add root)))))

(defun daml-switch-project-root ()
  "Choose a different project root for this file and restart the server."
  (interactive)
  (require 'lsp-mode)
  (let* ((file (or buffer-file-name (user-error "Buffer is not visiting a file")))
         (root (daml--read-root (daml--root-candidates file))))
    (dolist (ws (lsp-workspaces))
      (lsp-workspace-shutdown ws))
    ;; Drop every session folder that currently claims this file, so the
    ;; new root wins even if it is shallower than the old one.
    (dolist (folder (lsp-session-folders (lsp-session)))
      (when (file-in-directory-p file folder)
        (lsp-workspace-folders-remove folder)))
    (lsp-workspace-folders-add root)
    (lsp)
    (message "Daml project root: %s" (abbreviate-file-name root))))

(defun daml--lsp-command ()
  "Server command for the current buffer's project root."
  (or daml-lsp-command
      (let ((root (or (daml--current-root) default-directory)))
        (list "dpm" "damlc"
              (if (file-exists-p (expand-file-name "multi-package.yaml" root))
                  "multi-ide"
                "ide")))))

(require 'dom)
(require 'shr)
(require 'url-util)

(defvar daml--result-buffers (make-hash-table :test #'equal)
  "Map of virtual resource URI to its results buffer.")

(defvar-local daml-results--uri nil)
(defvar-local daml-results--html nil)
(defvar-local daml-results--workspace nil)
(defvar-local daml-results-view nil)
(defvar-local daml-results-show-archived nil)
(defvar-local daml-results--progress nil)

(defun daml-results--decl-name (uri)
  "Extract the script name from a virtual resource URI."
  (if (string-match "top-level-decl=\\([^&]+\\)" uri)
      (url-unhex-string (match-string 1 uri))
    uri))

(defun daml-results--class-re (class)
  (concat "\\(?:\\`\\| \\)" (regexp-quote class) "\\(?: \\|\\'\\)"))

(defun daml-results--filter (dom)
  "Strip the VS Code UI chrome and archived rows from the table part of DOM."
  (let ((drop (append
               (mapcan (lambda (tag) (dom-by-tag dom tag)) '(script style))
               ;; The toolbar div holding VS Code's buttons and checkboxes.
               (mapcar (lambda (b) (dom-parent dom b)) (dom-by-tag dom 'button))
               (unless daml-results-show-archived
                 (seq-filter (lambda (n) (eq (dom-tag n) 'tr))
                             (dom-by-class dom (daml-results--class-re "archived")))))))
    (dolist (node drop)
      (dom-remove-node dom node)))
  dom)

(defun daml-results--transaction-node (dom)
  "The <div class=\"da-code transaction\"> holding the transaction view."
  (seq-find (lambda (n) (eq (dom-tag n) 'div))
            (dom-by-class dom (daml-results--class-re "da-code"))))

(require 'tree-widget)
(require 'json)

(defvar-local daml-results--open-state nil
  "Hash of tree node key -> open state, kept across re-renders.")
(defvar-local daml-results--anchors nil
  "Hash of node anchor id -> list of ancestor keys, for jumping to it.")
(defvar-local daml-results--nodes nil
  "Hash of node key -> parsed node, for nodes with children.")
(defvar-local daml-results--parents nil
  "Hash of node key -> parent key.")
(defvar-local daml-results--tree-cache nil
  "(HTML . TREE) for the results currently shown.")

(defconst daml-results--class-faces
  '(("da-hl-keyword"     . font-lock-keyword-face)
    ("da-hl-type"        . font-lock-type-face)
    ("da-hl-constructor" . font-lock-constant-face)
    ("da-hl-predicate"   . font-lock-preprocessor-face)
    ("da-hl-operator"    . font-lock-builtin-face)
    ("da-hl-error"       . error)
    ("da-hl-warning"     . warning)
    ("da-hl-hint"        . font-lock-doc-face)
    ("da-hl-info"        . font-lock-doc-face))
  "Faces for the server's syntax-highlighting classes.")

(defvar daml-results-link-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'daml-results-follow-link)
    (define-key map [mouse-1] #'daml-results-follow-link)
    (define-key map [mouse-2] #'daml-results-follow-link)
    map)
  "Keymap active on links inside the transaction tree.")

(defun daml-results--protect-spaces (html)
  "Turn spaces in HTML text into &nbsp;.
libxml drops whitespace-only text nodes, and those carry the
indentation that encodes the transaction tree's nesting."
  (replace-regexp-in-string
   ">\\([^<]+\\)<"
   (lambda (m)
     (concat ">" (replace-regexp-in-string " " "&nbsp;" (substring m 1 -1) t t) "<"))
   html t t))

(defun daml-results--flatten (node)
  "Turn DOM NODE into a propertized string; <br> becomes a newline."
  (cond
   ((stringp node) (subst-char-in-string ?\u00a0 ?\s node))
   ((eq (dom-tag node) 'br) "\n")
   (t
    (let* ((s (apply #'concat (mapcar #'daml-results--flatten (dom-children node))))
           (len (length s))
           (face (alist-get (dom-attr node 'class) daml-results--class-faces
                            nil nil #'equal))
           (id (dom-attr node 'id))
           (onclick (dom-attr node 'onclick))
           (link (cond
                  ((and (eq (dom-tag node) 'a) (dom-attr node 'href))
                   (list 'source (dom-attr node 'href)))
                  ((and onclick (string-match "hash='\\([^']+\\)'" onclick))
                   (list 'node (match-string 1 onclick))))))
      (when (> len 0)
        (when face (add-face-text-property 0 len face t s))
        (when id (put-text-property 0 len 'daml-anchor id s))
        (when link
          (add-face-text-property 0 len 'link t s)
          (add-text-properties
           0 len
           (list 'daml-link link 'keymap daml-results-link-map
                 'mouse-face 'highlight
                 'help-echo (if (eq (car link) 'source)
                                "RET: jump to source"
                              "RET: jump to node"))
           s)))
      s))))

(defun daml-results--rank (text)
  "How strongly a line claims same-indent lines below it."
  (cond ((string-match-p "\\`\\(?:TX\\|pass\\) " text) 3)
        ((string-match-p "\\`children:" text) 2)
        ((string-match-p "\\`#[0-9]+:[0-9]+" text) 1)
        (t 0)))

(defun daml-results--entries (string)
  "Split STRING into (INDENT RANK TEXT) entries, dropping tree glyphs."
  (let (entries)
    (dolist (line (split-string string "\n"))
      (let ((indent (if (string-match "\\`[ │├└─>]*" line) (match-end 0) 0)))
        (when (< indent (length line))
          (let ((text (string-trim-right (substring line indent))))
            (push (list indent (daml-results--rank text) text) entries)))))
    (nreverse entries)))

(defun daml-results--owns-p (parent child)
  (let ((i (nth 0 parent)) (j (nth 0 child)))
    (or (> j i)
        (and (= j i) (< (nth 1 child) (nth 1 parent))))))

(defun daml-results--parse (entries)
  "Nest ENTRIES into a list of (ENTRY . CHILDREN) nodes."
  (let (result)
    (while entries
      (let ((entry (pop entries)) kids)
        (while (and entries (daml-results--owns-p entry (car entries)))
          (push (pop entries) kids))
        (push (cons entry (daml-results--parse (nreverse kids))) result)))
    (nreverse result)))

;;; Lists and records as trees

(defun daml-results--scan (text fn)
  "Walk TEXT, calling FN with (INDEX CHAR DEPTH) for chars outside quotes.
DEPTH counts open brackets, parens and braces before INDEX.  Returns the
final depth."
  (let ((depth 0) (quote nil) (i 0) (len (length text)))
    (while (< i len)
      (let ((c (aref text i)))
        (cond
         (quote (when (eq c quote) (setq quote nil)))
         ((memq c '(?\" ?')) (setq quote c))
         ((memq c '(?\[ ?\( ?\{)) (setq depth (1+ depth)))
         ((memq c '(?\] ?\) ?\})) (setq depth (1- depth))
          (when fn (funcall fn i c depth)))
         (fn (funcall fn i c depth))))
      (setq i (1+ i)))
    depth))

(defun daml-results--split-top (text sep)
  "Split TEXT at SEP characters that sit outside any brackets or quotes."
  (let ((start 0) parts)
    (daml-results--scan text (lambda (i c depth)
                               (when (and (eq c sep) (= depth 0))
                                 (push (string-trim (substring text start i)) parts)
                                 (setq start (1+ i)))))
    (push (string-trim (substring text start)) parts)
    (seq-remove #'string-empty-p (nreverse parts))))

(defun daml-results--bracket-body (text)
  "If TEXT is a single bracketed list \"[...]\", return what is inside."
  (when (and (string-prefix-p "[" text) (string-suffix-p "]" text))
    (let ((closes-early nil) (last (1- (length text))))
      (daml-results--scan text (lambda (i c depth)
                                 (when (and (eq c ?\]) (= depth 0) (< i last))
                                   (setq closes-early t))))
      (unless closes-early
        (substring text 1 last)))))

(defun daml-results--continues-p (text)
  "Non-nil if TEXT was wrapped by the server and goes on in the next line."
  (or (> (daml-results--scan text nil) 0)
      (string-suffix-p " =" text)
      (string-suffix-p "," text)))

(defun daml-results--join-continuations (entries)
  "Glue wrapped lines back onto the line they belong to."
  (let (out)
    (while entries
      (let ((entry (pop entries)))
        (while (and entries
                    (daml-results--continues-p (nth 2 entry))
                    (> (nth 0 (car entries)) (nth 0 entry)))
          (setq entry (list (nth 0 entry) (nth 1 entry)
                            (concat (nth 2 entry) " " (nth 2 (pop entries))))))
        (push entry out)))
    (nreverse out)))

(defun daml-results--mk (text &optional kids key)
  "A synthesized tree node showing TEXT, with KIDS and a stable KEY."
  (cons (list 0 0 text key) kids))

(defun daml-results--count-label (n)
  (propertize (format "[%d item%s]" n (if (= n 1) "" "s")) 'face 'shadow))

(defun daml-results--value-node (prefix value kids &optional key)
  "Node for VALUE shown after PREFIX.
Lists get one child per element; records get one child per field."
  (let ((body (daml-results--bracket-body value)))
    (cond
     (body
      (let ((elems (daml-results--split-top body ?,)))
        (if (null elems)
            (daml-results--mk (concat prefix value) nil key)
          (daml-results--mk
           (concat prefix (daml-results--count-label (length elems)))
           (seq-map-indexed (lambda (elem i)
                              (daml-results--value-node "" elem nil (number-to-string i)))
                            elems)
           key))))
     ((string-match "\\`\\([^][(){} ]+\\) with\\(?: \\(.*\\)\\)?\\'" value)
      (let ((type (substring value 0 (match-end 1)))
            (rest (match-string 2 value)))
        (daml-results--mk (concat prefix type)
                          (append (and rest (daml-results--split-fields rest))
                                  (daml-results--fields kids))
                          key)))
     (t
      (daml-results--mk (concat prefix value)
                        (mapcar #'daml-results--restructure kids)
                        key)))))

(defun daml-results--field (text kids)
  "Node for one record field \"name = value\"."
  (if (string-match "\\`\\([^ =]+\\) = \\(.*\\)\\'" text)
      (daml-results--value-node (substring text 0 (match-beginning 2))
                                (match-string 2 text)
                                kids
                                (substring-no-properties (match-string 1 text)))
    (daml-results--mk text (mapcar #'daml-results--restructure kids))))

(defun daml-results--split-fields (text)
  (mapcar (lambda (part) (daml-results--field part nil))
          (daml-results--split-top text ?\;)))

(defun daml-results--fields (nodes)
  "Field nodes from indented lines, each holding one or more fields."
  (mapcan (lambda (node)
            (let* ((parts (daml-results--split-top (nth 2 (car node)) ?\;))
                   (last (car (last parts))))
              (append (mapcar (lambda (p) (daml-results--field p nil)) (butlast parts))
                      (and last (list (daml-results--field last (cdr node)))))))
          nodes))

(defconst daml-results--list-labels-re
  "\\`\\(disclosed to (since):\\|divulged to (since):\\|referenced by\\|Active contracts:\\)\\s-*"
  "Lines whose remainder is a comma-separated list.")

(defun daml-results--restructure (node)
  "Rewrite NODE so every list becomes one child node per element."
  (let* ((entry (car node))
         (text (nth 2 entry))
         (kids (cdr node)))
    (cond
     ((string-match daml-results--list-labels-re text)
      ;; A long list is wrapped onto the lines below the label, which arrive
      ;; here as KIDS, so gather them all before splitting.
      (let* ((label (string-trim-right (substring text 0 (match-end 1))))
             (source (mapconcat #'identity
                                (cons (substring text (match-end 0))
                                      (mapcar (lambda (kid) (nth 2 (car kid))) kids))
                                " "))
             (elems (daml-results--split-top source ?,)))
        (daml-results--mk
         (concat label " " (daml-results--count-label (length elems)))
         (seq-map-indexed (lambda (elem i)
                            (daml-results--mk elem nil (number-to-string i)))
                          elems)
         (substring-no-properties label))))
     ((string-match "\\`Return value:\\s-*" text)
      (let ((prefix (substring text 0 (match-end 0)))
            (rest (substring text (match-end 0))))
        (cond
         ((not (string-empty-p rest))
          (daml-results--value-node prefix rest kids "Return value"))
         ((= (length kids) 1)
          (daml-results--value-node (concat (string-trim-right prefix) " ")
                                    (nth 2 (car (car kids))) (cdr (car kids))
                                    "Return value"))
         (t (cons entry (mapcar #'daml-results--restructure kids))))))
     ((and kids (equal (substring-no-properties text) "with"))
      (cons entry (daml-results--fields kids)))
     (t
      (cons entry (mapcar #'daml-results--restructure kids))))))

(defun daml-results--node-key (text)
  "Stable key for a node, so its open state survives re-renders."
  (let ((plain (substring-no-properties text)))
    (if (string-match "\\`\\(?:\\(?:TX\\|pass\\) [^ ]+\\|#[0-9]+:[0-9]+\\|children:\\)"
                      plain)
        (match-string 0 plain)
      plain)))

(defun daml-results--collect-anchors (text ancestors)
  (let ((pos 0) (len (length text)))
    (while (< pos len)
      (when-let ((id (get-text-property pos 'daml-anchor text)))
        (puthash id ancestors daml-results--anchors))
      (setq pos (next-single-property-change pos 'daml-anchor text len)))))

;;; Parsed-tree cache and index

(defun daml-results--key (parent-key entry)
  "Key of the node for ENTRY under PARENT-KEY."
  (concat parent-key "/" (or (nth 3 entry) (daml-results--node-key (nth 2 entry)))))

(defun daml-results--walk (nodes fn &optional parent-key ancestors)
  "Call FN with (NODE KEY ANCESTORS) for NODES and all their descendants."
  (dolist (node nodes)
    (let ((key (daml-results--key (or parent-key "") (car node))))
      (funcall fn node key ancestors)
      (daml-results--walk (cdr node) fn key (cons key ancestors)))))

(defun daml-results--parse-html (html)
  (with-temp-buffer
    (insert (daml-results--protect-spaces html))
    (libxml-parse-html-region (point-min) (point-max))))

(defun daml-results--build-tree (html)
  (when-let ((tx (daml-results--transaction-node (daml-results--parse-html html))))
    (mapcar #'daml-results--restructure
            (daml-results--parse
             (daml-results--join-continuations
              (daml-results--entries (daml-results--flatten tx)))))))

(defun daml-results--tree ()
  "The parsed transaction tree, rebuilt only when new results arrive."
  (unless (eq (car daml-results--tree-cache) daml-results--html)
    (let ((tree (daml-results--build-tree daml-results--html)))
      (setq daml-results--tree-cache (cons daml-results--html tree)
            daml-results--anchors (make-hash-table :test #'equal)
            daml-results--nodes (make-hash-table :test #'equal)
            daml-results--parents (make-hash-table :test #'equal))
      (daml-results--walk
       tree
       (lambda (node key ancestors)
         (daml-results--collect-anchors (nth 2 (car node)) ancestors)
         (when (cdr node)
           (puthash key node daml-results--nodes)
           (puthash key (car ancestors) daml-results--parents))))))
  (cdr daml-results--tree-cache))

;;; Drawing
;;
;; The tree looks like `tree-widget' (and uses its icon images in GUI
;; frames), but is drawn as plain propertized text.  Real widgets carry
;; several markers per line, which makes large trees crawl; plain text
;; redraws thousands of lines in milliseconds, so folding and jumping
;; simply redraw the buffer.

(defun daml-results--data-node-p (entry)
  "Non-nil for payload-level nodes: record blocks, lists and fields."
  (or (nth 3 entry)
      (string-prefix-p "with" (nth 2 entry))))

(defun daml-results--open-p (key entry)
  (let ((state (gethash key daml-results--open-state 'unset)))
    (if (eq state 'unset)
        (not (string-prefix-p "with" (nth 2 entry)))
      state)))

(defvar daml-results--use-images nil
  "Non-nil while drawing with `tree-widget' images.")

(defun daml-results--piece (text image)
  "TEXT, shown as tree-widget's IMAGE when images are in use."
  (if daml-results--use-images
      (propertize text 'display (tree-widget-find-image image))
    text))

(defvar daml-results-icon-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] #'daml-results-toggle-node)
    (define-key map [mouse-2] #'daml-results-toggle-node)
    map)
  "Keymap on the fold icons.")

(defun daml-results--insert-nodes (nodes parent-key guides depth)
  "Draw NODES under PARENT-KEY, prefixing each line with GUIDES."
  (while nodes
    (let* ((node (pop nodes))
           (last (null nodes))
           (entry (car node))
           (kids (cdr node))
           (key (daml-results--key parent-key entry))
           (open (and kids (daml-results--open-p key entry)))
           (start (point)))
      (insert guides)
      (when (> depth 0)
        (insert (daml-results--piece (if last " `" " |") (if last "end-guide" "guide"))
                (daml-results--piece "-" "handle")))
      (when kids
        (insert (propertize (daml-results--piece (if open "[-]" "[+]") (if open "open" "close"))
                            'keymap daml-results-icon-map
                            'mouse-face 'highlight
                            'help-echo "mouse-1: fold or unfold")))
      (when (and (not kids) (> depth 0) daml-results--use-images)
        (insert (daml-results--piece " " "leaf")))
      (when (or kids (> depth 0))
        (insert " "))
      (insert (nth 2 entry) "\n")
      (when kids
        (put-text-property start (point) 'daml-node-key key))
      (when open
        (daml-results--insert-nodes
         kids key
         (if (= depth 0)
             ""
           (concat guides
                   (daml-results--piece (if last "  " " |") (if last "no-guide" "guide"))
                   (daml-results--piece " " "no-handle")))
         (1+ depth))))))

(defun daml-results--insert-tree (tree)
  "Draw the parsed transaction TREE at point."
  (let ((daml-results--use-images (and (display-images-p) (tree-widget-use-image-p))))
    (daml-results--insert-nodes tree "" "" 0)))

;;; Navigation

(defun daml-results--find-prop (prop value)
  "Buffer position where text property PROP equals VALUE, or nil."
  (let ((pos (point-min)) found)
    (while (and pos (not found) (< pos (point-max)))
      (if (equal (get-text-property pos prop) value)
          (setq found pos)
        (setq pos (next-single-property-change pos prop))))
    found))

(defun daml-results--key-on-line ()
  "Key of the tree node on the current line, if it has children."
  (get-text-property (line-beginning-position) 'daml-node-key))

(defun daml-results--rerender-at (key)
  "Redraw, keeping KEY (or its nearest shown ancestor) on the same screen row."
  (let ((row (and (eq (window-buffer) (current-buffer))
                  (count-lines (window-start) (line-beginning-position)))))
    (daml-results--render)
    (let ((k key) pos)
      (while (and k (not (setq pos (daml-results--find-prop 'daml-node-key k))))
        (setq k (gethash k daml-results--parents)))
      (when pos
        (goto-char pos)
        (when row (recenter row))))))

(defun daml-results-toggle-node (&optional event)
  "Fold or unfold the tree node on this line (or the clicked icon)."
  (interactive (list last-nonmenu-event))
  (when (mouse-event-p event)
    (mouse-set-point event))
  (daml-results--tree)
  (let* ((key (daml-results--key-on-line))
         (node (and key (gethash key daml-results--nodes))))
    (if (not node)
        (message "No foldable node on this line")
      (puthash key (not (daml-results--open-p key (car node))) daml-results--open-state)
      (daml-results--rerender-at key))))

(defun daml-results--goto-anchor (id)
  "Unfold the tree down to node ID and move point to it."
  (daml-results--tree)
  (let ((ancestors (gethash id daml-results--anchors 'missing)))
    (if (eq ancestors 'missing)
        (message "Daml: %s isn't shown in this view" id)
      (let ((closed (seq-remove (lambda (k)
                                  (daml-results--open-p k (car (gethash k daml-results--nodes))))
                                ancestors)))
        (when closed
          (dolist (k closed) (puthash k t daml-results--open-state))
          (daml-results--render)))
      (if-let ((found (daml-results--find-prop 'daml-anchor id)))
          (progn
            (push-mark nil t)
            (goto-char found)
            (when (eq (window-buffer) (current-buffer)) (recenter)))
        (message "Daml: couldn't reveal %s" id)))))

;;; Org-style cycling

(defvar-local daml-results--global-cycle nil)
(defvar-local daml-results--node-cycle nil)

(defun daml-results-cycle-global ()
  "Cycle the whole tree like org's S-TAB: OVERVIEW, CONTENTS, SHOW ALL.
CONTENTS opens transactions and nodes but keeps payloads and lists folded."
  (interactive)
  (if (not (memq daml-results-view '(transaction both)))
      (message "Switch to the transaction view first (v)")
    (let ((next (pcase daml-results--global-cycle
                  ('overview 'contents) ('contents 'all) (_ 'overview)))
          (here (daml-results--key-on-line)))
      (setq daml-results--global-cycle next)
      (daml-results--walk
       (daml-results--tree)
       (lambda (node key _)
         (when (cdr node)
           (puthash key
                    (pcase next
                      ('overview nil)
                      ('contents (not (daml-results--data-node-p (car node))))
                      ('all t))
                    daml-results--open-state))))
      (daml-results--rerender-at here)
      (message "%s" (pcase next
                      ('overview "OVERVIEW") ('contents "CONTENTS") ('all "SHOW ALL"))))))

(defun daml-results-cycle-node ()
  "Cycle the node on this line like org's TAB: FOLDED, CHILDREN, SUBTREE."
  (interactive)
  (daml-results--tree)
  (let* ((key (daml-results--key-on-line))
         (node (and key (gethash key daml-results--nodes))))
    (if (not node)
        (message "Nothing to fold on this line")
      (let ((state (cond
                    ((not (daml-results--open-p key (car node))) 'children)
                    ((and (eq last-command this-command)
                          (equal daml-results--node-cycle (cons key 'children)))
                     'subtree)
                    (t 'folded))))
        (pcase state
          ('folded (puthash key nil daml-results--open-state))
          ('children
           (puthash key t daml-results--open-state)
           (dolist (kid (cdr node))
             (when (cdr kid)
               (puthash (daml-results--key key (car kid)) nil daml-results--open-state))))
          ('subtree
           (daml-results--walk (list node)
                               (lambda (n k _)
                                 (when (cdr n) (puthash k t daml-results--open-state)))
                               (or (gethash key daml-results--parents) ""))))
        (setq daml-results--node-cycle (cons key state))
        (daml-results--rerender-at key)
        (message "%s" (upcase (symbol-name state)))))))

(defun daml-results--visit-source (href)
  "Open the source location encoded in a `daml.revealLocation' HREF."
  (let* ((json (decode-coding-string
                (url-unhex-string
                 (replace-regexp-in-string "\\`command:daml\\.revealLocation\\?" "" href))
                'utf-8))
         (loc (ignore-errors (json-parse-string json :array-type 'list))))
    (pcase loc
      (`(,uri ,line . ,_)
       (pop-to-buffer (find-file-noselect (replace-regexp-in-string "\\`file://" "" uri))
                      '(display-buffer-use-some-window (inhibit-same-window . t)))
       (goto-char (point-min))
       (forward-line line)          ; locations are 0-indexed
       (back-to-indentation)
       (recenter))
      (_ (message "Daml: can't read location %s" href)))))

(defun daml-results-follow-link (&optional event)
  "Follow the link at point, or toggle the node on this line."
  (interactive (list last-nonmenu-event))
  (when (mouse-event-p event)
    (mouse-set-point event))
  (pcase (get-text-property (point) 'daml-link)
    (`(source ,href) (daml-results--visit-source href))
    (`(node ,id) (daml-results--goto-anchor id))
    (_ (daml-results-toggle-node))))

(defun daml-results--render ()
  (let ((inhibit-read-only t)
        (pos (point)))
    (erase-buffer)
    (insert (propertize
             (format "%s   view: %s   archived: %s   [v] view  [a] archived  [TAB/S-TAB] cycle  [RET] follow  [q] close\n\n"
                     (daml-results--decl-name daml-results--uri)
                     daml-results-view
                     (if daml-results-show-archived "shown" "hidden"))
             'face 'font-lock-comment-face))
    (cond
     ((null daml-results--html)
      (insert (if daml-results--progress
                  (format "Running script… (%.1fs)" (/ daml-results--progress 1000.0))
                "Waiting for the Daml server…")))
     ((or (eq daml-results-view 'html) (not (libxml-available-p)))
      (insert daml-results--html))
     (t
      (when (memq daml-results-view '(table both))
        (let* ((dom (daml-results--parse-html daml-results--html))
               (tx (daml-results--transaction-node dom)))
          (when tx (dom-remove-node dom tx))
          (shr-insert-document (daml-results--filter dom))
          (insert "\n")))
      (when (memq daml-results-view '(transaction both))
        (daml-results--insert-tree (daml-results--tree)))))
    (goto-char (min pos (point-max)))))

(defun daml-results-cycle-view ()
  "Cycle between table, transaction, combined and raw HTML views."
  (interactive)
  (setq daml-results-view
        (pcase daml-results-view
          ('table 'transaction) ('transaction 'both) ('both 'html) (_ 'table)))
  (daml-results--render))

(defun daml-results-toggle-archived ()
  "Toggle display of archived contracts."
  (interactive)
  (setq daml-results-show-archived (not daml-results-show-archived))
  (daml-results--render))

(defun daml-results-quit ()
  "Close the results buffer and unsubscribe from the server."
  (interactive)
  (quit-window t))

(defun daml-results--unsubscribe ()
  (when daml-results--uri
    (remhash daml-results--uri daml--result-buffers)
    (when daml-results--workspace
      (ignore-errors
        (with-lsp-workspace daml-results--workspace
          (lsp-notify "textDocument/didClose"
                      (list :textDocument (list :uri daml-results--uri))))))))

(defvar daml-results-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "v" #'daml-results-cycle-view)
    (define-key map "a" #'daml-results-toggle-archived)
    (define-key map "q" #'daml-results-quit)
    (define-key map (kbd "TAB") #'daml-results-cycle-node)
    (define-key map (kbd "<backtab>") #'daml-results-cycle-global)
    (define-key map (kbd "RET") #'daml-results-follow-link)
    map))

(define-derived-mode daml-results-mode special-mode "Daml-Results"
  "Displays Daml Script results streamed from the language server."
  (setq-local truncate-lines t)
  (setq-local daml-results--open-state (make-hash-table :test #'equal))
  (add-hook 'kill-buffer-hook #'daml-results--unsubscribe nil t))

(map! :map daml-results-mode-map
      :n "v" #'daml-results-cycle-view
      :n "a" #'daml-results-toggle-archived
      :n "q" #'daml-results-quit
      :n "TAB" #'daml-results-cycle-node
      :n "<backtab>" #'daml-results-cycle-global
      :n "RET" #'daml-results-follow-link)

(defun daml--show-resource (action)
  "Handle the `daml.showResource' command carried by a CodeLens."
  (let* ((args (lsp-get action :arguments))
         (uri (and args (> (length args) 1) (elt args 1))))
    (unless uri
      (user-error "Daml: CodeLens carried no resource URI"))
    (let ((existing (gethash uri daml--result-buffers)))
      (if (buffer-live-p existing)
          (display-buffer existing)
        (let ((ws (car (lsp-workspaces)))
              (buf (get-buffer-create
                    (format "*daml-results: %s*" (daml-results--decl-name uri)))))
          (with-current-buffer buf
            (daml-results-mode)
            (setq daml-results--uri uri
                  daml-results--workspace ws
                  daml-results-view daml-results-default-view)
            (daml-results--render))
          (puthash uri buf daml--result-buffers)
          (display-buffer buf)
          ;; Subscribing = opening the virtual document.
          (lsp-notify "textDocument/didOpen"
                      (list :textDocument
                            (list :uri uri :languageId "daml" :version 1 :text ""))))))))

(defun daml--on-virtual-resource-change (_workspace params)
  "Render HTML pushed by the server for a subscribed resource."
  (let ((buf (gethash (lsp-get params :uri) daml--result-buffers)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (setq daml-results--html (lsp-get params :contents)
              daml-results--progress nil)
        (daml-results--render)))))

(defun daml--on-virtual-resource-progress (_workspace params)
  "Show how long a script has been running until its first result arrives."
  (let ((buf (gethash (lsp-get params :uri) daml--result-buffers)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (let ((ms (lsp-get params :millisecondsPassed)))
          (setq daml-results--progress (and (numberp ms) ms)))
        (unless daml-results--html
          (daml-results--render))))))

(defun daml-run-script ()
  "Show results for the Daml Script at or above point."
  (interactive)
  (let ((line (1- (line-number-at-pos)))
        (best nil)
        (best-line -1))
    (seq-doseq (lens (lsp-request "textDocument/codeLens"
                                  (list :textDocument (lsp--text-document-identifier))))
      (let ((cmd (lsp-get lens :command))
            (l (lsp-get (lsp-get (lsp-get lens :range) :start) :line)))
        (when (and cmd
                   (equal (lsp-get cmd :command) "daml.showResource")
                   (<= l line) (> l best-line))
          (setq best cmd best-line l))))
    (if best
        (daml--show-resource best)
      (user-error "No Daml script at or above point"))))

(after! lsp-mode
  (add-to-list 'lsp-language-id-configuration '(daml-mode . "daml"))
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.daml\\'")
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection #'daml--lsp-command)
    :major-modes '(daml-mode)
    :priority 1
    :server-id 'daml-ide
    :action-handlers
    (ht ("daml.showResource" #'daml--show-resource))
    :notification-handlers
    (ht ("daml/virtualResource/didChange" #'daml--on-virtual-resource-change)
        ("daml/virtualResource/didProgress" #'daml--on-virtual-resource-progress)
        ("daml/virtualResource/note" #'ignore)
        ("daml/keepAlive" #'ignore)))))

(set-popup-rule! "^\\*daml-results:"
  :side 'right :size 0.45 :select nil :quit 'current :ttl 0)

(defun shaolin/daml-lsp-h ()
  "Configure and start LSP for Daml buffers."
  (setq-local lsp-disabled-clients
              (cons 'lsp-haskell (bound-and-true-p lsp-disabled-clients)))
  (setq-local lsp-enable-symbol-highlighting nil)
  (setq-local lsp-lens-enable t)
  ;; Undo any indentation guess made after the mode set 2 spaces.
  (when (bound-and-true-p dtrt-indent-mode)
    (dtrt-indent-mode -1))
  (require 'lsp-mode)
  (daml--ensure-root)
  (lsp!))

(add-hook 'daml-mode-local-vars-hook #'shaolin/daml-lsp-h)

(map! :map daml-mode-map
      :localleader
      "r" #'daml-run-script
      "l" #'lsp-avy-lens
      "p" #'daml-switch-project-root)

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
