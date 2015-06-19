;;; port.el --- a Emacs interface for MacPorts port(1)  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Chunyang Xu

;; Author: Chunyang Xu <chunyang@macports.org>
;; Version: 0.01
;; Package-Requires: ((emacs "24.1"))
;; Keywords: MacPorts

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Latest version can be found at:
;; https://svn.macports.org/repository/macports/users/chunyang/port.el/

;; NOTE: Use the command line program `port' is too slow.

;;; Code:

(require 'tabulated-list)

(define-derived-mode port-menu-mode tabulated-list-mode "MacPorts Port Menu"
  "Major mode browsing a list of ports.
Letters do not insert themselves; instead, they are commands. "
  (setq tabulated-list-format `[("Package" 18 nil)
                                ("Version" 28 nil)
                                ("Status"  11 nil)])
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key (cons "Status" nil))
  (tabulated-list-init-header))

;;;###autoload
(defun port-list-ports ()
  (interactive)
  (let ((buf (get-buffer-create "*Ports*")))
    (with-current-buffer buf
      (port-menu-mode)
      (setq tabulated-list-entries
            (mapcar
             (lambda (item)
               (let ((port (split-string (string-trim item))))
                 (list nil (vector (nth 0 port)
                                   (nth 1 port)
                                   (let ((status (nth 2 port)))
                                     (if status (substring status 1 -1)
                                       "deactivated"))))))
             (butlast
              (split-string
               (shell-command-to-string "port -q installed requested")
               "\n"))))
      (tabulated-list-print t)
      (switch-to-buffer buf))))

;;;###autoload
(defun helm-port ()
  (interactive)
  (and
   (require 'helm nil t)
   (require 'subr-x nil t)
   (helm :sources
         (helm-build-sync-source "MacPorts"
           :candidates (lambda ()
                         (mapcar
                          #'string-trim
                          (butlast
                           (split-string
                            (shell-command-to-string "port -q installed requested")
                            "\n"))))
           :action '(("Go to home page" .
                      (lambda (candidate)
                        (when-let ((string candidate) (regexp " (active)")
                                   (index (string-match regexp string)))
                          (setq candidate (substring string 0 index)))
                        (shell-command (concat "port gohome " candidate)))))))))

(provide 'port)
;;; port.el ends here
