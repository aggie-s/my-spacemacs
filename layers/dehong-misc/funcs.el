;;; funcs.el --- dehong Layer packages File for Spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;; @see https://bitbucket.org/lyro/evil/issue/511/let-certain-minor-modes-key-bindings
(defmacro adjust-major-mode-keymap-with-evil (m &optional r)
  `(eval-after-load (quote ,(if r r m))
     '(progn
        (evil-make-overriding-map ,(intern (concat m "-mode-map")) 'normal)
        ;; force update evil keymaps after git-timemachine-mode loaded
        (add-hook (quote ,(intern (concat m "-mode-hook"))) #'evil-normalize-keymaps))))

  ;; my fix for tab indent
(defun dehong/indent-region(numSpaces)
  (progn
                                      ; default to start and end of current line
    (setq regionStart (line-beginning-position))
    (setq regionEnd (line-end-position))

                                      ; if there's a selection, use that instead of the current line
    (when (use-region-p)
      (setq regionStart (region-beginning))
      (setq regionEnd (region-end))
      )

    (save-excursion                          ; restore the position afterwards
      (goto-char regionStart)                ; go to the start of region
      (setq start (line-beginning-position)) ; save the start of the line
      (goto-char regionEnd)                  ; go to the end of region
      (setq end (line-end-position))         ; save the end of the line

      (indent-rigidly start end numSpaces) ; indent between start and end
      (setq deactivate-mark nil)           ; restore the selected region
      )
    )
  )

(defun dehong/tab-region (N)
  (interactive "p")
  (if (use-region-p)
      (dehong/indent-region 4)               ; region was selected, call indent-region
    (insert "    ")                   ; else insert four spaces as expected
    ))

(defun dehong/untab-region (N)
  (interactive "p")
  (dehong/indent-region -4))

;; https://github.com/syohex/emacs-browser-refresh/blob/master/browser-refresh.el
(defun dehong/browser-refresh--chrome-applescript ()
  (interactive)
  (do-applescript
   (format
    "
  tell application \"Google Chrome\"
    set winref to a reference to (first window whose title does not start with \"Developer Tools - \")
    set winref's index to 1
    reload active tab of winref
  end tell
" )))


(define-minor-mode
  shadowsocks-proxy-mode
  :global t
  :init-value nil
  :lighter " SS"
  (if shadowsocks-proxy-mode
      (setq url-gateway-method 'socks)
    (setq url-gateway-method 'native)))


(define-global-minor-mode
  global-shadowsocks-proxy-mode shadowsocks-proxy-mode shadowsocks-proxy-mode
  :group 'shadowsocks-proxy)

;; http://blog.lojic.com/2009/08/06/send-growl-notifications-from-carbon-emacs-on-osx/
(defun dehong/growl-notification (title message &optional sticky)
  "Send a Growl notification"
  (do-applescript
   (format "tell application \"GrowlHelperApp\" \n
              notify with name \"Emacs Notification\" title \"%s\" description \"%s\" application name \"Emacs.app\" sticky \"%s\"
              end tell
              "
           title
           message
           (if sticky "yes" "no"))))

(defun dehong/insert-chrome-current-tab-url()
  "Get the URL of the active tab of the first window"
  (interactive)
  (insert (dehong/retrieve-chrome-current-tab-url)))

(defun dehong/retrieve-chrome-current-tab-url()
  "Get the URL of the active tab of the first window"
  (interactive)
  (let ((result (do-applescript
                 (concat
                  "set frontmostApplication to path to frontmost application\n"
                  "tell application \"Google Chrome\"\n"
                  "	set theUrl to get URL of active tab of first window\n"
                  "	set theResult to (get theUrl) \n"
                  "end tell\n"
                  "activate application (frontmostApplication as text)\n"
                  "set links to {}\n"
                  "copy theResult to the end of links\n"
                  "return links as string\n"))))
    (format "%s" (s-chop-suffix "\"" (s-chop-prefix "\"" result)))))

(defun dehong/ash-term-hooks ()
  ;; dabbrev-expand in term
  (define-key term-raw-escape-map "/"
    (lambda ()
      (interactive)
      (let ((beg (point)))
        (dabbrev-expand nil)
        (kill-region beg (point)))
      (term-send-raw-string (substring-no-properties (current-kill 0)))))
  ;; yank in term (bound to C-c C-y)
  (define-key term-raw-escape-map "\C-y"
    (lambda ()
      (interactive)
      (term-send-raw-string (current-kill 0)))))

(defun dehong/terminal ()
  "Switch to terminal. Launch if nonexistent."
  (interactive)
  (if (get-buffer "*ansi-term*")
      (switch-to-buffer-other-window "*ansi-term*")
    (progn
      (split-window-right-and-focus)
      (ansi-term "/bin/zsh")))
  (get-buffer-process "*ansi-term*"))

(defalias 'tt 'dehong/terminal)

(defun dehong/evil-quick-replace (beg end )
  (interactive "r")
  (when (evil-visual-state-p)
    (evil-exit-visual-state)
    (let ((selection (regexp-quote (buffer-substring-no-properties beg end))))
      (setq command-string (format "%%s /%s//g" selection))
      (minibuffer-with-setup-hook
          (lambda () (backward-char 2))
        (evil-ex command-string)))))

(defun dehong/git-project-root ()
  "Return the project root for current buffer."
  (let ((directory default-directory))
    (locate-dominating-file directory ".git")))

(defadvice persp-switch (after my-quit-helm-perspectives activate)
  (setq hydra-deactivate t))

(defun dehong/my-mc-mark-next-like-this ()
  (interactive)
  (if (region-active-p)
      (mc/mark-next-like-this 1)
    (er/expand-region 1)))


(defun wrap-sexp-with-new-round-parens ()
  (interactive)
  (insert "()")
  (backward-char)
  (sp-forward-slurp-sexp))

(defun evil-paste-after-from-0 ()
  (interactive)
  (let ((evil-this-register ?0))
    (call-interactively 'evil-paste-after)))

(defun my-erc-hook (match-type nick message)
  "Shows a growl notification, when user's nick was mentioned. If the buffer is currently not visible, makes it sticky."
  (unless (posix-string-match "^\\** *Users on #" message)
    (dehong/growl-notification
     (concat "ERC: : " (buffer-name (current-buffer)))
     message
     t
     )))

(defun my-swiper-search (p)
  (interactive "P")
  (let ((current-prefix-arg nil))
    (call-interactively
     (if p #'spacemacs/swiper-region-or-symbol
       #'counsel-grep-or-swiper))))

(defun ivy-ff-checksum ()
  (interactive)
  "Calculate the checksum of FILE. The checksum is copied to kill-ring."
  (let ((file (expand-file-name (ivy-state-current ivy-last) ivy--directory))
        (algo (intern (ivy-read
                       "Algorithm: "
                       '(md5 sha1 sha224 sha256 sha384 sha512)))))
    (kill-new (with-temp-buffer
                (insert-file-contents-literally file)
                (secure-hash algo (current-buffer))))
    (message "Checksum copied to kill-ring.")))

(defun ivy-ff-checksum-action (x)
  (ivy-ff-checksum))

(defun my-find-file-in-git-repo (repo)
  (if (file-directory-p repo)
      (let* ((default-directory repo)
             (files (split-string (shell-command-to-string (format "cd %s && git ls-files" repo)) "\n" t)))
        (ivy-read "files:" files
                  :action 'find-file
                  :caller 'my-find-file-in-git-repo))
    (message "%s is not a valid directory." repo)))

(defun my-open-file-in-external-app (file)
  "Open file in external application."
  (interactive)
  (let ((default-directory (dehong/git-project-root))
        (file-path file))
    (if file-path
        (cond
         ((spacemacs/system-is-mswindows) (w32-shell-execute "open" (replace-regexp-in-string "/" "\\\\" file-path)))
         ((spacemacs/system-is-mac) (shell-command (format "open \"%s\"" file-path)))
         ((spacemacs/system-is-linux) (let ((process-connection-type nil))
                                        (start-process "" nil "xdg-open" file-path))))
      (message "No file associated to this buffer."))))

(defun ivy-insert-action (x)
  (with-ivy-window
    (insert x)))

(defun ivy-kill-new-action (x)
  (with-ivy-window
    (kill-new x)))

(defun dehong/markdown-to-html ()
  (interactive)
  (start-process "grip" "*gfm-to-html*" "grip" (buffer-file-name) "5000")
  (browse-url (format "http://localhost:5000/%s.%s" (file-name-base) (file-name-extension (buffer-file-name)))))
