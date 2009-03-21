;; -*- mode: emacs-lisp -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Author: Kyle R. Burton
;;
;; This is my personal emacs configuration.  Check it out into
;; ~/personal/projects/krbemacs, then symlink it to ~/.emacs.
;;

(add-to-list 'load-path (expand-file-name "~/personal/projects/krbemacs/lib"))
(add-to-list 'load-path (expand-file-name "~/personal/projects/krbemacs/git"))
(add-to-list 'load-path (expand-file-name "~/personal/projects/krbemacs/slime/slime"))
(add-to-list 'load-path (expand-file-name "~/personal/projects/krbemacs/clojure-mode"))
(add-to-list 'load-path (expand-file-name "~/personal/projects/krbemacs/swank-clojure"))
(add-to-list 'load-path (expand-file-name "~/personal/projects/krbemacs/jochu-clojure-mode-494dfab8cd0dfc5ed24a1fc33da8b892feeef20d"))


(require 'cl)
(require 'yaml-mode)

(defvar krb-local-host-name nil)
(setq krb-local-host-name (first (split-string (shell-command-to-string "hostname") "\n")))

(defun krb-file-ext-case-permute (pattern)
  (loop for mutator in '(downcase upcase capitalize)
        collect (funcall mutator pattern)))

(defun krb-push-file-ext-and-mode-binding (mode-name &rest patterns)
  (loop for pattern in patterns
        do
        (loop for modified-case in (krb-file-ext-case-permute pattern)
              do
              (setq auto-mode-alist
              (cons (cons pattern mode-name)
                    auto-mode-alist)))))


(require  'color-theme)
(load "themes/color-theme-library.el")
(color-theme-arjen)

(load "dabbrev")
(load "completion")
(initialize-completions)

; spaces instead of tabs
(setq-default
 indent-tabs-mode nil
 c-basic-offset 2
 c-default-style "user")

(custom-set-variables
 ;; custom-set-variables was added by Custom -- don't edit or cut/paste it!
 ;; Your init file should contain only one such instance.
 '(compile-command "TERM=dumb make")
 '(pc-select-meta-moves-sexps t)
 '(pc-select-selection-keys-only t)
 '(pc-selection-mode t t)
 '(semanticdb-default-save-directory (expand-file-name "~/.emacs-semantic") t)
 '(semanticdb-default-system-save-directory (expand-file-name "~/.emacs-semantic") t)
 '(user-full-name "Kyle R. Burton")
 '(user-mail-address "kburton@healthmarketscience.com")
 
 ;; confluence customization
 '(confluence-url "http://intranet.hmsonline.com/confluence/rpc/xmlrpc")
 '(confluence-default-space-alist (list (cons confluence-url "SWDEV")))
 '(confluence-prompt-page-function 'cf-prompt-page-by-path))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; localized customization per host

(defmacro when-file-exists (decl &rest body)
  "(when-file-exists (fname \"/etc/passwd\")
     (message \"%s exists\" fname)"
  (destructuring-bind (var file-path) decl
    `(let ((,var (expand-file-name ,file-path)))
       (when (file-exists-p ,var)
         ,@body))))

(when (string= "kburton-lin" krb-local-host-name)
  (when-file-exists
   (fname "~/projects/sandbox/trunk/standardize-web/jruby/jruby-1.1.5/bin/jruby")
   (setq krb-ruby-path-to-ruby fname))
  (when-file-exists 
   (fname "~/projects/svn.datapump/trunk/hmsdev2/etc/emacs-utils.el")
   (load-file fname)))

(when-file-exists
 (fname (format "~/personal/projects/krbemacs/config/%s.el" krb-local-host-name))
 (message "loading local customization file: %s" fname)
 (load-file fname))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; version control customization

;;; git
;; see: http://xtalk.msk.su/~ott/en/writings/emacs-vcs/EmacsGit.html
(require 'git)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Perl Development customization
(setq cperl-hairy t)

(krb-push-file-ext-and-mode-binding 'cperl-mode "\\.pl$" "\\.pm$" "\\.al$")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Confluence Mode Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(load (expand-file-name "~/personal/projects/krbemacs/confluence-el/xml-rpc.el"))
(load (expand-file-name "~/personal/projects/krbemacs/confluence-el/confluence.el"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; confluence editing support (with longlines mode)

(autoload 'confluence-get-page "confluence" nil t)

(eval-after-load "confluence"
  '(progn
     (require 'longlines)
     (progn
       (add-hook 'confluence-mode-hook 'longlines-mode)
       (add-hook 'confluence-before-save-hook 'longlines-before-revert-hook)
       (add-hook 'confluence-before-revert-hook 'longlines-before-revert-hook)
       (add-hook 'confluence-mode-hook '(lambda () (local-set-key "\C-j" 'confluence-newline-and-indent))))))

;; LongLines mode: http://www.emacswiki.org/emacs-en/LongLines
(autoload 'longlines-mode "longlines" "LongLines Mode." t)

(eval-after-load "longlines"
  '(progn
     (defvar longlines-mode-was-active nil)
     (make-variable-buffer-local 'longlines-mode-was-active)

     (defun longlines-suspend ()
       (if longlines-mode
           (progn
             (setq longlines-mode-was-active t)
             (longlines-mode 0))))

     (defun longlines-restore ()
       (if longlines-mode-was-active
           (progn
             (setq longlines-mode-was-active nil)
             (longlines-mode 1))))

     ;; longlines doesn't play well with ediff, so suspend it during diffs
     (defadvice ediff-make-temp-file (before make-temp-file-suspend-ll
                                             activate compile preactivate)
       "Suspend longlines when running ediff."
       (with-current-buffer (ad-get-arg 0)
         (longlines-suspend)))

     
     (add-hook 'ediff-cleanup-hook 
               '(lambda ()
                  (dolist (tmp-buf (list ediff-buffer-A
                                         ediff-buffer-B
                                         ediff-buffer-C))
                    (if (buffer-live-p tmp-buf)
                        (with-current-buffer tmp-buf
                          (longlines-restore))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; keybindings (change to suit)

;; open confluence page
(global-set-key "\C-xwf" 'confluence-get-page)

;; setup confluence mode
(add-hook 'confluence-mode-hook
          '(lambda ()
             (local-set-key "\C-xw" confluence-prefix-map)
             (setq abbrev-mode t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; End of Confluence Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Ruby
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; need to make this environment indepdendent...
(add-to-list 'load-path "/usr/share/emacs/site-lisp/ruby1.8-elisp")
(load "ruby-mode.el")
(load "inf-ruby.el")

(krb-push-file-ext-and-mode-binding 'ruby-mode "\\.rb$" "\\.erb$")

(require 'krb-ruby)
(add-hook 'ruby-mode-hook
          'krb-ruby-apply-keybindings)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lisp and Clojure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(load "paredit.el")

(defun krb-set-clojure-bindings ()
  (message "setting my own bindings")
  (local-set-key "\C-c)" 'paredit-forward-slurp-sexp)
  (local-set-key "\C-c(" 'paredit-backward-slurp-sexp)
  (local-set-key "\C-c}" 'paredit-forward-barf-sexp)
  (local-set-key "\C-c{" 'paredit-backward-barf-sexp)
  (setq abbrev-mode t))

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
             (paredit-mode +1)
             (setq abbrev-mode t)))

(add-hook 'clojure-mode-hook
          'krb-set-clojure-bindings)

(krb-push-file-ext-and-mode-binding 'clojure-mode "\\.clj$")

(defvar sbcl-binary nil)

;; find the sbcl binary
(let ((locations
       (mapcar #'expand-file-name
               (list "~/local/bin/sbcl"
                     "~/local/sbcl/bin/sbcl")))
      (found nil))
  (loop for location in locations
        while (not found)
        do
        (message "finding sbcl: %s => %s" location (file-exists-p location))
        (when (file-exists-p location)
          (setq inferior-lisp-program location
                sbcl-binary location
                found t)
          (message "found sbcl: %s %s" inferior-lisp-program found)))
  (unless found
    (error "Can't find the sbcl binary for slime, tried: %s,
    please locate it or disable slime in this environment."
           locations)))

;; ;; find SBCL_HOME...
;; (let ((locations
;;        (mapcar #'expand-file-name
;;                (list "~/local/lib/sbcl"
;;                      "~/local/sbcl/lib/sbcl")))
;;       (found nil))
;;   (loop for location in locations
;;         while (not found)
;;         do
;;         (let ((file (format "%s/sbcl.core" location)))
;;           (message "finding sbcl_home: %s => %s" file (file-exists-p file))
;;           (when (file-exists-p file)
;;             (setq found t)
;;             (setenv "SBCL_HOME" location)
;;             (message "found sbcl: %s %s" inferior-lisp-program found))))
;;   (unless found
;;     (error "Can't determine SBCL_HOME, tried: %s, please locate
;;     it or disable slime in this environment."  locations)))


(require 'slime)
(slime-setup)

(setq swank-clojure-binary "clojure")
; (require 'clojure-auto)
; (require 'clojure-paredit) 
(require 'swank-clojure-autoload)

(add-hook
 'paredit-mode-hook
 '(lambda ()
    (local-set-key "\M-Oa" 'paredit-splice-sexp-killing-backward)
    (local-set-key "\M-Ob" 'paredit-splice-sexp-killing-forward)
    (local-set-key "\M-Oc" 'paredit-forward-slurp-sexp)
    (local-set-key "\M-Od" 'paredit-forward-barf-sexp)
    (setq abbrev-mode t)))

(setq slime-lisp-implementations
      (append
       '((sbcl ("sbcl")))
       ;; (list (list 'sbcl (list sbcl-binary)))
       slime-lisp-implementations))

(add-hook 'lisp-mode-hook
          (lambda ()
             (paredit-mode +1)
             (setq abbrev-mode t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end Lisp and Clojure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chicken scheme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (require 'hen)
(setq scheme-program-name "csi")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end Chicken scheme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; XML, YAML Customizations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(krb-push-file-ext-and-mode-binding 'nxml-mode "\\.xml$")
(krb-push-file-ext-and-mode-binding 'yaml-mode "\\.yml$" "\\.yaml$")
(setq nxml-slash-auto-complete-flag t)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end XML
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Java 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(krb-push-file-ext-and-mode-binding 'archive-mode "\\.war$" "\\.ear$" "\\.jar$")
;; TODO: need to set up jdee
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end Java 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Other
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-set-key "\M-g" 'goto-line)

(load "toggle-case")
(global-set-key [(control \^)] 'joc-toggle-case)
(global-set-key [(control meta \^)] 'joc-toggle-case-by-region)

;; follow compilation output when M-x compile
(setq compilation-scroll-output t)


; (require 'elunit)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Abbreviations and yasnippet...
(setq abbrev-file-name (expand-file-name "~/personal/projects/krbemacs/abbrev-defs.el"))
(read-abbrev-file abbrev-file-name t)

(add-to-list 'load-path "~/personal/projects/krbemacs/yasnippet")
(require 'yasnippet)
;;; Abbreviations and yasnippet...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end Other
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
