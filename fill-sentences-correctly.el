;;; fill-sentences-correctly.el --- Correctly fill sentences -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Case Duckworth

;; Author: Case Duckworth <acdw@acdw.net>
;; URL: https://github.com/duckwork/fill-sentences-correctly.el
;; Package-Version: 1.0.1
;; Package-Requires: ((emacs "24.4"))

;;; Commentary:

;; This is the result of the following comment thread on lobste.rs
;; ( https://lobste.rs/s/c9qsmz/#c_1szspx ):

;; -----------------------------------------------------------------------------
;; acdw | I feel like I’m the only person who has sentence-end-double-space set
;; to t — I like it because it allows me to easily navigate sentences, and it
;; doesn’t matter because when I export the document to another format the
;; spaces get properly minimized.

;; snan | Hi acdw!♥ ¶ I felt like setting it to nil (which I didn’t realize
;; until after a few years) unlocked super powers of Emacs I had only dreamt of
;; before, M-a, M-k, transposing sentences etc, even in text I didn’t originally
;; author, and it does a really good job. ¶ Also, with this set to nil, it works
;; with one or two spaces; with it set to t it can’t find sentence boundaries if
;; there’s only one space. I can’t believe that’s the default.

;; acdw | Hi there :) Nice to see you on lobsters! ¶ Oh my god, you’ve actually
;; convinced me to turn sentence-end-double-space to nil … I honestly did not
;; realize that it’s telling Emacs to recognize single-spaced sentences, which
;; honestly makes so much sense. ¶ I think the only place I want to set it is
;; when filling paragraphs, so it fills the “proper” (to my eyes anyway)
;; two-spaced sentences, which of course I can just add some advice to to fix.
;; Thanks for the mind-changer, snan!
;; -----------------------------------------------------------------------------

;; Basically, I was laboring under the impression that
;; `sentence-end-double-space' was telling Emacs the /right/ way to do
;; end-of-sentence spacing, but really it's just letting it know how sentences
;; work.  So setting it to nil lets you do sentence-level stuff, even on people
;; who are /wrong/.  So great.

;; However, there's one issue that arises when `sentence-end-double-space' is
;; set to nil: when filling, my perfectly-spaced sentences will fill and remove
;; the two spaces.  That's simply unacceptable.

;; No, I don't want to just set the NOSQUEEZE option to non-nil for
;; `fill-region', because I /do/ want it to squeeze whitespace that shouldn't be
;; there.  It's just that two spaces after a period /should/ be there.

;; USAGE:

;; Enable `fill-sentences-correctly-mode'.

;;; Code:

(defgroup fill-sentences-correctly nil
  "Customizations to fill sentences correctly."
  :prefix "fill-sentences-correctly-"
  :group 'text)

(defcustom fill-sentences-correctly-functions '(fill-paragraph
                                                fill-region)
  "Which functions to fill sentences correctly around."
  :type '(repeat function))

(defvar fill-sentences-correctly--sentence-end-double-space-orig nil
  "The original value of `sentence-end-double-space'.")

;; `dlet' was apparently only added in Emacs 27.1, so if it's not bound, let's
;; just define it.
(defmacro fill-sentences-correctly--dlet (binders &rest body)
  "Like `let' but using dynamic scoping."
  (declare (indent 1) (debug let))
  ;; (defvar FOO) only affects the current scope, but in order for
  ;; this not to affect code after the main `let' we need to create a new scope,
  ;; which is what the surrounding `let' is for.
  ;; FIXME: (let () ...) currently doesn't actually create a new scope,
  ;; which is why we use (let (_) ...).
  `(let (_)
     ,@(mapcar (lambda (binder)
                 `(defvar ,(if (consp binder) (car binder) binder)))
               binders)
     (let ,binders ,@body)))

(defun fill-sentences-correctly (fn &rest r)
  "AROUND ADVICE to fill sentences correctly.
FN should be one of `fill-region', `fill-paragraph', or other
filling functions. R are their arguments, and are passed through
unaltered."
  (fill-sentences-correctly--dlet ((sentence-end-double-space t))
    (apply fn r)))

;;;###autoload
(define-minor-mode fill-sentences-correctly-mode
  "Set `sentence-end-double-space' to fill sentences correctly.
It will be set to nil globally for better sentence movement and
editing, but dlet to t around filling functions, to correctly
fill sentences."
  :global t
  :keymap nil
  :lighter " .__"
  (if fill-sentences-correctly-mode
      (progn                            ; Enable
        (setq fill-sentences-correctly--sentence-end-double-space-orig
              sentence-end-double-space
              sentence-end-double-space nil)
        (dolist (fn fill-sentences-correctly-functions)
          (advice-add fn :around #'fill-sentences-correctly)))
    ;; Disable
    (setq sentence-end-double-space
          fill-sentences-correctly--sentence-end-double-space-orig)
    (dolist (fn fill-sentences-correctly-functions)
      (advice-remove fn #'fill-sentences-correctly))))

(provide 'fill-sentences-correctly)
;;; fill-sentences-correctly.el ends here
