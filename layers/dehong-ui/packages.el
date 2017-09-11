;;; packages.el --- dehong-ui layer packages file for Spacemacs.
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defconst dehong-ui-packages
  '(
    diminish
    popwin
    (whitespace :location built-in)
    spaceline
    )
  )

(defun dehong-ui/post-init-diminish ()
  (progn
    (with-eval-after-load 'whitespace
      (diminish 'whitespace-mode))
    (with-eval-after-load 'smartparens
      (diminish 'smartparens-mode))
    (with-eval-after-load 'which-key
      (diminish 'which-key-mode))
    (with-eval-after-load 'hungry-delete
      (diminish 'hungry-delete-mode))))


(defun dehong-ui/post-init-spaceline ()
  (use-package spaceline-config
    :config
    (progn
      (defvar spaceline-org-clock-format-function
        'org-clock-get-clock-string
        "The function called by the `org-clock' segment to determine what to show.")

      (spaceline-define-segment org-clock
                                "Show information about the current org clock task.  Configure
`spaceline-org-clock-format-function' to configure. Requires a currently running
org clock.

This segment overrides the modeline functionality of `org-mode-line-string'."
                                (when (and (fboundp 'org-clocking-p)
                                           (org-clocking-p))
                                  (substring-no-properties (funcall spaceline-org-clock-format-function)))
                                :global-override org-mode-line-string)

      (spaceline-compile
       'dehong
       ;; Left side of the mode line (all the important stuff)
       '(((persp-name
           workspace-number
           window-number
           )
          :separator "|"
          :face highlight-face)
         ((buffer-modified buffer-size input-method))
         anzu
         '(buffer-id remote-host buffer-encoding-abbrev)
         ((point-position line-column buffer-position selection-info)
          :separator " | ")
         major-mode
         process
         (flycheck-error flycheck-warning flycheck-info)
         ;; (python-pyvenv :fallback python-pyenv)
         ((minor-modes :separator spaceline-minor-modes-separator) :when active)
         (org-pomodoro :when active)
         (org-clock :when active)
         nyan-cat)
       ;; Right segment (the unimportant stuff)
       '((version-control :when active)
         battery))

      (setq-default mode-line-format '("%e" (:eval (spaceline-ml-dehong))))
      )))

(defun dehong-ui/post-init-popwin ()
  (progn
    (push "*dehong/run-current-file output*" popwin:special-display-config)
    (delete "*Async Shell Command*" popwin:special-display-config)))

(defun dehong-ui/post-init-whitespace ()
  (progn
    ;; ;; http://emacsredux.com/blog/2013/05/31/highlight-lines-that-exceed-a-certain-length-limit/
    (setq whitespace-line-column fill-column) ;; limit line length
    ;;https://www.reddit.com/r/emacs/comments/2keh6u/show_tabs_and_trailing_whitespaces_only/
    (setq whitespace-display-mappings
          ;; all numbers are Unicode codepoint in decimal. try (insert-char 182 ) to see it
          '(
            (space-mark 32 [183] [46])           ; 32 SPACE, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
            (newline-mark 10 [182 10])           ; 10 LINE FEED
            (tab-mark 9 [187 9] [9655 9] [92 9]) ; 9 TAB, 9655 WHITE RIGHT-POINTING TRIANGLE 「▷」
            ))
    (setq whitespace-style '(face tabs trailing tab-mark ))
    ;; (setq whitespace-style '(face lines-tail))
    ;; show tab;  use untabify to convert tab to whitespace
    (setq spacemacs-show-trailing-whitespace nil)

    (setq-default tab-width 4)
    ;; set-buffer-file-coding-system -> utf8 to convert dos to utf8
    ;; (setq inhibit-eol-conversion t)
    ;; (add-hook 'prog-mode-hook 'whitespace-mode)

    ;; (global-whitespace-mode +1)

    (with-eval-after-load 'whitespace
      (progn
        (set-face-attribute 'whitespace-tab nil
                            :background "#Adff2f"
                            :foreground "#00a8a8"
                            :weight 'bold)
        (set-face-attribute 'whitespace-trailing nil
                            :background "#e4eeff"
                            :foreground "#183bc8"
                            :weight 'normal)))

    (diminish 'whitespace-mode)))
