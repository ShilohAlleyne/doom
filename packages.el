;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; --- UI ---
(package! nano-theme
  :recipe (:host github :repo "rougier/nano-theme"))

(package! nano-modeline
  :recipe (:host github :repo "rougier/nano-modeline"))

(package! indent-bars
  :recipe (:host github :repo "jdtsmith/indent-bars"))

(package! doom-nano-modeline
  :recipe (:host github
  :repo "ronisbr/doom-nano-modeline"))

(package! dirvish
  :recipe (:host github :repo "alexluigit/dirvish"))

;; --- Code ---
(package! vundo
  :recipe (:host github :repo "casouri/vundo"))

(package! outline-indent
  :recipe (:host github :repo "jamescherti/outline-indent.el"))

(package! ghostel
  :recipe (:host github :repo "dakra/ghostel"))

(package! evil-ghostel)

;; --- Note Taking ---
(package! denote)
(package! org-modern)
(package! org-modern-indent :recipe (:host github :repo "jdtsmith/org-modern-indent"))
(package! olivetti)
