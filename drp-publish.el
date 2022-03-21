;; [[file:pip-conformance-tests.org::*1: But what is this org-mode document, why is this not a Markdown or HTML file?][1: But what is this org-mode document, why is this not a Markdown or HTML file?:2]]
(defun publish-drp-test-suite ()
  (interactive)
  (let* ((base-dir (file-name-directory (buffer-file-name))) ; this file's directory
         (pub-dir (expand-file-name "docs" base-dir))        ; the subdirectory "docs" of this directory for ghpages..
         (org-export-babel-evaluate nil))                    ; no sense evaluating code on export
    ;; this seems more legible than using a magic ` quote instead of building the project definition procedurally...
    (org-publish
     (append '("drp-cert"
               :base-extension "org\\|md"
               :recursive t
               :headline-levels 4
               :publishing-function org-html-publish-to-html)
             (list :publishing-directory pub-dir)
             (list :base-directory base-dir)))))
(provide 'drp-publish)
;; 1: But what is this org-mode document, why is this not a Markdown or HTML file?:2 ends here
